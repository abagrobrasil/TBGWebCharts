unit View.Reg;

{$I TBGWebCharts.inc}

interface

uses
  Classes;

procedure Register;

implementation

{$R TWebCharts.dcr}

uses
  View.WebCharts
  {$IFDEF HAS_WEBVIEW2}
    {$IFNDEF HAS_FMX}
      , WebView2.WindowParent
    {$ENDIF}
  {$ENDIF};

procedure Register;
begin
     RegisterComponents('TBG WebCharts', [TWebCharts]);
     {$IFDEF HAS_WEBVIEW2}
       {$IFNDEF HAS_FMX}
         RegisterComponents('TBG WebCharts', [TWebView2WindowParent]);
       {$ENDIF}
     {$ENDIF}
end;

end.
