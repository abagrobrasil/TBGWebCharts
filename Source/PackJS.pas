unit PackJS;
{$I TBGWebCharts.inc}
interface
uses
  Interfaces,
  JSModules,
  Classes;
type
  TPackJS = class(TInterfacedObject,iModelJS,iModelJSPack)
    private
      FPack : TStringList;
      FCDN : Boolean;
      FModules : TJSModules;
      FCredenciais : iModelCredenciais;
      function UpdateDomElement : string;
    public
      constructor Create;
      destructor Destroy; override;
      class function New : iModelJSPack;
      function PackJS : String;
      function CDN(Value : Boolean) : iModelJS;
      function Modules(Value : TJSModules) : iModelJSPack;
      function Credenciais(Value : iModelCredenciais) : iModelJS;
  end;
implementation
uses
  SysUtils,
  BootstrapJS,
  ChartbundleJS,
  FontawesomeallJS,
  PhosphorIconsJS,
	JqueryJS,
  PopperJS,
  TetherminJS,
  UtilsJS,
  NumberJS,
  DataTableJS,
  Chart.Easy.PieJS,
  Chart.Easy.PieCSS,
  PivotTableJS,
  JQuery.UIJS,
  PivotTablePlotlyJS,
  PivotTablePlotlyRendersJS,
  MomentJS,
  ChartStreamJS,
  GMapsJS,
  LiquidFillGaugeJS,
  D3JS,
  QuillEditorJS, QuillDeltaConverter, ChartJSScript;
{ TPackJS }
function TPackJS.CDN(Value: Boolean): iModelJS;
begin
  Result := Self;
  FCDN := Value;
end;
constructor TPackJS.Create;
begin
  FPack := TStringList.Create;
  FCDN := False;
  FModules := cAllJSModules;
end;

function TPackJS.Modules(Value: TJSModules): iModelJSPack;
begin
  Result := Self;
  FModules := Value;
end;
function TPackJS.Credenciais(Value: iModelCredenciais): iModelJS;
begin
  Result := Self;
  FCredenciais := Value;
end;

destructor TPackJS.Destroy;
begin
  freeandnil(fpack);
  inherited;
end;
class function TPackJS.New: iModelJSPack;
begin
  Result := Self.Create;
end;
function TPackJS.PackJS : String;
begin
  if FCDN then
  begin
    if jsJQuery in FModules then
      Result := Result + TJqueryJS.New.CDN(FCDN).PackJS;
    if jsPopper in FModules then
      Result := Result + TPopperJS.New.CDN(FCDN).PackJS;
    if jsBootstrap in FModules then
      Result := Result + TBootstrapJS.New.CDN(FCDN).PackJS;
    if jsFontAwesome in FModules then
      Result := Result + TFontawesomeallJS.New.CDN(FCDN).PackJS;
    if jsPhosphorIcons in FModules then
      Result := Result + TPhosphorIconsJS.New.CDN(FCDN).PackJS;
    if jsDataTable in FModules then
      Result := Result + TDataTableJS.New.CDN(FCDN).PackJS;
    if jsChartEasyPie in FModules then
      Result := Result + TChartEasyPieJS.New.CDN(FCDN).PackJS;
    if jsMoment in FModules then
      Result := Result + TMomentJS.New.CDN(FCDN).PackJS;
    if jsChartbundle in FModules then
      Result := Result + TChartbundleJS.New.CDN(FCDN).PackJS;
    if jsChartStream in FModules then
      Result := Result + TChartStreamJS.New.CDN(FCDN).PackJS;
    if jsNumber in FModules then
      Result := Result + '<script src="https://cdnjs.cloudflare.com/ajax/libs/numeral.js/2.0.6/numeral.min.js"></script>';
    if jsPivotTable in FModules then
      Result := Result + TPivotTableJS.New.CDN(FCDN).PackJS;
    if jsJQueryUI in FModules then
      Result := Result + TJQueryUIJS.New.CDN(FCDN).PackJS;
    if jsPivotTablePlotly in FModules then
    begin
      Result := Result + TPivotTablePlotlyJS.New.CDN(FCDN).PackJS;
      Result := Result + TPivotTablePlotlyRendersJS.New.CDN(FCDN).PackJS;
    end;
    if jsGMaps in FModules then
      Result := Result + TGMapsJS.New.Credenciais(FCredenciais).CDN(FCDN).PackJS;
    if jsD3 in FModules then
      Result := Result + TD3JS.New.CDN(FCDN).PackJS;
    if jsLiquidFillGauge in FModules then
      Result := Result + TLiquidFillGaugeJS.New.CDN(FCDN).PackJS;
    if jsQuillEditor in FModules then
    begin
      Result := Result + TQuillEditorJS.New.CDN(FCDN).PackJS;
      Result := Result + TQuillDeltaConverter.New.CDN(FCDN).PackJS;
    end;
    if jsChartJSScript in FModules then
      Result := Result + TChartJSScript.New.CDN(FCDN).PackJS;
    if jsNumber in FModules then
    begin
    Result := Result + '<script>';
    Result := Result + '(function (global, factory) {';
    Result := Result + '    if (typeof define === ''function'' && define.amd) {';
    Result := Result + '        define([''../numeral''], factory);';
    Result := Result + '    } else if (typeof module === ''object'' && module.exports) {';
    Result := Result + '        factory(require(''../numeral''));';
    Result := Result + '    } else {';
    Result := Result + '        factory(global.numeral);';
    Result := Result + '    }';
    Result := Result + '}(this, function (numeral) {';
    Result := Result + '    numeral.register(''locale'', ''pt-br'', {';
    Result := Result + '        delimiters: {';
    Result := Result + '            thousands: ''.'',';
    Result := Result + '            decimal: '',''';
    Result := Result + '        },';
    Result := Result + '        abbreviations: {';
    Result := Result + '            thousand: ''mil'',';
    Result := Result + '            million: ''milh�es'',';
    Result := Result + '            billion: ''b'',';
    Result := Result + '            trillion: ''t''';
    Result := Result + '        },';
    Result := Result + '        ordinal: function (number) {';
    Result := Result + '            return ''�'';';
    Result := Result + '        },';
    Result := Result + '        currency: {';
    Result := Result + '            symbol: ''R$''';
    Result := Result + '        }';
    Result := Result + '    });';
    Result := Result + '}));';
    Result := Result + '</script>';
    end;
  end
  else
  begin
    Result := FPack.Text;
    if jsJQuery in FModules then
      Result := Result + TJqueryJS.New.PackJS;
    if jsPopper in FModules then
      Result := Result + TPopperJS.New.PackJS;
    if jsBootstrap in FModules then
      Result := Result + TBootstrapJS.New.PackJS;
    if jsFontAwesome in FModules then
      Result := Result + TFontawesomeallJS.New.PackJS;
    if jsPhosphorIcons in FModules then
      Result := Result + TPhosphorIconsJS.New.CDN(FCDN).PackJS;
    if jsTetheremin in FModules then
      Result := Result + TTetherminJS.New.PackJS;
    if jsUtils in FModules then
      Result := Result + TUtilsJS.New.PackJS;
    if jsNumber in FModules then
      Result := Result + TNumberJS.New.PackJS;
    if jsDataTable in FModules then
      Result := Result + TDataTableJS.New.PackJS;
    if jsChartEasyPie in FModules then
      Result := Result + TChartEasyPieJS.New.PackJS;
    if jsMoment in FModules then
      Result := Result + TMomentJs.New.PackJS;
    if jsChartbundle in FModules then
      Result := Result + TChartbundleJS.New.PackJS;
    if jsChartStream in FModules then
      Result := Result + TChartStreamJS.New.PackJS;
    if jsPivotTable in FModules then
      Result := Result + TPivotTableJS.New.PackJS;
    if jsJQueryUI in FModules then
      Result := Result + TJQueryUIJS.New.PackJS;
    if jsPivotTablePlotly in FModules then
    begin
      Result := Result + TPivotTablePlotlyJS.New.PackJS;
      Result := Result + TPivotTablePlotlyRendersJs.New.PackJS;
    end;
    if jsGMaps in FModules then
      Result := Result + TGMapsJS.New.Credenciais(FCredenciais).PackJS;
    if jsD3 in FModules then
      Result := Result + TD3JS.New.PackJS;
    if jsLiquidFillGauge in FModules then
      Result := Result + TLiquidFillGaugeJS.New.PackJS;
    if jsQuillEditor in FModules then
    begin
      Result := Result + TQuillEditorJS.New.CDN(FCDN).PackJS;
      Result := Result + TQuillDeltaConverter.New.CDN(FCDN).PackJS;
    end;
    if jsChartJSScript in FModules then
      Result := Result + TChartJSScript.New.CDN(FCDN).PackJS;
  end;
  Result := Result + UpdateDomElement;
end;
function TPackJS.UpdateDomElement: string;
begin
  Result := '<script>' +
              'function UpdateDOM(elementId, html) {' +
                'let DOMElement = document.getElementById(elementId);' +
                'if (DOMElement) {' +
                  'DOMElement.innerHTML = html;' +
                '}' +
              '}' +
            '</script>';
end;

end.
