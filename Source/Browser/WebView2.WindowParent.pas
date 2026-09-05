unit WebView2.WindowParent;

{$I TBGWebCharts.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ActiveX,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  WebView2.Api;

const
  { Valor usado ate hoje como constante fixa em Browser.VCL.WebView2.pas -
    agora e so o default de OperationTimeoutMs, configuravel por instancia. }
  cDefaultWebView2OperationTimeoutMs = 10000;

  { URL virtual (nunca sai pra rede de verdade - interceptada via
    WebResourceRequested antes disso) usada pra servir o HTML gerado direto
    da memoria, sem NavigateToString (limite real de ~2MB) nem
    Navigate(file://...) (bug ERR_FILE_NOT_FOUND nunca resolvido) - mesma
    tecnica que Browser.VCL.Chromium.pas ja usa pro CEF (URL fake +
    resource handler em memoria). ".local" (RFC 2606) garante que nunca
    seria um dominio real mesmo se a interceptacao falhasse por algum
    motivo. O "?v=N" no final (ver NavigateToHtml) forca cada chamada a
    ser uma URL distinta, pra nao arriscar o WebView2 pular a navegacao
    por achar que "a URL nao mudou". }
  cVirtualHtmlPath = 'https://tbgwebcharts.local/generated.html';

type
  { Controle a ser solto no formulario, equivalente ao TCEFWindowParent do
    CEF - mas proprio deste projeto, sem depender de pacote externo. Hospeda
    a janela nativa criada pelo ICoreWebView2Controller. }
  TWebView2WindowParent = class(TCustomControl)
  private
    FEnvironment: ICoreWebView2Environment;
    FController: ICoreWebView2Controller;
    FCoreWebView2: ICoreWebView2;
    FInitializing: Boolean;
    FReady: Boolean;
    FOperationTimeoutMs: Cardinal;
    { Handler PERSISTENTE (ver comentario em WebView2.Api.pas) - a referencia
      precisa ficar viva aqui enquanto o evento estiver registrado. }
    FNavigationStartingHandler: ICoreWebView2NavigationStartingEventHandler;
    FNavigationStartingToken: EventRegistrationToken;
    FOnNavigationStarting: TWebView2NavigationStartingProc;
    { Idem, pro WebResourceRequested - e o que serve FPendingHtml quando o
      WebView2 pede cVirtualHtmlPath. }
    FWebResourceRequestedHandler: ICoreWebView2WebResourceRequestedEventHandler;
    FWebResourceRequestedToken: EventRegistrationToken;
    FPendingHtml: string;
    FNavigationCounter: Integer;
    procedure DoEnvironmentCreated(ErrorCode: HResult; const Env: ICoreWebView2Environment);
    procedure DoControllerCreated(ErrorCode: HResult; const Ctrl: ICoreWebView2Controller);
    procedure HandleWebResourceRequested(const Uri: string;
      const Args: ICoreWebView2WebResourceRequestedEventArgs);
    procedure UpdateBounds;
  protected
    procedure Resize; override;
    { Controles escondidos (ex.: pagina inativa de um TPageControl, painel
      criado com Visible=False) recebem seu layout final via AlignControls
      sem nunca disparar WM_SIZE - TWinControl.CMShowingChanged troca a
      visibilidade da janela com SWP_NOSIZE. Sem este hook, se o Bounds do
      controller for calculado enquanto o controle ainda esta oculto, ele
      fica travado nesse tamanho (normalmente menor que o painel real) ate
      que ocorra um resize de verdade. }
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    { Dispara a criacao assincrona do Environment/Controller/CoreWebView2.
      Idempotente - chamadas repetidas depois da primeira sao ignoradas. }
    procedure Initialize;
    { Serve HTML para o WebView2 sem NavigateToString (limite real de
      ~2MB) e sem Navigate(file://...) (bug ERR_FILE_NOT_FOUND nunca
      resolvido): guarda o HTML e navega pra uma URL virtual fixa
      (cVirtualHtmlPath) interceptada via WebResourceRequested, que serve
      o conteudo direto da memoria - mesma tecnica que
      Browser.VCL.Chromium.pas ja usa pro CEF (URL fake + resource
      handler). Sem limite de tamanho de pagina. }
    procedure NavigateToHtml(const HTML: string);
    property CoreWebView2: ICoreWebView2 read FCoreWebView2;
    property Controller: ICoreWebView2Controller read FController;
    { True quando CoreWebView2/Controller ja estao prontos pra uso (Navigate,
      ExecuteScript etc). }
    property Ready: Boolean read FReady;
    { Disparado a cada navegacao (inclusive as geradas por link clicado
      dentro do HTML renderizado). Quem assina pode setar Cancel := True
      pra impedir a navegacao de fato acontecer - e o gancho que
      Browser.VCL.WebView2 usa pra interceptar "ActionCallBackJS:...". }
    property OnNavigationStarting: TWebView2NavigationStartingProc
      read FOnNavigationStarting write FOnNavigationStarting;
  published
    { Quanto tempo (em ms) WaitReady/ExecuteScriptResult esperam antes de
      desistir (WebView2 nao ficar pronto, ou script nao retornar). Script
      muito pesado (grafico grande, tabela enorme) pode precisar de mais
      que o default. }
    property OperationTimeoutMs: Cardinal read FOperationTimeoutMs
      write FOperationTimeoutMs default cDefaultWebView2OperationTimeoutMs;
    { TCustomControl nao republica nada disso como published - sem essas
      linhas as propriedades existem (herdadas de TControl/TWinControl) mas
      nao aparecem no Object Inspector nem podem ser gravadas no .dfm (o
      "Align" e um caso concreto: sem isto o Delphi acusa a propriedade como
      inexistente ao tentar usa-la no formulario). }
    property Align;
    property Anchors;
    property Color;
    property Constraints;
    property Enabled;
    property PopupMenu;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick;
    property OnEnter;
    property OnExit;
    property OnResize;
  end;

implementation

{ TWebView2WindowParent }

constructor TWebView2WindowParent.Create(AOwner: TComponent);
begin
  inherited;
  FOperationTimeoutMs := cDefaultWebView2OperationTimeoutMs;
end;

destructor TWebView2WindowParent.Destroy;
begin
  if Assigned(FCoreWebView2) and Assigned(FNavigationStartingHandler) then
    FCoreWebView2.remove_NavigationStarting(FNavigationStartingToken);
  FNavigationStartingHandler := nil;
  if Assigned(FCoreWebView2) and Assigned(FWebResourceRequestedHandler) then
    FCoreWebView2.remove_WebResourceRequested(FWebResourceRequestedToken);
  FWebResourceRequestedHandler := nil;
  if Assigned(FController) then
  begin
    FController.Close;
    FController := nil;
  end;
  FCoreWebView2 := nil;
  FEnvironment := nil;
  inherited;
end;

procedure TWebView2WindowParent.Initialize;
var
  Callback: TProc<HResult, ICoreWebView2Environment>;
begin
  if FInitializing or FReady then
    Exit;
  FInitializing := True;
  Callback := procedure(ErrorCode: HResult; Env: ICoreWebView2Environment)
    begin
      DoEnvironmentCreated(ErrorCode, Env);
    end;
  WebView2_CreateEnvironment(TCoreWebView2EnvironmentCompletedHandler.Create(Callback));
end;

procedure TWebView2WindowParent.DoEnvironmentCreated(ErrorCode: HResult;
  const Env: ICoreWebView2Environment);
var
  ControllerCallback: TProc<HResult, ICoreWebView2Controller>;
begin
  if (ErrorCode <> S_OK) or not Assigned(Env) then
  begin
    FInitializing := False;
    raise Exception.CreateFmt('Falha ao criar o ICoreWebView2Environment (HResult=%.8x).', [Cardinal(ErrorCode)]);
  end;
  FEnvironment := Env;
  ControllerCallback := procedure(ErrorCode: HResult; Ctrl: ICoreWebView2Controller)
    begin
      DoControllerCreated(ErrorCode, Ctrl);
    end;
  FEnvironment.CreateCoreWebView2Controller(Handle, TCoreWebView2ControllerCompletedHandler.Create(ControllerCallback));
end;

procedure TWebView2WindowParent.DoControllerCreated(ErrorCode: HResult;
  const Ctrl: ICoreWebView2Controller);
begin
  FInitializing := False;
  if (ErrorCode <> S_OK) or not Assigned(Ctrl) then
    raise Exception.CreateFmt('Falha ao criar o ICoreWebView2Controller (HResult=%.8x).', [Cardinal(ErrorCode)]);
  FController := Ctrl;
  FController.Get_CoreWebView2(FCoreWebView2);

  FNavigationStartingHandler := TCoreWebView2NavigationStartingHandler.Create(
    procedure(const Uri: string; var Cancel: Boolean)
    begin
      if Assigned(FOnNavigationStarting) then
        FOnNavigationStarting(Uri, Cancel);
    end);
  FCoreWebView2.add_NavigationStarting(FNavigationStartingHandler, FNavigationStartingToken);

  FWebResourceRequestedHandler := TCoreWebView2WebResourceRequestedHandler.Create(HandleWebResourceRequested);
  FCoreWebView2.add_WebResourceRequested(FWebResourceRequestedHandler, FWebResourceRequestedToken);
  FCoreWebView2.AddWebResourceRequestedFilter(PWideChar(cVirtualHtmlPath + '*'), 0 { COREWEBVIEW2_WEB_RESOURCE_CONTEXT_ALL });

  UpdateBounds;
  FController.Set_IsVisible(1);
  FReady := True;
end;

procedure TWebView2WindowParent.HandleWebResourceRequested(const Uri: string;
  const Args: ICoreWebView2WebResourceRequestedEventArgs);
var
  Bytes: TBytes;
  Stream: TMemoryStream;
  StreamAdapter: IStream;
  Response: ICoreWebView2WebResourceResponse;
begin
  if not Assigned(FEnvironment) or not Uri.StartsWith(cVirtualHtmlPath) then
    Exit;

  Bytes := TEncoding.UTF8.GetBytes(FPendingHtml);
  Stream := TMemoryStream.Create;
  if Length(Bytes) > 0 then
    Stream.WriteBuffer(Bytes[0], Length(Bytes));
  Stream.Position := 0;
  StreamAdapter := TStreamAdapter.Create(Stream, soOwned);

  { cVirtualHtmlPath e sempre a MESMA URL base, só o "?v=N" muda - sem
    dizer explicitamente "nao cacheia" o navegador pode (e, na pratica,
    caiu exatamente nisso durante o diagnostico) devolver uma resposta
    antiga do cache do proprio WebView2Loader (perfil em disco, persiste
    entre execucoes do app) em vez de chamar este handler nesta
    navegacao - o que faz qualquer mudanca de codigo parecer nao ter
    efeito nenhum, mesmo recompilando. Cada HTML gerado e dinamico e
    nunca deve ser cacheado. }
  if FEnvironment.CreateWebResourceResponse(StreamAdapter, 200, 'OK',
    'Content-Type: text/html; charset=utf-8'#13#10 +
    'Cache-Control: no-store, no-cache, must-revalidate'#13#10,
    Response) = S_OK then
    Args.Set_Response(Response);
end;

procedure TWebView2WindowParent.NavigateToHtml(const HTML: string);
begin
  FPendingHtml := HTML;
  Inc(FNavigationCounter);
  FCoreWebView2.Navigate(PWideChar(cVirtualHtmlPath + '?v=' + IntToStr(FNavigationCounter)));
end;

procedure TWebView2WindowParent.UpdateBounds;
begin
  if Assigned(FController) then
    FController.Set_Bounds(ClientRect);
end;

procedure TWebView2WindowParent.Resize;
begin
  inherited;
  UpdateBounds;
end;

procedure TWebView2WindowParent.CMShowingChanged(var Message: TMessage);
begin
  inherited;
  UpdateBounds;
end;

end.
