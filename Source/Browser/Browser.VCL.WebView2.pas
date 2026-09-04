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
    FLastTempFile: string;
    FWaitingResult: Boolean;
    procedure WaitReady;
    procedure DeleteLastTempFile;
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
  System.IOUtils,
  System.JSON,
  System.Diagnostics,
  Vcl.Forms;

const
  cWebView2OperationTimeoutMs = 10000;

function BuildResultExpression(const Value: iModelJSCommand): string;
begin
  { Ao contrario do CEF (que precisa do truque "DOMVISITOR" via console.log,
    ver Browser.Chromium.Events.pas), o ExecuteScript do WebView2 ja devolve
    o valor da ultima expressao diretamente no callback - so precisamos
    fazer o comando rodar e, na sequencia, ler o atributo pedido. }
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

{ TModelBrowserVCLWebView2 }

constructor TModelBrowserVCLWebView2.Create(WindowParent: TWebView2WindowParent);
begin
  inherited Create;
  FWindowParent := WindowParent;
  FWindowParent.Initialize;
end;

destructor TModelBrowserVCLWebView2.Destroy;
begin
  DeleteLastTempFile;
  inherited;
end;

procedure TModelBrowserVCLWebView2.DeleteLastTempFile;
begin
  if FLastTempFile.IsEmpty then
    Exit;
  try
    { Melhor esforco: o processo do WebView2 pode ainda estar com o arquivo
      aberto por um instante apos a navegacao (ex.: renderer ainda descarregando
      a pagina anterior). Falha ao apagar aqui nao deve quebrar o fluxo do
      chamador - o arquivo so fica orfao em %TEMP%, o que e o problema que
      esta rotina ja reduz na pratica (era 1 arquivo por Generated(), sem
      nenhuma limpeza). }
    if TFile.Exists(FLastTempFile) then
      TFile.Delete(FLastTempFile);
  except
  end;
  FLastTempFile := '';
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
  while not FWindowParent.Ready and (Stopwatch.ElapsedMilliseconds < cWebView2OperationTimeoutMs) do
    Application.ProcessMessages;

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
    raise Exception.Create('Procedure para Callback inválida');

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
    raise Exception.Create('ExecuteScriptResult (WebView2) chamado novamente antes do ' +
      'anterior terminar - esta instancia nao suporta chamadas sincronas aninhadas ' +
      '(ex.: um evento disparado durante o ProcessMessages da espera atual chamando ' +
      'ExecuteScriptResult de novo).');

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
    while not Done and (Stopwatch.ElapsedMilliseconds < cWebView2OperationTimeoutMs) do
      Application.ProcessMessages;

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
var
  TempFile: string;
  Uri: string;
  Id: TGUID;
begin
  Result := Self;

  WaitReady;

  DeleteLastTempFile;

  CreateGUID(Id);
  TempFile := TPath.Combine(TPath.GetTempPath, 'TBGWebCharts_' + GUIDToString(Id) + '.html');
  TFile.WriteAllText(TempFile, FHTML, TEncoding.UTF8);

  Uri := 'file:///' + StringReplace(TempFile, '\', '/', [rfReplaceAll]);
  FWindowParent.CoreWebView2.Navigate(PWideChar(Uri));

  FLastTempFile := TempFile;
end;

end.
