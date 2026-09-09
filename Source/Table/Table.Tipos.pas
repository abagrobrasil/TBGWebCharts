unit Table.Tipos;

interface

type
  { Alinhamento de texto pra cabecalho/corpo da Table (DataTables) -
    taDefault preserva o comportamento atual (campo numerico alinha
    a direita automaticamente, resto sem classe nenhuma); os outros 3
    valores forcam a classe do Bootstrap 5 em TODAS as celulas,
    sobrescrevendo essa logica automatica. Ver IModelTableDataSet.TextAlignHead/
    TextAlignBody em Interfaces.pas. }
  TTextAlign = (taDefault, taStart, taCenter, taEnd);

function TextAlignClass(Value: TTextAlign): string;

implementation

function TextAlignClass(Value: TTextAlign): string;
begin
  case Value of
    taStart: Result := 'text-start';
    taCenter: Result := 'text-center';
    taEnd: Result := 'text-end';
  else
    Result := '';
  end;
end;

end.
