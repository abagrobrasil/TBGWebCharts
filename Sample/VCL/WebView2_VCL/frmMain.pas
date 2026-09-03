unit frmMain;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  WebView2.WindowParent,
  View.WebCharts;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Panel1: TPanel;
    Panel2: TPanel;
    WebView2WindowParent1: TWebView2WindowParent;
    WebCharts1: TWebCharts;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
  strict private
    FContent: String;
  public
    procedure SaveContent(aValue: String);
    procedure SaveRichText(aValue: String);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{ Botao "Generate": exercita IModelBrowser.Generated (grava HTML num arquivo
  temporario e chama CoreWebView2.Navigate) - ver Browser.VCL.WebView2.pas. }
procedure TForm1.Button1Click(Sender: TObject);
begin
  WebCharts1
  .CDN(true)
  .NewProject
    .RichTextEditor
      .Attributes
        .Height('400px')
        .Width('600px')
        .PlaceHolder('Enter your text here')
        .Content('Hello World!\nRenderizado via WebView2')
      .&End
    .&End
  .WebBrowser(WebView2WindowParent1)
  .Generated;
end;

{ Os botoes abaixo exercitam IModelBrowser.ExecuteScriptCallback (roundtrip
  JS -> Delphi via ICoreWebView2.ExecuteScript). }
procedure TForm1.Button2Click(Sender: TObject);
begin
  WebCharts1
  .ContinuosProject
  .WebBrowser(WebView2WindowParent1)
    .RichTextEditor
    .SaveContent(SaveContent);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  WebCharts1
  .ContinuosProject
  .WebBrowser(WebView2WindowParent1)
    .RichTextEditor
    .SaveContentText(SaveRichText);
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  WebCharts1
  .ContinuosProject
  .WebBrowser(WebView2WindowParent1)
    .RichTextEditor
    .SaveContentHtml(SaveRichText);
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  WebCharts1
  .ContinuosProject
  .WebBrowser(WebView2WindowParent1)
  .Print;
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  WebCharts1
  .ContinuosProject
  .WebBrowser(WebView2WindowParent1)
    .RichTextEditor
    .LoadContent(FContent);
end;

procedure TForm1.SaveContent(aValue: String);
begin
  FContent := aValue;
  ShowMessage(FContent);
end;

procedure TForm1.SaveRichText(aValue: String);
begin
  ShowMessage(aValue);
end;

end.
