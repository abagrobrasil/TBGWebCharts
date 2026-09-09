object Form7: TForm7
  Left = 0
  Top = 0
  Caption = 'Form7'
  ClientHeight = 433
  ClientWidth = 689
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 689
    Height = 392
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 685
    ExplicitHeight = 391
    object WebView2WindowParent1: TWebView2WindowParent
      Left = 0
      Top = 0
      Width = 689
      Height = 392
      Align = alClient
      TabOrder = 0
      ExplicitLeft = 360
      ExplicitTop = 160
      ExplicitWidth = 100
      ExplicitHeight = 41
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 392
    Width = 689
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitTop = 391
    ExplicitWidth = 685
    object Button1: TButton
      Left = 0
      Top = 0
      Width = 105
      Height = 41
      Align = alLeft
      Caption = 'Generate'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 105
      Top = 0
      Width = 105
      Height = 41
      Align = alLeft
      Caption = 'Save Content'
      TabOrder = 1
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 315
      Top = 0
      Width = 105
      Height = 41
      Align = alLeft
      Caption = 'Save Text'
      TabOrder = 2
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 420
      Top = 0
      Width = 105
      Height = 41
      Align = alLeft
      Caption = 'Save Html'
      TabOrder = 3
      OnClick = Button4Click
    end
    object Button5: TButton
      Left = 525
      Top = 0
      Width = 105
      Height = 41
      Align = alLeft
      Caption = 'Print'
      TabOrder = 4
      OnClick = Button5Click
    end
    object Button6: TButton
      Left = 210
      Top = 0
      Width = 105
      Height = 41
      Align = alLeft
      Caption = 'Load Content'
      TabOrder = 5
      OnClick = Button6Click
    end
  end
  object WebCharts1: TWebCharts
    Left = 632
    Top = 360
  end
end
