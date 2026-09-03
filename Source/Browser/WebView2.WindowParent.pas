unit WebView2.WindowParent;

{$I TBGWebCharts.inc}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  WebView2.Api;

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
    procedure DoEnvironmentCreated(ErrorCode: HResult; const Env: ICoreWebView2Environment);
    procedure DoControllerCreated(ErrorCode: HResult; const Ctrl: ICoreWebView2Controller);
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
    destructor Destroy; override;
    { Dispara a criacao assincrona do Environment/Controller/CoreWebView2.
      Idempotente - chamadas repetidas depois da primeira sao ignoradas. }
    procedure Initialize;
    property CoreWebView2: ICoreWebView2 read FCoreWebView2;
    property Controller: ICoreWebView2Controller read FController;
    { True quando CoreWebView2/Controller ja estao prontos pra uso (Navigate,
      ExecuteScript etc). }
    property Ready: Boolean read FReady;
  end;

implementation

{ TWebView2WindowParent }

destructor TWebView2WindowParent.Destroy;
begin
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
  UpdateBounds;
  FController.Set_IsVisible(1);
  FReady := True;
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
