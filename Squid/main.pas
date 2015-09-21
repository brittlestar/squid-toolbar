// pattern observer/observable sur tapplilist
// ajout de tests unitaire
// ajout d'une icone alphablendé


// in this sample project, you'll find :
//   design pattern observer/observable
//   test driven development using dunit
//   specific Win32 API like SetWindowsHookEx
//   windows shell object handling
//   a tester sous windows 8/10 !
unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ShellAPI, JvDragDrop, AppliList, Menus, OleCtrls,
  Buttons, ActiveX, ShlObj, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdHTTP, IdThreadComponent, WinInet, JvCaptionButton, JvComponent,
  JvAppRegistryStorage, JvGnugettext, JvAppStorage, JvComponentBase;

const
  // user messages constants
  WM_EX_HOOKMOUSE = WM_USER + 1;
  WM_EX_UNINSTALL = WM_USER + 2;
  WM_EX_POSTUPDATE = WM_USER + 3;
  WM_EX_DISPLAYAPPLI = WM_USER + 4;

type
  TMainForm = class(TForm)
    panelMain: TPanel;
    panelExeFiles: TPanel;
    JvCaptionButton1: TJvCaptionButton;
    JvAppRegistryStorage1: TJvAppRegistryStorage;
    TimerHideShow: TTimer;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure JvCaptionButton1Click(Sender: TObject);
    procedure TimerHideShowTimer(Sender: TObject);

  private
    { Private declarations }
    OrgX_M: integer;
    OrgY_M: integer;
    DragCandidate_M: Boolean;
    TopImage_M: TImage;
    HoodDLLHinst_M: THandle;
    BlendIndice_M: integer;

    procedure DragDropDrop(Sender: TObject; Pos: TPoint; Value: TStrings);

    procedure OnHookMessage(var Message_P: TMessage); message WM_EX_HOOKMOUSE;
    procedure OnUninstallMessage(var Message_P: TMessage); message WM_EX_UNINSTALL;
    procedure OnPostUpdate(var Message_P: TMessage); message WM_EX_POSTUPDATE;
    procedure CheckAlignment(iNewX_P, iNewY_P: integer);
    procedure OnRemoveMenuItemClick(Sender: TObject);
    procedure OnMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
    procedure OnMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure OnMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);

    procedure OnDragOver(Sender, Source: TObject; X, Y: integer; State: TDragState; var Accept: Boolean);
    procedure OnDragDrop(Sender, Source: TObject; X, Y: integer);
    procedure OnHelpClick(Sender: TObject);
    procedure OnDisplayAppli(var Mess_P: TMessage); message WM_EX_DISPLAYAPPLI;

  public
    { Public declarations }
    AppliList_M: TAppliList;
    ControlToDestroy_M: TList;
    ComponentToDestroy_M: TList;

    procedure ImageClick(Sender: TObject);
    procedure DisplayAppli;
  end;

  TInstallHookProc = procedure(hWnd_P: HWND); stdcall;
  TUnInstallHookProc = procedure; stdcall;

var
  MainForm: TMainForm;
  InstallHook_G: TInstallHookProc;
  UnInstallHook_G: TUnInstallHookProc;

const
  MAXICONNUMBER = 5;

  ICONHEIGHT = 50;
  ICONWIDTH = 50;

  PANELHEIGHT = 8;

implementation

{$R *.dfm}

// detects if internet connection is available
// returns true/false according to current situation
function DetectionConnexion: Boolean;
var
  Flags_L: DWord;
begin
  Flags_L := INTERNET_CONNECTION_MODEM or INTERNET_CONNECTION_LAN or INTERNET_CONNECTION_PROXY;
  Result := InternetGetConnectedState(@Flags_L, 0);
end;

procedure TMainForm.OnDisplayAppli(var Mess_P: TMessage);
begin
  DisplayAppli;
end;

// event called when wheel click is detected
procedure TMainForm.OnHookMessage(var Message_P: TMessage);
var
  iX_L, iY_L: integer;
begin
  if (Message_P.WParam = WM_MBUTTONDOWN) or (Message_P.WParam = WM_NCMBUTTONDOWN) then
  begin
    iX_L := Message_P.LParam and $0000FFFF;
    iY_L := (Message_P.LParam shr 16);
    if not Visible then
    begin
      CheckAlignment(iX_L, iY_L);
      Visible := true;
      AlphaBlendValue := 0;
      BlendIndice_M := 25;
      TimerHideShow.Enabled := true;
      PostMessage(Handle, WM_EX_POSTUPDATE, 0, 0);
    end else begin
      BlendIndice_M := -25;
      TimerHideShow.Enabled := true;
    end;
  end;
end;

// cleans ui and then dynamically (re)creates controls : application icons,
// separators and so...
procedure TMainForm.DisplayAppli;
var
  i, iMainTop_L, iTop_L: integer;
  Image_L: TImage;
  Panel_L: TPanel;
  Control_L: TControl;
  IconHandle_L: HIcon;
  IconIndex_L: word;
  DragDrop_L: TJvDragDrop;
  PopupMenu_L: TPopupMenu;
  RemoveMenuItem_L: TMenuItem;
  Label_L: TLabel;
  Component_L: TComponent;

  procedure CleanUI;
  var
    i: integer;
  begin
    for i := 0 to ComponentToDestroy_M.Count - 1 do
    begin
      Component_L := ComponentToDestroy_M[i];
      if (Component_L is TJvDragDrop) then
      begin
        DragDrop_L := (Component_L as TJvDragDrop);
        panelExeFiles.RemoveComponent(DragDrop_L);
        DragDrop_L.Free;
      end else if (Component_L is TMenuItem) then
      begin
        RemoveMenuItem_L := (Component_L as TMenuItem);
        panelExeFiles.RemoveComponent(RemoveMenuItem_L);
        RemoveMenuItem_L.Free;
      end else if (Component_L is TPopupMenu) then
      begin
        PopupMenu_L := (Component_L as TPopupMenu);
        panelExeFiles.RemoveComponent(PopupMenu_L);
        PopupMenu_L.Free;
      end;
    end;
    ComponentToDestroy_M.Clear;

    for i := 0 to ControlToDestroy_M.Count - 1 do
    begin
      Control_L := ControlToDestroy_M[i];
      if (Control_L is TImage) then
      begin
        Image_L := (Control_L as TImage);
        if Image_L.Picture.Icon.Handle <> 0 then
          DestroyIcon(Image_L.Picture.Icon.Handle);
        panelExeFiles.RemoveControl(Image_L);
        Image_L.Free;
      end else if (Control_L is TPanel) then
      begin
        Panel_L := (Control_L as TPanel);
        panelExeFiles.RemoveControl(Panel_L);
        Panel_L.Free;
      end else if (Control_L is TLabel) then
      begin
        Label_L := (Control_L as TLabel);
        RemoveControl(Label_L);
        Label_L.Free;
      end;
    end;
    ControlToDestroy_M.Clear;
  end;

begin
  CleanUI;

  MainForm.AutoSize := false; // tweaks to adjust UI
  panelMain.Visible := true;

  Width := ICONWIDTH + 6;

  AppliList_M.RemoveDeadLinks; // remove oldies...

  iTop_L := 0;
  iMainTop_L := 0;

  panelMain.Top := iMainTop_L;

  Panel_L := TPanel.Create(panelExeFiles);
  ControlToDestroy_M.Add(Panel_L);
  Panel_L.Top := iTop_L;
  Panel_L.Width := ICONWIDTH;
  Panel_L.Height := PANELHEIGHT;
  Panel_L.Color := clAppWorkSpace;
  Panel_L.BevelOuter := bvNone;
  Panel_L.BevelInner := bvLowered;
  Panel_L.Tag := 0;
  Panel_L.OnDragOver := OnDragOver;
  Panel_L.OnDragDrop := OnDragDrop;
  panelExeFiles.InsertControl(Panel_L);
  Inc(iTop_L, Panel_L.Height + 1);

  DragDrop_L := TJvDragDrop.Create(panelExeFiles);
  ComponentToDestroy_M.Add(DragDrop_L);
  DragDrop_L.DropTarget := Panel_L;
  DragDrop_L.Tag := integer(Panel_L);
  DragDrop_L.AcceptDrag := true;
  DragDrop_L.OnDrop := DragDropDrop;

  if AppliList_M.Count > 0 then
  begin
    for i := 0 to AppliList_M.Count - 1 do
    begin
      RemoveMenuItem_L := TMenuItem.Create(panelExeFiles);
      ComponentToDestroy_M.Add(RemoveMenuItem_L);
      RemoveMenuItem_L.OnClick := OnRemoveMenuItemClick;
      RemoveMenuItem_L.Caption := _('&Remove');
      RemoveMenuItem_L.Tag := i;
      PopupMenu_L := TPopupMenu.Create(panelExeFiles);
      ComponentToDestroy_M.Add(PopupMenu_L);
      PopupMenu_L.Items.Add(RemoveMenuItem_L);

      Image_L := TImage.Create(panelExeFiles);
      ControlToDestroy_M.Add(Image_L);
      TopImage_M := Image_L;
      if FileExists(TApplication(AppliList_M[i]).Exename_M) or
        DirectoryExists(TApplication(AppliList_M[i]).Exename_M) then
      begin
        IconIndex_L := 0;
        IconHandle_L := ExtractIcon(Application.Handle, pchar(TApplication(AppliList_M[i]).Exename_M),
          IconIndex_L);

        if IconHandle_L = 0 then
        begin
          IconIndex_L := 0;
          IconHandle_L := ExtractAssociatedIcon(Application.Handle,
            pchar(TApplication(AppliList_M[i]).Exename_M), IconIndex_L);
        end;

        if IconHandle_L <> 0 then
          Image_L.Picture.Icon.Handle := IconHandle_L;
      end;
      Image_L.PopupMenu := PopupMenu_L;
      Image_L.Top := iTop_L;
      Image_L.Left := 0;
      Image_L.Width := ICONWIDTH;
      Image_L.Height := ICONHEIGHT;
      Image_L.ShowHint := true;
      Image_L.Hint := ChangeFileExt(ExtractFileName(TApplication(AppliList_M[i]).Exename_M), '');
      Image_L.Center := true;
      Image_L.Tag := i;
      Image_L.Cursor := crHandPoint;
      Image_L.OnClick := ImageClick;
      Image_L.OnMouseDown := OnMouseDown;
      Image_L.OnMouseMove := OnMouseMove;
      Image_L.OnMouseUp := OnMouseUp;
      panelExeFiles.InsertControl(Image_L);
      Inc(iTop_L, Image_L.Height + 1);

      Panel_L := TPanel.Create(panelExeFiles);
      ControlToDestroy_M.Add(Panel_L);
      Panel_L.Top := iTop_L;
      Panel_L.Left := 0;
      Panel_L.Width := 50;
      Panel_L.Height := 8;
      Panel_L.BevelOuter := bvNone;
      Panel_L.BevelInner := bvLowered;
      Panel_L.OnDragOver := OnDragOver;
      Panel_L.OnDragDrop := OnDragDrop;
      Panel_L.Color := clAppWorkSpace;
      Panel_L.Tag := i + 1;
      panelExeFiles.InsertControl(Panel_L);
      Inc(iTop_L, Panel_L.Height + 1);

      DragDrop_L := TJvDragDrop.Create(panelExeFiles);
      ComponentToDestroy_M.Add(DragDrop_L);
      DragDrop_L.DropTarget := Panel_L;
      DragDrop_L.Tag := integer(Panel_L);
      DragDrop_L.AcceptDrag := true;
      DragDrop_L.OnDrop := DragDropDrop;
    end;
  end;

  panelExeFiles.Height := iTop_L;
  panelMain.Height := iTop_L;
  Inc(iMainTop_L, panelMain.Height);

  Label_L := TLabel.Create(panelExeFiles);
  ControlToDestroy_M.Add(Label_L);
  Label_L.AutoSize := false;
  Label_L.Alignment := taCenter;
  Label_L.Cursor := crHandPoint;
  Label_L.Font.Color := clBlue;
  Label_L.Font.Style := [fsUnderline];
  Label_L.Font.Name := 'Arial';
  Label_L.Font.Size := 7;
  Label_L.Caption := _('Help');
  Label_L.Top := iMainTop_L;
  Label_L.Left := 1;
  Label_L.Width := ICONWIDTH;
  Label_L.Height := 12;
  Label_L.OnClick := OnHelpClick;
  InsertControl(Label_L);
  Inc(iMainTop_L, Label_L.Height + 1);
  Height := iMainTop_L + 22;
end;

// shifts application down
procedure TMainForm.FormMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
var
  i: integer;
begin
  Handled := true;

  panelExeFiles.DoubleBuffered := true;
  panelMain.DoubleBuffered := true;
  for i := 0 to (ICONHEIGHT div 4) do
  begin
    panelExeFiles.Top := panelExeFiles.Top + 4;
    Refresh;
  end;

  AppliList_M.ShiftDown;
  DisplayAppli;
  panelExeFiles.Top := 0;
end;

// shifts application up
procedure TMainForm.FormMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
var
  i: integer;
begin
  Handled := true;

  for i := 0 to (ICONHEIGHT div 4) do
  begin
    panelExeFiles.Top := panelExeFiles.Top - 4;
    Refresh;
  end;

  AppliList_M.ShiftUp;
  DisplayAppli;
  panelExeFiles.Top := 0;
end;

procedure TMainForm.CheckAlignment(iNewX_P, iNewY_P: integer);
begin
  if TopImage_M <> nil then
  begin
    Left := iNewX_P - (ICONWIDTH div 2) - 15;
    Top := iNewY_P - PANELHEIGHT - (ICONWIDTH div 2) - 25;
  end;
end;

// manage application launching
procedure TMainForm.ImageClick(Sender: TObject);
var
  Image_L: TImage;
begin
  if Sender is TImage then
  begin
    Image_L := Sender as TImage;
    ShellExecute(0, 'OPEN', PWideChar(TApplication(AppliList_M[Image_L.Tag]).Exename_M), nil, nil, SW_SHOW);
    AlphaBlendValue := 0; // hide this !
    Hide;
  end;
end;

// closes application when uninstallation wizard asks for it
//   Message_P: not used...
procedure TMainForm.OnUninstallMessage(var Message_P: TMessage);
begin
  Close;
end;

// deals with application adding
procedure TMainForm.DragDropDrop(Sender: TObject; Pos: TPoint; Value: TStrings);
var
  Panel_L: TPanel;
begin
  Panel_L := TPanel((Sender as TJvDragDrop).Tag);
  AppliList_M.Add(Panel_L.Tag, Value[0]);
  AppliList_M.SaveAppliList;
  DisplayAppli;
end;

// remove application
procedure TMainForm.OnRemoveMenuItemClick(Sender: TObject);
begin
  AppliList_M.Remove((Sender as TMenuItem).Tag);
  AppliList_M.SaveAppliList;
  DisplayAppli;
end;

procedure TMainForm.OnMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  OrgX_M := X;
  OrgY_M := Y;
  DragCandidate_M := true;
end;

procedure TMainForm.OnMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
begin
  if DragCandidate_M then
  begin
    if (Abs(X - OrgX_M) > 4) or (Abs(Y - OrgY_M) > 4) then
    begin
      DragCandidate_M := false;
      (Sender as TImage).OnClick := nil;
      (Sender as TImage).BeginDrag(true);
    end;
  end;
end;

procedure TMainForm.OnMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  DragCandidate_M := false;
  (Sender as TImage).OnClick := ImageClick;
end;

procedure TMainForm.OnDragOver(Sender, Source: TObject; X, Y: integer; State: TDragState; var Accept: Boolean);
begin
  Accept := true;
end;

procedure TMainForm.OnDragDrop(Sender, Source: TObject; X, Y: integer);
var
  iDest_L, iSrc_L: integer;
begin
  iSrc_L := (Source as TImage).Tag;
  iDest_L := (Sender as TPanel).Tag;

  if iSrc_L < iDest_L then
  begin
    AppliList_M.Add(iDest_L, TApplication(AppliList_M[iSrc_L]).Exename_M,
      TApplication(AppliList_M[iSrc_L]).Parameters_M, TApplication(AppliList_M[iSrc_L]).Directory_M);
    AppliList_M.Remove(iSrc_L);
  end else begin
    AppliList_M.Add(iDest_L, TApplication(AppliList_M[iSrc_L]).Exename_M,
      TApplication(AppliList_M[iSrc_L]).Parameters_M, TApplication(AppliList_M[iSrc_L]).Directory_M);
    AppliList_M.Remove(iSrc_L + 1);
  end;
  PostMessage(Handle, WM_EX_POSTUPDATE, 0, 0);
end;

// now we're sure that main form is fully initialized
procedure TMainForm.OnPostUpdate(var Message_P: TMessage);
begin
  DisplayAppli;
end;

procedure TMainForm.OnHelpClick(Sender: TObject);
begin
  AlphaBlendValue := 0; // hide this, we have to display help !
  Visible := false;
  SetCurrentDir(ExtractFilePath(ParamStr(0)));
  ShellExecute(self.WindowHandle, 'open', pchar('Enjoy.exe'), nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.JvCaptionButton1Click(Sender: TObject);
begin
  BlendIndice_M := -25;
  TimerHideShow.Enabled := true;
end;

procedure TMainForm.TimerHideShowTimer(Sender: TObject);
begin
  // animation for fun !
  if ((AlphaBlendValue + BlendIndice_M) > 0) and ((AlphaBlendValue + BlendIndice_M) < 255) then
  begin
    AlphaBlendValue := AlphaBlendValue + BlendIndice_M;
  end else begin
    if BlendIndice_M > 0 then
    begin
      AlphaBlendValue := 255;
      TimerHideShow.Enabled := false;
    end else begin
      AlphaBlendValue := 0;
      Visible := false;
      TimerHideShow.Enabled := false;
    end;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  CurStyle_L: integer;
begin
  // translation stuff
  TranslateComponent(self);

  Top := 100;
  Left := Screen.Width - 150;

  // no icon in taskbar please
  CurStyle_L := GetWindowLong(Application.Handle, GWL_EXSTYLE);
  CurStyle_L := (CurStyle_L or WS_EX_TOOLWINDOW) and (not WS_EX_APPWINDOW);
  SetWindowLong(Application.Handle, GWL_EXSTYLE, CurStyle_L);

  TopImage_M := nil; // the one that is mouse pointed by default

  ControlToDestroy_M := TList.Create;
  ComponentToDestroy_M := TList.Create;

  AppliList_M := TAppliList.Create;
  AppliList_M.ReadAppliList;

  HoodDLLHinst_M := LoadLibrary('SquidHook.dll');
  if HoodDLLHinst_M <> 0 then
  begin
    // get installhook proc
    InstallHook_G := GetProcAddress(HoodDLLHinst_M, 'InstallHook');
    if @InstallHook_G = nil then
      raise Exception.Create('Initialization failed : a file is corrupted')
    else
      InstallHook_G(Handle);

    // get uninstallhook proc
    UnInstallHook_G := GetProcAddress(HoodDLLHinst_M, 'UnInstallHook');
    if @InstallHook_G = nil then
      raise Exception.Create('Initialization failed : a file is corrupted');
  end else begin
    raise Exception.Create('Initialization failed : a file is missing or corrupted');
  end;

  panelExeFiles.Width := ICONWIDTH;
  panelMain.Width := ICONWIDTH;

  Width := ICONWIDTH + 6;

  DisplayAppli;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnInstallHook_G;
  FreeLibrary(HoodDLLHinst_M);
  AppliList_M.Destroy;
  ComponentToDestroy_M.Destroy;
  ControlToDestroy_M.Destroy;
end;

end.
