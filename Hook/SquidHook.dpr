library SquidHook;

uses
  Windows, Messages;

{$R *.res}

type
  TMouseHookStructEx = packed record
    Point: TPoint;
    Hwnd: hwnd;
    HitTestCode: UINT;
    ExtraInfo: DWORD;
    MouseData: DWORD;
  end;

  PMouseHookStructEx = ^TMouseHookStructEx;

  PSharedData = ^TSharedData;

  TSharedData = record
    hwnd: hwnd;
  end;

var
  hHook_G: HHook;
  pSharedData_G: PSharedData;
  MapHandle_G: THandle;

// callback called on mouse events
//   refer to SetWindowsHookEx Win32 API function for further informations
function MouseProc(nCode_P: Integer; wParam_P: wParam; lParam_P: lParam): LongInt; stdcall;
var
  pMouseHook_L: PMouseHookStructEx;
begin
  if nCode_P = HC_ACTION then
  begin
    pMouseHook_L := PMouseHookStructEx(lParam_P);
    PostMessage(pSharedData_G.hwnd, WM_USER + 1, wParam_P, (pMouseHook_L^.Point.x and $FFFF) or
      (pMouseHook_L^.Point.y shl 16));

    if (wParam_P = WM_MBUTTONUP) or (wParam_P = WM_MBUTTONDOWN) or (wParam_P = WM_NCMBUTTONUP) or
      (wParam_P = WM_NCMBUTTONDOWN) then
    begin
      SetForegroundWindow(pSharedData_G^.hwnd);
      Result := 1;
    end else begin
      Result := CallNextHookEx(hHook_G, nCode_P, wParam_P, lParam_P);
    end;
  end else begin
    Result := CallNextHookEx(hHook_G, nCode_P, wParam_P, lParam_P);
  end;
end;

// hook installation procedure
procedure InstallHook(hWnd_P: hwnd); stdcall;
begin
  pSharedData_G.hwnd := hWnd_P;
  hHook_G := SetWindowsHookEx(WH_MOUSE_LL, MouseProc, HInstance, 0);
end;

procedure UnInstallHook; stdcall;
begin
  UnhookWindowsHookEx(hHook_G);
end;

procedure DLLEntryPoint(Reason_P: Integer);
begin
  if Reason_P = DLL_PROCESS_DETACH then
  begin
    UnmapViewOfFile(pSharedData_G);
    CloseHandle(MapHandle_G);
  end;
end;

exports
  InstallHook name 'InstallHook',
  UnInstallHook name 'UnInstallHook';

begin
  MapHandle_G := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, SizeOf(TSharedData), 'MyMapName');
  pSharedData_G := MapViewOfFile(MapHandle_G, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  DLLProc := @DLLEntryPoint;

end.
