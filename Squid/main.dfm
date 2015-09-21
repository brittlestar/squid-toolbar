object MainForm: TMainForm
  Left = 473
  Top = 242
  AlphaBlend = True
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'Squid'
  ClientHeight = 180
  ClientWidth = 209
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnMouseWheelDown = FormMouseWheelDown
  OnMouseWheelUp = FormMouseWheelUp
  PixelsPerInch = 96
  TextHeight = 13
  object panelMain: TPanel
    Left = 0
    Top = 0
    Width = 73
    Height = 305
    BevelOuter = bvNone
    TabOrder = 0
    object panelExeFiles: TPanel
      Left = 0
      Top = 0
      Width = 49
      Height = 305
      BevelOuter = bvNone
      TabOrder = 0
    end
  end
  object JvCaptionButton1: TJvCaptionButton
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Standard = tsbClose
    OnClick = JvCaptionButton1Click
    Left = 40
    Top = 8
  end
  object JvAppRegistryStorage1: TJvAppRegistryStorage
    StorageOptions.BooleanStringTrueValues = 'TRUE, YES, Y'
    StorageOptions.BooleanStringFalseValues = 'FALSE, NO, N'
    RegRoot = hkLocalMachine
    Root = '%NONE%'
    SubStorages = <>
    Left = 72
    Top = 8
  end
  object TimerHideShow: TTimer
    Enabled = False
    Interval = 10
    OnTimer = TimerHideShowTimer
    Left = 8
    Top = 8
  end
end
