unit Browser.VCL.WebView2;

{$I TBGWebCharts.inc}

interface

uses
  Interfaces,
  Winapi.Windows,
  WebView2.Api,
  WebView2.WindowParent;

type
  TModelBrowserVCLWebView2 = class(TInterfacedObject, iModelBrowser)
  private
    FWindowParent: TWebView2WindowParent;
    FWaitingResult: Boolean;
    procedure WaitReady;
    { Intercepta a "navegacao" pro pseudo-protocolo ActionCallBackJS:Metodo(...)
      gerado pelas acoes de linha da Table (CallbackLink/ActionEdit/ActionDelete)
      - mesmo parsing usado em Browser.VCL.WebBrowser.BeforeNavigate e
      Browser.Chromium.Events.Chromium_BeforeBrowse. }
    procedure HandleNavigationStarting(const Uri: string; var Cancel: Boolean);
  public
    constructor Create(WindowParent: TWebView2WindowParent);
    destructor Destroy; override;
    class function New(WindowParent: TWebView2WindowParent): iModelBrowser;
    procedure ExecuteScript(Value: iModelJSCommand);
    function ExecuteScriptResult(Value: iModelJSCommand): string;
    procedure ExecuteScriptCallback(Value: iModelJSCommand);
    function Generated(FHTML: string): iModelBrowser;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  System.Classes,
  System.Diagnostics,
  Vcl.Forms,
  CallBackJS;

const
  { Limite documentado do NavigateToString e ~2.097.152 chars (2MB).
    NavigateToString e o caminho PRINCIPAL agora (comprovadamente
    confiavel - e o que sempre funcionou aqui) pra qualquer HTML que
    caiba nele; so paginas maiores usam NavigateToHtml (URL virtual +
    WebResourceRequested, ver WebView2.WindowParent.pas). Motivo de nao
    usar NavigateToHtml sempre (o que eliminaria esse teto de vez):
    2026-09-05, descoberto com o sample real, que paginas com MUITOS
    <script src=...> externos (modo CDN(true)) servidas via
    WebResourceRequested tem os scripts silenciosamente ignorados pelo
    WebView2 (confirmado nao ser cache, CSP nem header de Content-Type -
    3 hipoteses testadas e descartadas uma a uma). Paginas CDN(true) sao
    sempre pequenas (poucos KB, so tags script/link) e nunca esbarram
    nesse teto mesmo, entao NavigateToString sozinho ja resolve esse
    caso; NavigateToHtml fica so pra quando o HTML e grande de verdade
    (tipicamente CDN(false), sem scripts externos - onde ja confirmamos
    funcionando: Table Demo e Phosphor Demo, ~1.2MB). }
  cNavigateToStringMaxChars = 1900000;

function BuildResultExpression(const Value: iModelJSCommand): string;
begin
  Result := '(function(){' + Value.ResultCommand + '; return document.getElementById("' +
    Value.TagID + '").' + Value.TagAttribute + ';})()';
end;

function DecodeJSResult(const Json: string): string;
var
  JV: TJSONValue;
begin
  Result := '';
  if Json.IsEmpty then
    Exit;
  JV := TJSONValue.ParseJSONValue(Json);
  try
    if Assigned(JV) then
      Result := JV.Value
    else
      Result := Json;
  finally
    JV.Free;
  end;
end;

constructor TModelBrowserVCLWebView2.Create(WindowParent: TWebView2WindowParent);
begin
  inherited Create;
  FWindowParent := WindowParent;
  FWindowParent.OnNavigationStarting := HandleNavigationStarting;
  FWindowParent.Initialize;
end;

procedure TModelBrowserVCLWebView2.HandleNavigationStarting(const Uri: string; var Cancel: Boolean);
var
  Aux, Method, Target: string;
  Params: TStringList;
begin
  Target := Uri;
  if not UpperCase(Target).StartsWith('ACTIONCALLBACKJS') then
    Exit;

  Method := Copy(Target, Pos(':', Target) + 1, Length(Target));
  Method := Copy(Method, 1, Pos('(', Method) - 1);
  Params := TStringList.Create;
  try
    Aux := Copy(Target, Pos('(', Target) + 1, Length(Target));
    Aux := Copy(Aux, 1, LastDelimiter(')', Aux) - 1);
    Params.CommaText := Aux;
    if not Method.IsEmpty then
      if vCallBackJS.TryGetValue(Method, Params) then
        Cancel := True;
  finally
    Params.Free;
  end;
end;

destructor TModelBrowserVCLWebView2.Destroy;
begin
  inherited;
end;

class function TModelBrowserVCLWebView2.New(WindowParent: TWebView2WindowParent): iModelBrowser;
begin
  Result := Self.Create(WindowParent);
end;

procedure TModelBrowserVCLWebView2.WaitReady;
var
  Stopwatch: TStopwatch;
begin
  Stopwatch := TStopwatch.StartNew;
  while not FWindowParent.Ready and (Stopwatch.ElapsedMilliseconds < FWindowParent.OperationTimeoutMs) do
  begin
    Application.ProcessMessages;
    Sleep(1);
  end;

  if not FWindowParent.Ready then
    raise Exception.Create('WebView2 nao ficou pronto a tempo (Environment/Controller).');
end;

procedure TModelBrowserVCLWebView2.ExecuteScript(Value: iModelJSCommand);
begin
  WaitReady;
  FWindowParent.CoreWebView2.ExecuteScript(PWideChar(Value.ResultCommand),
    TCoreWebView2ExecuteScriptCompletedHandler.Create(nil));
end;

procedure TModelBrowserVCLWebView2.ExecuteScriptCallback(Value: iModelJSCommand);
var
  Callback: TProc<HResult, string>;
  UserCallback: TProc<string>;
begin
  UserCallback := Value.CallBack;
  if not Assigned(UserCallback) then
    raise Exception.Create('Procedure para Callback invalida');

  WaitReady;
  Callback := procedure(ErrorCode: HResult; Json: string)
    begin
      if ErrorCode = S_OK then
        UserCallback(DecodeJSResult(Json));
    end;
  FWindowParent.CoreWebView2.ExecuteScript(PWideChar(BuildResultExpression(Value)),
    TCoreWebView2ExecuteScriptCompletedHandler.Create(Callback));
end;

function TModelBrowserVCLWebView2.ExecuteScriptResult(Value: iModelJSCommand): string;
var
  Done: Boolean;
  ResultJson: string;
  ResultError: HResult;
  Stopwatch: TStopwatch;
  Callback: TProc<HResult, string>;
begin
  if FWaitingResult then
    raise Exception.Create('ExecuteScriptResult (WebView2) chamado novamente antes do anterior terminar.');

  WaitReady;

  FWaitingResult := True;
  try
    Done := False;
    ResultJson := '';
    ResultError := S_OK;

    Callback := procedure(ErrorCode: HResult; Json: string)
      begin
        ResultError := ErrorCode;
        ResultJson := Json;
        Done := True;
      end;
    FWindowParent.CoreWebView2.ExecuteScript(PWideChar(BuildResultExpression(Value)),
      TCoreWebView2ExecuteScriptCompletedHandler.Create(Callback));

    Stopwatch := TStopwatch.StartNew;
    while not Done and (Stopwatch.ElapsedMilliseconds < FWindowParent.OperationTimeoutMs) do
    begin
      Application.ProcessMessages;
      Sleep(1);
    end;

    if not Done then
      raise Exception.Create('Tempo esgotado aguardando o resultado do ExecuteScript (WebView2).');
    if ResultError <> S_OK then
      raise Exception.CreateFmt('ExecuteScript (WebView2) falhou com HResult=%.8x.', [Cardinal(ResultError)]);

    Result := DecodeJSResult(ResultJson);
  finally
    FWaitingResult := False;
  end;
end;

function TModelBrowserVCLWebView2.Generated(FHTML: string): iModelBrowser;
begin
  Result := Self;
  WaitReady;
  if Length(FHTML) <= cNavigateToStringMaxChars then
    FWindowParent.CoreWebView2.NavigateToString(PWideChar(FHTML))
  else
    { So entra aqui pra HTML grande de verdade (tipicamente CDN(false)).
      Serve via URL virtual interceptada (WebResourceRequested) - ver
      WebView2.WindowParent.pas. Substitui o antigo fallback
      Navigate(file://...) (bug ERR_FILE_NOT_FOUND nunca resolvido). }
    FWindowParent.NavigateToHtml(FHTML);
end;

end.
