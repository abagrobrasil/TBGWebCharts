{$DEFINE FULL}

{$IFNDEF FPC}
  {$IF Declared(FireMonkeyVersion) or Defined(FRAMEWORK_FMX) or Defined(LINUX64)}
    {$DEFINE HAS_FMX}
  {$IFEND}
{$ENDIF}

(* IF CEF is installed, uncomment below*)

  //{$DEFINE HAS_CHROMIUM}

(* IF o WebView2 Runtime e o WebView2Loader.dll estiverem disponiveis (backend VCL), uncomment abaixo*)

  {$DEFINE HAS_WEBVIEW2}