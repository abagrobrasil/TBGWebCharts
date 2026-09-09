unit Table.Tipos;

interface

type
  { Alinhamento de texto pra cabecalho/corpo da Table (DataTables) -
    taDefault preserva o comportamento atual (campo numerico alinha
    a direita automaticamente, resto sem classe nenhuma); os outros 3
    valores forcam a classe do Bootstrap 5 em TODAS as celulas,
    sobrescrevendo essa logica automatica. Ver IModelTableDataSet.TextAlignHead/
    TextAlignBody em Interfaces.pas.
    SCOPEDENUMS de proposito (2026-09-08, achado num app real que consome
    o componente): sem isso, o literal "taCenter" vaza pro namespace
    global (Table.Tipos entra via Interfaces.pas, usado por TUDO que usa
    o componente) e colide com o TAlignment.taCenter padrao da VCL
    (System.Classes/Vcl.StdCtrls) - qualquer app com "Label1.Alignment :=
    taCenter" quebra com "Incompatible types: TTextAlign e TAlignment".
    Com escopo, o acesso vira TTextAlign.taCenter - sem ambiguidade
    possivel, custa só um pouco mais de digitacao. }
  {$SCOPEDENUMS ON}
  TTextAlign = (taDefault, taStart, taCenter, taEnd);
  {$SCOPEDENUMS OFF}

function TextAlignClass(Value: TTextAlign): string;

implementation

function TextAlignClass(Value: TTextAlign): string;
begin
  case Value of
    TTextAlign.taStart: Result := 'text-start';
    TTextAlign.taCenter: Result := 'text-center';
    TTextAlign.taEnd: Result := 'text-end';
  else
    Result := '';
  end;
end;

end.
