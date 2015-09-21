unit lnk;

interface

function GetTarget(const LinkFileName_P: WideString): string;
function GetParameters(const LinkFileName_P: WideString): string;
function GetRunDir(const LinkFileName_P: WideString): string;

implementation

uses
  Windows, SysUtils, ShlObj, ActiveX, ComObj;

const
  SLR_NOSEARCH = $0010;
  SLR_NOTRACK = $0020;
  SLR_NOLINKINFO = $0040;
  SLR_INVOKE_MSI = $0080;
  SLR_NO_UI_WITH_MSG_PUMP = $0101;

function GetParameters(const LinkFileName_P: WideString): string;
var
  ShellLink_L: IShellLink;
  PersistFile_L: IPersistFile;
  AFile_L: array[0..MAX_PATH] of Char;
  Flags_L: DWORD;
  ItemIDList_L: PItemIDList;
begin
  Result := '';
  FillChar(AFile_L, SizeOf(AFile_L), #0);
  ShellLink_L := CreateComObject(CLSID_ShellLink) as IShellLink;
  PersistFile_L := ShellLink_L as IPersistFile;

  { Set low-order flags for IShellLink.Resolve().
    Basically, we're using MSI with everything disabled. }
  LongRec(Flags_L).Lo :=
    SLR_ANY_MATCH or
    SLR_INVOKE_MSI or //Call the Microsoft Windows Installer.
  SLR_NOLINKINFO or //Disable distributed link tracking.
  SLR_NO_UI or //Do not display a dialog box if the link cannot be resolved.
  SLR_NOUPDATE or //Do not update the link information.
  SLR_NOSEARCH or //Do not execute the search heuristics.
  SLR_NOTRACK or //Do not use distributed link tracking.
  SLR_NO_UI_WITH_MSG_PUMP; //Undocumented in SDK. Assume same as SLR_NO_UI but
  //intended for applications without a hWnd.

  LongRec(Flags_L).Hi := 100; //100 ms timeout for invalid shortcuts

  if Succeeded(PersistFile_L.Load(PWideChar(LinkFileName_P), STGM_READ)) then
  begin
    if Succeeded(ShellLink_L.Resolve(0, Flags_L)) then
    begin
      if Succeeded(ShellLink_L.GetIDList(ItemIDList_L)) then
      begin
        if SHGetPathFromIDList(ItemIDList_L, @AFile_L) then
          Result := AFile_L;
      end;
    end else begin
      if ShellLink_L.GetArguments(@AFile_L, MAX_PATH) = NOERROR then
        Result := AFile_L;
    end;
  end;
end;

function GetRunDir(const LinkFileName_P: WideString): string;
var
  ShellLink_L: IShellLink;
  PersistFile_L: IPersistFile;
  AFile_L: array[0..MAX_PATH] of Char;
  Flags_L: DWORD;
  ItemIDList_L: PItemIDList;
begin
  Result := '';
  FillChar(AFile_L, SizeOf(AFile_L), #0);
  ShellLink_L := CreateComObject(CLSID_ShellLink) as IShellLink;
  PersistFile_L := ShellLink_L as IPersistFile;

  { Set low-order flags for IShellLink.Resolve().
    Basically, we're using MSI with everything disabled. }
  LongRec(Flags_L).Lo :=
    SLR_ANY_MATCH or
    SLR_INVOKE_MSI or //Call the Microsoft Windows Installer.
  SLR_NOLINKINFO or //Disable distributed link tracking.
  SLR_NO_UI or //Do not display a dialog box if the link cannot be resolved.
  SLR_NOUPDATE or //Do not update the link information.
  SLR_NOSEARCH or //Do not execute the search heuristics.
  SLR_NOTRACK or //Do not use distributed link tracking.
  SLR_NO_UI_WITH_MSG_PUMP; //Undocumented in SDK. Assume same as SLR_NO_UI but
  //intended for applications without a hWnd.

  LongRec(Flags_L).Hi := 100; //100 ms timeout for invalid shortcuts

  if Succeeded(PersistFile_L.Load(PWideChar(LinkFileName_P), STGM_READ)) then
  begin
    if Succeeded(ShellLink_L.Resolve(0, Flags_L)) then
    begin
      if Succeeded(ShellLink_L.GetIDList(ItemIDList_L)) then
      begin
        if SHGetPathFromIDList(ItemIDList_L, @AFile_L) then
          Result := AFile_L;
      end;
    end else begin
      if ShellLink_L.GetWorkingDirectory(@AFile_L, MAX_PATH) = NOERROR then
      begin
        Result := AFile_L;
      end;
    end;
  end;
end;

function GetTarget(const LinkFileName_P: WideString): string;
var
  ShellLink_L: IShellLink;
  PersistFile_L: IPersistFile;
  AFile_L: array[0..MAX_PATH] of Char;
  FindData_L: TWin32FindData;
  Flags_L: DWORD;
  ItemIDList_L: PItemIDList;
begin
  Result := '';
  FillChar(AFile_L, SizeOf(AFile_L), #0);
  ShellLink_L := CreateComObject(CLSID_ShellLink) as IShellLink;
  PersistFile_L := ShellLink_L as IPersistFile;

  { Set low-order flags for IShellLink.Resolve().
    Basically, we're using MSI with everything disabled. }
  LongRec(Flags_L).Lo :=
    SLR_ANY_MATCH or
    SLR_INVOKE_MSI or //Call the Microsoft Windows Installer.
  SLR_NOLINKINFO or //Disable distributed link tracking.
  SLR_NO_UI or //Do not display a dialog box if the link cannot be resolved.
  SLR_NOUPDATE or //Do not update the link information.
  SLR_NOSEARCH or //Do not execute the search heuristics.
  SLR_NOTRACK or //Do not use distributed link tracking.
  SLR_NO_UI_WITH_MSG_PUMP; //Undocumented in SDK. Assume same as SLR_NO_UI but
  //intended for applications without a hWnd.

  LongRec(Flags_L).Hi := 100; // 100 ms timeout for invalid shortcuts

  if Succeeded(PersistFile_L.Load(PWideChar(LinkFileName_P), STGM_READ)) then
  begin
    if Succeeded(ShellLink_L.Resolve(0, Flags_L)) then
    begin
      if Succeeded(ShellLink_L.GetIDList(ItemIDList_L)) then
      begin
        if SHGetPathFromIDList(ItemIDList_L, @AFile_L) then
          Result := AFile_L;
      end;
    end else begin
      if ShellLink_L.GetPath(@AFile_L, MAX_PATH, FindData_L, 0) = NOERROR then
        Result := AFile_L;
    end;
  end;
end;

end.
