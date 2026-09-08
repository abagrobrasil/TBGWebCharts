unit PackCss;

interface

uses
  Interfaces,
  Classes;

type
  TPackCss = class(TInterfacedObject,iModelCSS)
    private
      FBackgroundColor : String;
      FFontColor : String;
      FBorderColor : String;
      FCDN : Boolean;
    public
      constructor Create;
      destructor Destroy; override;
      class function New : iModelCSS;
      function PackCSS : String;
      function CDN(Value : Boolean) : iModelCSS;
      function BackgroundColor ( Value : String ) :  iModelCSS;
      function BorderColor ( Value : String ) : iModelCSS;
      function FontColor ( Value : String ) : iModelCSS;
  end;

implementation

uses
  StyleCSS,
  BootstrapCss,
  DataTableCss,
  Chart.Easy.PieCSS,
  PivotTableCSS,
  LiquidFillGaugeCSS,
  QuillEditorCSS;

{ TPackCss }

function TPackCss.BackgroundColor(Value: String): iModelCSS;
begin
  Result := Self;
  FBackgroundColor := Value;
end;

function TPackCss.BorderColor(Value: String): iModelCSS;
begin
  Result := Self;
  FBorderColor := Value;
end;

function TPackCss.CDN(Value: Boolean): iModelCSS;
begin
  Result := SElf;
  FCDN := Value;
end;

constructor TPackCss.Create;
begin
  FCDN := False;
end;

destructor TPackCss.Destroy;
begin
  inherited;
end;

function TPackCss.FontColor(Value: String): iModelCSS;
begin
  Result := Self;
  FFontColor := Value;
end;

class function TPackCss.New: iModelCSS;
begin
  Result := Self.Create;
end;

function TPackCss.PackCSS: String;
begin
  if FCDN then
  begin
    Result := Result + '<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.3/css/bootstrap.min.css">';
		Result := Result + '<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/v/bs5/jq-3.6.0/dt-1.13.11/r-2.5.0/sl-1.7.0/datatables.min.css"/>';
    { thuliobittencourt.com/tbgwebcharts (host pessoal) fora do ar - 404
      confirmado em 2026-09-05. Trocado pro mesmo host oficial que ja
      serve o pivot.js (ver PivotTableJS.pas), pivottable.js.org - projeto
      ativo, nao depende de ninguem pessoal. }
    Result := Result + '<link rel="stylesheet" type="text/css" href="https://pivottable.js.org/dist/pivot.css">';
    Result := Result + '<link rel="stylesheet" href="https://cdn.quilljs.com/1.3.6/quill.snow.css">';
    Result := Result + TStyleCSS.New
                        .BackgroundColor(FBackgroundColor)
                        .FontColor(FFontColor)
                        .BorderColor(FBorderColor)
                        .PackCSS;
    Result := Result + TChartEasyPieCSS.New.PackCSS;
    Result := Result + TLiquidFillGaugeCSS.New.PackCSS;
    Result := Result + TQuillEditorCSS.New.CDN(FCDN).PackCSS;
  end
  else
    Result :=  TBootstrapCss.New
              .PackCSS+
            TDataTableCss.New
              .PackCSS+
            TStyleCSS.New
              .BackgroundColor(FBackgroundColor)
              .FontColor(FFontColor)
              .BorderColor(FBorderColor)
              .PackCSS+
            TChartEasyPieCSS.New.PackCSS+
            TPivotTableCSS.New.PackCSS+
            TLiquidFillGaugeCSS.New.PackCSS+
            TQuillEditorCSS.New.PackCSS;
end;

end.
