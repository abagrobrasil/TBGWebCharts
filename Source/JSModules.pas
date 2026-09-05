unit JSModules;

{$I TBGWebCharts.inc}

interface

type
  { Cada biblioteca que TPackJS pode incluir no HTML gerado (bundle offline
    OU links de CDN, dependendo do modo). Por default TODAS ficam ligadas
    (cAllJSModules) - identico ao comportamento que a lib sempre teve, pra
    nao quebrar quem ja usa. Vale a pena desligar as que a pagina gerada
    nao precisa: o bundle offline "com tudo" passa de 4 milhoes de
    caracteres, bem acima do teto real do WebView2.NavigateToString
    (~2MB) - ver EVOLUCAO.md, achado de 2026-09-05. }
  TJSModule = (
    jsBootstrap,
    jsJQuery,
    jsPopper,
    jsFontAwesome,
    jsPhosphorIcons,
    jsTetheremin,
    jsUtils,
    jsNumber,
    jsDataTable,
    jsChartEasyPie,
    jsMoment,
    jsChartbundle,
    jsChartStream,
    jsPivotTable,
    jsJQueryUI,
    jsPivotTablePlotly,
    jsGMaps,
    jsD3,
    jsLiquidFillGauge,
    jsQuillEditor,
    jsChartJSScript
  );
  TJSModules = set of TJSModule;

const
  cAllJSModules: TJSModules = [Low(TJSModule)..High(TJSModule)];

implementation

end.
