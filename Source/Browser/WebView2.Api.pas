unit WebView2.Api;

{$I TBGWebCharts.inc}

{
  Bindings COM minimos para o Microsoft Edge WebView2, escritos a mao (sem
  depender de nenhum wrapper de terceiros em runtime).

  Os GUIDs e a ordem dos metodos nas interfaces COM abaixo foram conferidos
  contra o codigo-fonte real do projeto WebView4Delphi (MIT License,
  https://github.com/salvadordf/WebView4Delphi, arquivo
  source/uWVTypeLibrary.pas), que e uma traducao madura e testada do header
  oficial WebView2.h da Microsoft. Nenhum codigo daquele projeto e usado em
  runtime aqui - so os valores (GUIDs, assinaturas, ordem de vtable) foram
  usados como referencia para escrever este subconjunto minimo.

  So estao declarados os metodos das interfaces COM realmente usados por
  este projeto. Como uma interface COM e apenas uma vtable, os metodos
  intermediarios que nao usamos (principalmente pares add_XXX/remove_XXX de
  eventos) precisam continuar declarados, na ordem certa, para que os
  metodos que usamos caiam no slot certo da vtable - mas os parametros do
  tipo "event handler" desses metodos nao utilizados sao tipados como
  IUnknown (todo ponteiro de interface COM tem o mesmo tamanho binario, e
  esses add_XXX nunca sao chamados por este codigo).
}

interface

uses
  Winapi.Windows,
  Winapi.ActiveX,
  System.SysUtils,
  System.Classes,
  System.Variants;

type
  EventRegistrationToken = record
    Value: Int64;
  end;

  ICoreWebView2 = interface;
  ICoreWebView2Controller = interface;
  ICoreWebView2Environment = interface;
  ICoreWebView2Settings = interface;
  ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler = interface;
  ICoreWebView2CreateCoreWebView2ControllerCompletedHandler = interface;
  ICoreWebView2ExecuteScriptCompletedHandler = interface;
  ICoreWebView2NavigationStartingEventArgs = interface;
  ICoreWebView2NavigationStartingEventHandler = interface;
  ICoreWebView2WebResourceRequest = interface;
  ICoreWebView2WebResourceResponse = interface;
  ICoreWebView2WebResourceRequestedEventArgs = interface;
  ICoreWebView2WebResourceRequestedEventHandler = interface;

  { ICoreWebView2Controller - GUID e ordem de metodos conferidos contra
    uWVTypeLibrary.pas (WebView4Delphi). So precisamos ir ate Get_CoreWebView2. }
  ICoreWebView2Controller = interface(IUnknown)
    ['{4D00C0D1-9434-4EB6-8078-8697A560334F}']
    function Get_IsVisible(out IsVisible: Integer): HResult; stdcall;
    function Set_IsVisible(IsVisible: Integer): HResult; stdcall;
    function Get_Bounds(out Bounds: TRect): HResult; stdcall;
    function Set_Bounds(Bounds: TRect): HResult; stdcall;
    function Get_ZoomFactor(out ZoomFactor: Double): HResult; stdcall;
    function Set_ZoomFactor(ZoomFactor: Double): HResult; stdcall;
    function add_ZoomFactorChanged(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_ZoomFactorChanged(Token: EventRegistrationToken): HResult; stdcall;
    function SetBoundsAndZoomFactor(Bounds: TRect; ZoomFactor: Double): HResult; stdcall;
    function MoveFocus(Reason: Integer): HResult; stdcall;
    function add_MoveFocusRequested(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_MoveFocusRequested(Token: EventRegistrationToken): HResult; stdcall;
    function add_GotFocus(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_GotFocus(Token: EventRegistrationToken): HResult; stdcall;
    function add_LostFocus(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_LostFocus(Token: EventRegistrationToken): HResult; stdcall;
    function add_AcceleratorKeyPressed(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_AcceleratorKeyPressed(Token: EventRegistrationToken): HResult; stdcall;
    function Get_ParentWindow(out ParentWindow: HWND): HResult; stdcall;
    function Set_ParentWindow(ParentWindow: HWND): HResult; stdcall;
    function NotifyParentWindowPositionChanged: HResult; stdcall;
    function Close: HResult; stdcall;
    function Get_CoreWebView2(out CoreWebView2: ICoreWebView2): HResult; stdcall;
  end;

  { ICoreWebView2 - GUID e ordem de metodos conferidos contra uWVTypeLibrary.pas
    (WebView4Delphi). Vai ate AddWebResourceRequestedFilter - precisado pra
    servir o HTML gerado via URL virtual interceptada (WebResourceRequested),
    em vez de NavigateToString (limite reais de ~2MB) ou Navigate(file://...)
    (bug ERR_FILE_NOT_FOUND nunca resolvido). Os metodos entre ExecuteScript
    e AddWebResourceRequestedFilter que nao usamos ficam com parametros
    genericos (IUnknown/Integer) so pra vtable nao desalinhar. }
  ICoreWebView2 = interface(IUnknown)
    ['{76ECEACB-0462-4D94-AC83-423A6793775E}']
    function Get_Settings(out Settings: ICoreWebView2Settings): HResult; stdcall;
    function Get_Source(out Uri: PWideChar): HResult; stdcall;
    function Navigate(Uri: PWideChar): HResult; stdcall;
    function NavigateToString(HtmlContent: PWideChar): HResult; stdcall;
    function add_NavigationStarting(const EventHandler: ICoreWebView2NavigationStartingEventHandler; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_NavigationStarting(Token: EventRegistrationToken): HResult; stdcall;
    function add_ContentLoading(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_ContentLoading(Token: EventRegistrationToken): HResult; stdcall;
    function add_SourceChanged(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_SourceChanged(Token: EventRegistrationToken): HResult; stdcall;
    function add_HistoryChanged(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_HistoryChanged(Token: EventRegistrationToken): HResult; stdcall;
    function add_NavigationCompleted(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_NavigationCompleted(Token: EventRegistrationToken): HResult; stdcall;
    function add_FrameNavigationStarting(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_FrameNavigationStarting(Token: EventRegistrationToken): HResult; stdcall;
    function add_FrameNavigationCompleted(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_FrameNavigationCompleted(Token: EventRegistrationToken): HResult; stdcall;
    function add_ScriptDialogOpening(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_ScriptDialogOpening(Token: EventRegistrationToken): HResult; stdcall;
    function add_PermissionRequested(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_PermissionRequested(Token: EventRegistrationToken): HResult; stdcall;
    function add_ProcessFailed(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_ProcessFailed(Token: EventRegistrationToken): HResult; stdcall;
    function AddScriptToExecuteOnDocumentCreated(JavaScript: PWideChar; const Handler: IUnknown): HResult; stdcall;
    function RemoveScriptToExecuteOnDocumentCreated(Id: PWideChar): HResult; stdcall;
    function ExecuteScript(JavaScript: PWideChar; const Handler: ICoreWebView2ExecuteScriptCompletedHandler): HResult; stdcall;
    function CapturePreview(ImageFormat: Integer; const ImageStream: IUnknown; const Handler: IUnknown): HResult; stdcall;
    function Reload: HResult; stdcall;
    function PostWebMessageAsJson(WebMessageAsJson: PWideChar): HResult; stdcall;
    function PostWebMessageAsString(WebMessageAsString: PWideChar): HResult; stdcall;
    function add_WebMessageReceived(const Handler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_WebMessageReceived(Token: EventRegistrationToken): HResult; stdcall;
    function CallDevToolsProtocolMethod(MethodName: PWideChar; ParametersAsJson: PWideChar; const Handler: IUnknown): HResult; stdcall;
    function Get_BrowserProcessId(out Value: Cardinal): HResult; stdcall;
    function Get_CanGoBack(out CanGoBack: Integer): HResult; stdcall;
    function Get_CanGoForward(out CanGoForward: Integer): HResult; stdcall;
    function GoBack: HResult; stdcall;
    function GoForward: HResult; stdcall;
    function GetDevToolsProtocolEventReceiver(EventName: PWideChar; out Receiver: IUnknown): HResult; stdcall;
    function Stop: HResult; stdcall;
    function add_NewWindowRequested(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_NewWindowRequested(Token: EventRegistrationToken): HResult; stdcall;
    function add_DocumentTitleChanged(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_DocumentTitleChanged(Token: EventRegistrationToken): HResult; stdcall;
    function Get_DocumentTitle(out Title: PWideChar): HResult; stdcall;
    function AddHostObjectToScript(Name: PWideChar; const Obj: OleVariant): HResult; stdcall;
    function RemoveHostObjectFromScript(Name: PWideChar): HResult; stdcall;
    function OpenDevToolsWindow: HResult; stdcall;
    function add_ContainsFullScreenElementChanged(const EventHandler: IUnknown; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_ContainsFullScreenElementChanged(Token: EventRegistrationToken): HResult; stdcall;
    function Get_ContainsFullScreenElement(out Value: Integer): HResult; stdcall;
    function add_WebResourceRequested(const EventHandler: ICoreWebView2WebResourceRequestedEventHandler; out Token: EventRegistrationToken): HResult; stdcall;
    function remove_WebResourceRequested(Token: EventRegistrationToken): HResult; stdcall;
    function AddWebResourceRequestedFilter(Uri: PWideChar; ResourceContext: Integer): HResult; stdcall;
  end;

  { ICoreWebView2Settings - existe apenas para tipar o parametro "out" de
    Get_Settings (primeiro metodo de ICoreWebView2, precisa estar declarado
    por causa da ordem da vtable). Nenhum metodo seu e chamado por este
    projeto, entao o GUID abaixo e so um placeholder (nao foi conferido
    contra a API real) - isso e seguro porque nunca fazemos QueryInterface
    nem chamamos metodo nenhum desta interface. }
  ICoreWebView2Settings = interface(IUnknown)
    ['{6D19B599-CB19-4C8E-9AC0-9F81A2DB0C4B}']
  end;

  { ICoreWebView2Environment - GUID conferido contra uWVTypeLibrary.pas.
    CreateCoreWebView2Controller e o primeiro metodo da vtable. }
  ICoreWebView2Environment = interface(IUnknown)
    ['{B96D755E-0319-4E92-A296-23436F46A1FC}']
    function CreateCoreWebView2Controller(ParentWindow: HWND;
      const Handler: ICoreWebView2CreateCoreWebView2ControllerCompletedHandler): HResult; stdcall;
    function CreateWebResourceResponse(const Content: IStream; StatusCode: Integer;
      ReasonPhrase: PWideChar; Headers: PWideChar;
      out Response: ICoreWebView2WebResourceResponse): HResult; stdcall;
  end;

  ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler = interface(IUnknown)
    ['{4E8A3389-C9D8-4BD2-B6B5-124FEE6CC14D}']
    function Invoke(ErrorCode: HResult; const Env: ICoreWebView2Environment): HResult; stdcall;
  end;

  ICoreWebView2CreateCoreWebView2ControllerCompletedHandler = interface(IUnknown)
    ['{6C4819F3-C9B7-4260-8127-C9F5BDE7F68C}']
    function Invoke(ErrorCode: HResult; const Ctrl: ICoreWebView2Controller): HResult; stdcall;
  end;

  ICoreWebView2ExecuteScriptCompletedHandler = interface(IUnknown)
    ['{49511172-CC67-4BCA-9923-137112F4C4CC}']
    function Invoke(ErrorCode: HResult; ResultObjectAsJson: PWideChar): HResult; stdcall;
  end;

  { ICoreWebView2NavigationStartingEventArgs - GUID e ordem de metodos
    conferidos, um a um, contra uWVTypeLibrary.pas (WebView4Delphi): Get_uri,
    Get_IsUserInitiated, Get_IsRedirected, Get_RequestHeaders, Get_Cancel,
    Set_Cancel, Get_NavigationId - nessa ordem exata. So usamos Get_Uri e
    Set_Cancel, mas os demais precisam continuar declarados (mesmo sem
    nenhuma chamada) pra vtable nao desalinhar; Get_RequestHeaders e tipado
    como IUnknown por nunca ser chamado (todo ponteiro de interface COM tem
    o mesmo tamanho binario - mesma logica do add_XXX/remove_XXX em
    ICoreWebView2). Uma tentativa anterior de declarar esta interface (sem
    o Delphi IDE disponivel pra conferir passo a passo) causou access
    violation ao chamar Get_Uri/Set_Cancel - suspeita forte de que a
    causa era exatamente algum destes metodos faltando ou fora de ordem. }
  ICoreWebView2NavigationStartingEventArgs = interface(IUnknown)
    ['{5B495469-E119-438A-9B18-7604F25F2E49}']
    function Get_Uri(out Uri: PWideChar): HResult; stdcall;
    function Get_IsUserInitiated(out IsUserInitiated: Integer): HResult; stdcall;
    function Get_IsRedirected(out IsRedirected: Integer): HResult; stdcall;
    function Get_RequestHeaders(out RequestHeaders: IUnknown): HResult; stdcall;
    function Get_Cancel(out Cancel: Integer): HResult; stdcall;
    function Set_Cancel(Cancel: Integer): HResult; stdcall;
    function Get_NavigationId(out NavigationId: UInt64): HResult; stdcall;
  end;

  { ICoreWebView2NavigationStartingEventHandler - GUID conferido contra
    uWVTypeLibrary.pas (WebView4Delphi). Ao contrario dos handlers "de uma
    vez so" acima, este e um handler de evento PERSISTENTE (registrado via
    ICoreWebView2.add_NavigationStarting e disparado a cada navegacao ate
    ser removido com remove_NavigationStarting) - por isso quem o registra
    precisa manter uma referencia forte pra ele (ver
    TWebView2WindowParent.FNavigationStartingHandler), senao o objeto pode
    ser liberado antes do evento disparar. }
  ICoreWebView2NavigationStartingEventHandler = interface(IUnknown)
    ['{9ADBE429-F36D-432B-9DDC-F8881FBD76E3}']
    function Invoke(const Sender: ICoreWebView2;
      const Args: ICoreWebView2NavigationStartingEventArgs): HResult; stdcall;
  end;

  { ICoreWebView2WebResourceResponse - nunca chamamos nenhum metodo dela,
    so guardamos a referencia que CreateWebResourceResponse devolve e
    entregamos pra Set_Response; por isso fica vazia (mesmo raciocinio do
    placeholder ICoreWebView2Settings acima - seguro so por nunca fazermos
    QueryInterface nem chamar metodo nenhum dela). }
  ICoreWebView2WebResourceResponse = interface(IUnknown)
    ['{AAFCC94F-FA27-48FD-97DF-830EF75AAEC9}']
  end;

  { ICoreWebView2WebResourceRequest - GUID e ordem conferidos contra
    uWVTypeLibrary.pas. So usamos Get_Uri; os demais (Set_Uri/Get_Method/
    Set_Method/Get_Content/Set_Content/Get_Headers) ficam com tipos
    genericos so pra vtable nao desalinhar. }
  ICoreWebView2WebResourceRequest = interface(IUnknown)
    ['{97055CD4-512C-4264-8B5F-E3F446CEA6A5}']
    function Get_Uri(out Uri: PWideChar): HResult; stdcall;
    function Set_Uri(Uri: PWideChar): HResult; stdcall;
    function Get_Method(out Method: PWideChar): HResult; stdcall;
    function Set_Method(Method: PWideChar): HResult; stdcall;
    function Get_Content(out Content: IStream): HResult; stdcall;
    function Set_Content(const Content: IStream): HResult; stdcall;
    function Get_Headers(out Headers: IUnknown): HResult; stdcall;
  end;

  { ICoreWebView2WebResourceRequestedEventArgs - GUID e ordem conferidos
    contra uWVTypeLibrary.pas: Get_Request, Get_Response, Set_Response,
    GetDeferral, Get_ResourceContext - nessa ordem exata. Usamos Get_Request
    e Set_Response; GetDeferral/Get_ResourceContext ficam genericos. }
  ICoreWebView2WebResourceRequestedEventArgs = interface(IUnknown)
    ['{453E667F-12C7-49D4-BE6D-DDBE7956F57A}']
    function Get_Request(out Request: ICoreWebView2WebResourceRequest): HResult; stdcall;
    function Get_Response(out Response: ICoreWebView2WebResourceResponse): HResult; stdcall;
    function Set_Response(const Response: ICoreWebView2WebResourceResponse): HResult; stdcall;
    function GetDeferral(out Deferral: IUnknown): HResult; stdcall;
    function Get_ResourceContext(out Context: Integer): HResult; stdcall;
  end;

  { ICoreWebView2WebResourceRequestedEventHandler - GUID conferido contra
    uWVTypeLibrary.pas. Handler PERSISTENTE (igual NavigationStarting) -
    quem registra precisa manter referencia forte (ver
    TWebView2WindowParent.FWebResourceRequestedHandler). }
  ICoreWebView2WebResourceRequestedEventHandler = interface(IUnknown)
    ['{AB00B74C-15F1-4646-80E8-E76341D25D71}']
    function Invoke(const Sender: ICoreWebView2;
      const Args: ICoreWebView2WebResourceRequestedEventArgs): HResult; stdcall;
  end;

  { Implementacoes reutilizaveis dos handlers acima, cada uma recebendo
    uma anonymous method no construtor. }

  TCoreWebView2EnvironmentCompletedHandler = class(TInterfacedObject, ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler)
  private
    FCallback: TProc<HResult, ICoreWebView2Environment>;
  public
    constructor Create(Callback: TProc<HResult, ICoreWebView2Environment>);
    function Invoke(ErrorCode: HResult; const Env: ICoreWebView2Environment): HResult; stdcall;
  end;

  TCoreWebView2ControllerCompletedHandler = class(TInterfacedObject, ICoreWebView2CreateCoreWebView2ControllerCompletedHandler)
  private
    FCallback: TProc<HResult, ICoreWebView2Controller>;
  public
    constructor Create(Callback: TProc<HResult, ICoreWebView2Controller>);
    function Invoke(ErrorCode: HResult; const Ctrl: ICoreWebView2Controller): HResult; stdcall;
  end;

  TCoreWebView2ExecuteScriptCompletedHandler = class(TInterfacedObject, ICoreWebView2ExecuteScriptCompletedHandler)
  private
    FCallback: TProc<HResult, string>;
  public
    constructor Create(Callback: TProc<HResult, string>);
    function Invoke(ErrorCode: HResult; ResultObjectAsJson: PWideChar): HResult; stdcall;
  end;

  { Callback de alto nivel (Uri ja decodificado como string, Cancel como
    Boolean comum) pra quem consome o evento NavigationStarting sem precisar
    lidar com PWideChar/CoTaskMemFree/Integer-como-bool. }
  TWebView2NavigationStartingProc = reference to procedure(const Uri: string; var Cancel: Boolean);

  TCoreWebView2NavigationStartingHandler = class(TInterfacedObject, ICoreWebView2NavigationStartingEventHandler)
  private
    FCallback: TWebView2NavigationStartingProc;
  public
    constructor Create(Callback: TWebView2NavigationStartingProc);
    function Invoke(const Sender: ICoreWebView2;
      const Args: ICoreWebView2NavigationStartingEventArgs): HResult; stdcall;
  end;

  { Callback de alto nivel pro WebResourceRequested: entrega so a Uri ja
    decodificada como string. O Args crua e repassado pra quem consome (ver
    TWebView2WindowParent) montar e entregar a resposta via
    ICoreWebView2Environment.CreateWebResourceResponse + Args.Set_Response -
    isso fica fora deste unit porque exige o Environment, que so o
    WindowParent tem a mao. }
  TWebView2WebResourceRequestedProc = reference to procedure(const Uri: string;
    const Args: ICoreWebView2WebResourceRequestedEventArgs);

  TCoreWebView2WebResourceRequestedHandler = class(TInterfacedObject, ICoreWebView2WebResourceRequestedEventHandler)
  private
    FCallback: TWebView2WebResourceRequestedProc;
  public
    constructor Create(Callback: TWebView2WebResourceRequestedProc);
    function Invoke(const Sender: ICoreWebView2;
      const Args: ICoreWebView2WebResourceRequestedEventArgs): HResult; stdcall;
  end;

{ Carrega WebView2Loader.dll dinamicamente (LoadLibrary/GetProcAddress) e
  chama CreateCoreWebView2EnvironmentWithOptions com opcoes padrao (nil).
  Levanta excecao com mensagem clara se a DLL nao for encontrada/carregada. }
function WebView2_CreateEnvironment(const Handler: ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler): HResult;

{ Indica se WebView2Loader.dll ja foi carregada com sucesso nesta sessao. }
function WebView2_LoaderAvailable: Boolean;

implementation

type
  TCreateCoreWebView2EnvironmentWithOptions = function(BrowserExecutableFolder,
    UserDataFolder: PWideChar; EnvironmentOptions: IUnknown;
    const EnvironmentCreatedHandler: ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler): HResult; stdcall;

var
  vLoaderModule: HMODULE = 0;
  vCreateCoreWebView2EnvironmentWithOptions: TCreateCoreWebView2EnvironmentWithOptions = nil;

function EnsureLoader: Boolean;
begin
  if vLoaderModule = 0 then
  begin
    vLoaderModule := LoadLibrary('WebView2Loader.dll');
    if vLoaderModule <> 0 then
      vCreateCoreWebView2EnvironmentWithOptions := GetProcAddress(vLoaderModule, 'CreateCoreWebView2EnvironmentWithOptions');
  end;
  Result := (vLoaderModule <> 0) and Assigned(vCreateCoreWebView2EnvironmentWithOptions);
end;

function WebView2_LoaderAvailable: Boolean;
begin
  Result := EnsureLoader;
end;

function WebView2_CreateEnvironment(const Handler: ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler): HResult;
begin
  if not EnsureLoader then
    raise Exception.Create('WebView2Loader.dll nao encontrada. Copie o arquivo ' +
      'WebView2Loader.dll (arquitetura x86 ou x64, conforme a plataforma de build) ' +
      'para a pasta do executavel. O arquivo vem do pacote NuGet Microsoft.Web.WebView2 ' +
      '(build\native\<arquitetura>\WebView2Loader.dll). Tambem verifique se o WebView2 ' +
      'Runtime esta instalado nesta maquina.');
  Result := vCreateCoreWebView2EnvironmentWithOptions(nil, nil, nil, Handler);
end;

{ TCoreWebView2EnvironmentCompletedHandler }

constructor TCoreWebView2EnvironmentCompletedHandler.Create(Callback: TProc<HResult, ICoreWebView2Environment>);
begin
  inherited Create;
  FCallback := Callback;
end;

function TCoreWebView2EnvironmentCompletedHandler.Invoke(ErrorCode: HResult;
  const Env: ICoreWebView2Environment): HResult;
begin
  if Assigned(FCallback) then
    FCallback(ErrorCode, Env);
  Result := S_OK;
end;

{ TCoreWebView2ControllerCompletedHandler }

constructor TCoreWebView2ControllerCompletedHandler.Create(Callback: TProc<HResult, ICoreWebView2Controller>);
begin
  inherited Create;
  FCallback := Callback;
end;

function TCoreWebView2ControllerCompletedHandler.Invoke(ErrorCode: HResult;
  const Ctrl: ICoreWebView2Controller): HResult;
begin
  if Assigned(FCallback) then
    FCallback(ErrorCode, Ctrl);
  Result := S_OK;
end;

{ TCoreWebView2ExecuteScriptCompletedHandler }

constructor TCoreWebView2ExecuteScriptCompletedHandler.Create(Callback: TProc<HResult, string>);
begin
  inherited Create;
  FCallback := Callback;
end;

function TCoreWebView2ExecuteScriptCompletedHandler.Invoke(ErrorCode: HResult;
  ResultObjectAsJson: PWideChar): HResult;
begin
  if Assigned(FCallback) then
    FCallback(ErrorCode, ResultObjectAsJson);
  Result := S_OK;
end;

{ TCoreWebView2NavigationStartingHandler }

constructor TCoreWebView2NavigationStartingHandler.Create(Callback: TWebView2NavigationStartingProc);
begin
  inherited Create;
  FCallback := Callback;
end;

function TCoreWebView2NavigationStartingHandler.Invoke(const Sender: ICoreWebView2;
  const Args: ICoreWebView2NavigationStartingEventArgs): HResult;
var
  UriPtr: PWideChar;
  Uri: string;
  Cancel: Boolean;
begin
  Result := S_OK;
  if not Assigned(FCallback) or not Assigned(Args) then
    Exit;

  UriPtr := nil;
  if Args.Get_Uri(UriPtr) <> S_OK then
    Exit;
  try
    Uri := UriPtr;
  finally
    if Assigned(UriPtr) then
      CoTaskMemFree(UriPtr);
  end;

  Cancel := False;
  FCallback(Uri, Cancel);
  if Cancel then
    Args.Set_Cancel(1);
end;

{ TCoreWebView2WebResourceRequestedHandler }

constructor TCoreWebView2WebResourceRequestedHandler.Create(Callback: TWebView2WebResourceRequestedProc);
begin
  inherited Create;
  FCallback := Callback;
end;

function TCoreWebView2WebResourceRequestedHandler.Invoke(const Sender: ICoreWebView2;
  const Args: ICoreWebView2WebResourceRequestedEventArgs): HResult;
var
  Request: ICoreWebView2WebResourceRequest;
  UriPtr: PWideChar;
  Uri: string;
begin
  Result := S_OK;
  if not Assigned(FCallback) or not Assigned(Args) then
    Exit;

  if (Args.Get_Request(Request) <> S_OK) or not Assigned(Request) then
    Exit;

  UriPtr := nil;
  if Request.Get_Uri(UriPtr) <> S_OK then
    Exit;
  try
    Uri := UriPtr;
  finally
    if Assigned(UriPtr) then
      CoTaskMemFree(UriPtr);
  end;

  FCallback(Uri, Args);
end;

end.
