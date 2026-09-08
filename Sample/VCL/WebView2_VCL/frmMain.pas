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
  Data.DB,
  Datasnap.DBClient,
  WebView2.WindowParent,
  JSModules,
  Interfaces,
  View.WebCharts;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
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
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
  strict private
    FContent: String;
    FTableDataSet: TClientDataSet;
    procedure EnsureTableDataSet;
  public
    procedure SaveContent(aValue: String);
    procedure SaveRichText(aValue: String);
    procedure RowEdit(const Value: String);
    procedure RowDelete(const Value: String);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{ Botao "Generate": exercita RichTextEditor (Quill) via CDN (.CDN(true)) -
  ver Browser.VCL.WebView2.pas (Generated escolhe NavigateToString vs
  NavigateToHtml pelo tamanho do HTML).
  Restaurado pra .CDN(true) em 2026-09-05 depois de achar e corrigir o
  bug real: TWebCharts.Create era "constructor Create; reintroduce;" (sem
  parametro), que o streaming do .dfm NUNCA chama pra um componente
  largado no formulario (sempre cria via Create(AOwner) herdado) - FModules
  ficava vazio pra QUALQUER WebCharts1 de formulario, entao PackJS pulava
  TODAS as libs condicionadas a "if jsX in FModules" (Quill incluso),
  gerando HTML sem os <script src> - o que parecia (mas nao era) o
  WebView2 bloqueando scripts externos. PackCss nao usa FModules (sempre
  inclui os <link> de CSS), por isso so os <script> desapareciam - o
  sintoma exato documentado em PENDENCIA-WEBVIEW2-CDN-SCRIPTS.md. Fix em
  View.WebCharts.pas (Create agora e override de Create(AOwner), roda
  sempre). Este botao volta a .CDN(true) pra confirmar que o Quill
  renderiza certo de novo.
  .Modules(cAllJSModules) explicito (2026-09-08): FModules e campo do
  COMPONENTE (WebCharts1), setado uma unica vez no construtor e nunca
  resetado em NewProject - .Modules(...) e "sticky" entre cliques.
  Botao8 (Phosphor Demo) restringe FModules pra so 4 libs; sem este
  reset explicito, clicar Generate DEPOIS do Phosphor Demo gera HTML
  sem jsQuillEditor (editor nao renderiza) - achado testando o upgrade
  do Bootstrap, sem relacao com ele. }
procedure TForm1.Button1Click(Sender: TObject);
begin
  WebCharts1
  .CDN(true)
  .Modules(cAllJSModules)
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

{ Botao "Table Demo": exercita a feature Table (DataTables) via
  IModelBrowser.Generated (render estatico, sem ExecuteScript/
  ExecuteScriptCallback) e as acoes de linha (ActionEdit/ActionDelete), que
  dependem do NavigationStarting interceptar "ActionCallBackJS:Metodo(...)"
  - ver TWebView2WindowParent.OnNavigationStarting em
  Browser.VCL.WebView2.pas.
  ActionEdit/ActionDelete tambem exercitam Image.IconClass(...) (novo,
  2026-09-05) - troca o PNG base64 embutido default por um icon-font
  (aqui, Phosphor via CDN, ja que .CDN(true) esta ligado acima) - ver
  IModelTableActionImage em Interfaces.pas. }
procedure TForm1.EnsureTableDataSet;
begin
  if Assigned(FTableDataSet) then
    Exit;
  FTableDataSet := TClientDataSet.Create(Self);
  FTableDataSet.FieldDefs.Add('Nome', ftString, 40);
  FTableDataSet.FieldDefs.Add('Cidade', ftString, 40);
  FTableDataSet.FieldDefs.Add('Vendas', ftFloat);
  FTableDataSet.CreateDataSet;
  FTableDataSet.AppendRecord(['Ana', 'Curitiba', 1200.50]);
  FTableDataSet.AppendRecord(['Bruno', 'Sao Paulo', 980.00]);
  FTableDataSet.AppendRecord(['Carla', 'Recife', 1575.30]);
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  EnsureTableDataSet;
  WebCharts1
  .CDN(false)
  .Modules(cAllJSModules)
  .NewProject
    .Table
      .TableClass
        .tableSm
        .tableHover
        .tableStriped
      .EndTableClass
      .DataSet
        .DataSet(FTableDataSet)
        .ActionEdit
          .CallbackLink('Nome', 'RowEdit')
          .Image
            .IconClass('ph ph-pencil-simple')
          .&End
        .&End
        .ActionDelete
          .CallbackLink('Nome', 'RowDelete')
          .Image
            .IconClass('ph ph-trash')
          .&End
        .&End
      .&End
    .&End
  .WebBrowser(WebView2WindowParent1)
  .CallbackJS
    .ClassProvider(Self)
  .&End
  .Generated;
end;

{ Botao "Phosphor Demo": exercita o Phosphor Icons via CDN (.CDN(true) -
  PhosphorIconsJS.pas gera <link rel="stylesheet" href=".../jsdelivr/...">
  em vez do bundle offline embutido) - segunda opcao de fonte de icone alem
  do Font Awesome, mesmo padrao de uso (classe CSS num <i>). Caminho recem
  implementado (2026-09-05), ainda nao confirmado em runtime - ver
  EVOLUCAO.md, "Frente paralela: Phosphor Icons".
  .Modules([...]) restringe o HTML gerado so ao que essa demo usa de
  verdade. }
procedure TForm1.Button8Click(Sender: TObject);
begin
  WebCharts1
  .CDN(false)
  .Modules([jsBootstrap, jsJQuery, jsPopper, jsPhosphorIcons])
  .NewProject
    .Rows
      ._Div
        .Add(
          '<div style="font-size:48px; display:flex; gap:24px; align-items:center;">' +
          '<i class="ph ph-heart" style="color:#e63946"></i>' +
          '<i class="ph ph-house"></i>' +
          '<i class="ph ph-chart-bar"></i>' +
          '<i class="ph ph-rocket-launch"></i>' +
          '<i class="ph ph-butterfly"></i>' +
          '</div>')
      .&End
    .&End
  .WebBrowser(WebView2WindowParent1)
  .Generated;
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

procedure TForm1.RowEdit(const Value: String);
begin
  ShowMessage('Editar: ' + Value);
end;

procedure TForm1.RowDelete(const Value: String);
begin
  ShowMessage('Excluir: ' + Value);
end;

end.
