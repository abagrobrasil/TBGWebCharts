object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 595
  ClientWidth = 954
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object Button1: TButton
    Left = 8
    Top = 43
    Width = 121
    Height = 25
    Caption = 'Gerar'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Edit1: TEdit
    Left = 8
    Top = 16
    Width = 121
    Height = 21
    TabOrder = 1
    Text = '5'
  end
  object Panel1: TPanel
    Left = 135
    Top = 0
    Width = 819
    Height = 595
    Align = alRight
    Caption = 'Panel1'
    TabOrder = 2
    object WebView2WindowParent1: TWebView2WindowParent
      Left = 1
      Top = 1
      Width = 817
      Height = 593
      Align = alClient
      TabOrder = 0
      ExplicitLeft = 368
      ExplicitTop = 240
      ExplicitWidth = 100
      ExplicitHeight = 41
    end
  end
  object WebCharts1: TWebCharts
    Left = 56
    Top = 264
  end
end
