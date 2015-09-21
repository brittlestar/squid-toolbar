unit AppliList;

interface

uses
  Windows, SysUtils, IniFiles, Classes, ShlObj, ActiveX, lnk, Registry,
  DefaultBrowser;

function GetShellFoldername(FolderID_P: integer): string;

type
  TApplication = class
    ExeName_M: string;
    Parameters_M: string;
    Directory_M: string;
  end;

  TAppliList = class
  private
    IniFile_M: TIniFile;
    Appli_M: TList;
    function Get(Index: Integer): Pointer;
    procedure Put(Index: Integer; const Value: Pointer);
    function GetCount:integer;

  public
    procedure ReadAppliList;
    procedure SaveAppliList;
    procedure ShiftUp;
    procedure ShiftDown;
    procedure Add(iIndex_P: integer; ExeName_P: string; Parameters_P: string = ''; WorkingDirectory_P: string = '');
    procedure Remove(iIndex_P: integer);
    procedure RemoveDeadLinks;

    property Items[Index: Integer]: Pointer read Get write Put; default;
    property Count: integer read GetCount;

    constructor Create;
    destructor Destroy; reintroduce;
  end;

implementation

function GetShellFoldername(FolderID_P: integer): string;
var
  pItemIDList_L: PItemIDList;
  Buffer_L: array[0..MAX_PATH] of Char;
begin
  Result := '';
  if Succeeded(ShGetSpecialFolderLocation(GetActiveWindow, FolderID_P, pItemIDList_L)) then
  begin
    if ShGetPathfromIDList(pItemIDList_L, Buffer_L) then
      Result := Buffer_L;
    CoTaskMemFree(pItemIDList_L);
  end;
end;

///////////////////////////////////////////
// TAppliList
///////////////////////////////////////////

constructor TAppliList.Create;
var
  IniFileName_L: string;
begin
  IniFileName_L := ChangeFileExt(ParamStr(0), '.ini');
  IniFile_M := TIniFile.Create(IniFileName_L);
  Appli_M := TList.Create;
end;

destructor TAppliList.Destroy;
var
  i: integer;
begin
  for i := 0 to Appli_M.Count - 1 do
    TApplication(Appli_M[i]).Destroy;
  Appli_M.Free;
  IniFile_M.Free;
end;

function TAppliList.Get(Index: Integer): Pointer;
begin
  Result := Appli_M[Index];
end;

procedure TAppliList.Put(Index: Integer; const Value: Pointer);
begin
  Appli_M[Index] := Value;
end;

// updates application list by removing obsoletes ones (ie when exe doesn't
// exist anymore
procedure TAppliList.RemoveDeadLinks;
var i: integer;
  ItemsToRemove_L: TList;
begin
  ItemsToRemove_L := TList.Create;
  try
    for i := 0 to Appli_M.Count - 1 do
    begin
      if (not FileExists(TApplication(Appli_M[i]).ExeName_M)) and
        (not DirectoryExists(TApplication(Appli_M[i]).ExeName_M)) then
        ItemsToRemove_L.Add(Pointer(i));
    end;

    for i := 0 to ItemsToRemove_L.Count - 1 do
      Remove(Integer(ItemsToRemove_L[i]));
  finally
    ItemsToRemove_L.Free;
  end;
end;

// save application list to ini file
procedure TAppliList.SaveAppliList;
var
  i: integer;
  Value_L: string;
begin
  IniFile_M.EraseSection('app');
  for i := 0 to Appli_M.Count - 1 do
  begin
    Value_L := '"' + TApplication(Appli_M[i]).ExeName_M + '","' + TApplication(Appli_M[i]).Parameters_M + '","' + TApplication(Appli_M[i]).Directory_M + '"';
    IniFile_M.WriteString('app', '#' + IntToStr(i), Value_L);
  end;
  IniFile_M.UpdateFile;
end;

// reads application list from ini file (no file ? we create one with default application)
procedure TAppliList.ReadAppliList;
var
  i: integer;
  IniFileName_L, Value_L, PathToSystem_L: string;
  Appli_L: TApplication;
  ValueList_L, SectionExeFiles_L: TStringList;
begin
  SectionExeFiles_L := TStringList.Create;

  IniFileName_L := ParamStr(0);
  IniFileName_L := GetShellFoldername(CSIDL_APPDATA) + '\' + ExtractFileName(ChangeFileExt(ParamStr(0), '.ini'));

  IniFile_M := TIniFile.Create(IniFileName_L);
  if not FileExists(IniFileName_L) then // no ini file, let's create a new one !
  begin
    // define a default ini file content : with default brower, calc and notepad
    PathToSystem_L := GetShellFoldername($25); // system32 path
    IniFile_M.WriteString('app', '#0', GetDefaultBrowser.Path + '\' + GetDefaultBrowser.Name);
    IniFile_M.WriteString('app', '#1', '"' + PathToSystem_L + '\calc.exe"');
    IniFile_M.WriteString('app', '#2', '"' + PathToSystem_L + '\notepad.exe"');
    IniFile_M.UpdateFile;
  end;

  ValueList_L := TStringList.Create;
  try
    IniFile_M.ReadSection('app', SectionExeFiles_L);
    for i := 0 to SectionExeFiles_L.Count - 1 do
    begin
      Appli_L := TApplication.Create;
      Value_L := '"' + IniFile_M.ReadString('app', SectionExeFiles_L[i], '') + '"';
      ValueList_L.CommaText := Value_L;
      if ValueList_L.Count > 0 then Appli_L.ExeName_M := ValueList_L[0];
      if ValueList_L.Count > 1 then Appli_L.Parameters_M := ValueList_L[1];
      if ValueList_L.Count > 2 then Appli_L.Directory_M := ValueList_L[2];
      Appli_M.Add(Appli_L);
    end;
  finally
    ValueList_L.Destroy;
  end;
  SectionExeFiles_L.Destroy;
end;

// shift icons up (top one goes bottom)
procedure TAppliList.ShiftUp;
var
  i: integer;
  pTempItem_L: pointer;
begin
  if Appli_M.Count > 1 then
  begin
    pTempItem_L := Appli_M[0];
    for i := 0 to Appli_M.Count - 2 do
      Appli_M[i] := Appli_M[i + 1];
    Appli_M[Appli_M.Count - 1] := pTempItem_L;
  end;
end;

// shift icons up (bottom one goes top)
procedure TAppliList.ShiftDown;
var
  i: integer;
  pTempItem_L: pointer;
begin
  if Appli_M.Count > 1 then
  begin
    pTempItem_L := Appli_M[Appli_M.Count - 1];
    for i := Appli_M.Count - 2 downto 0 do
      Appli_M[i + 1] := Appli_M[i];
    Appli_M[0] := pTempItem_L;
  end;
end;

// adds a new application to application list
//  iIndex_P: where to add it
//  ExeName_P: full path and exe name
//  Parameters_P: parameters used at startup
//  Directory_P: working directory
procedure TAppliList.Add(iIndex_P: integer; ExeName_P: string; Parameters_P: string = ''; WorkingDirectory_P: string = '');
var
  Appli_L: TApplication;
begin
  Appli_L := TApplication.Create;
  try
    if UpperCase(ExtractFileExt(ExeName_P)) = '.LNK' then
    begin
      Appli_L.ExeName_M := GetTarget(ExeName_P);
      Appli_L.Parameters_M := GetParameters(ExeName_P);
      Appli_L.Directory_M := GetRunDir(ExeName_P);
    end else
    begin
      Appli_L.ExeName_M := ExeName_P;
    end;
    Appli_M.Insert(iIndex_P, Appli_L);
  except
    Appli_M.Destroy;
  end;
end;

// remove an application for list
//   iIndex_P: index application to remove
procedure TAppliList.Remove(iIndex_P: integer);
var
  Appli_L: TApplication;
begin
  Appli_L := Appli_M[iIndex_P];
  Appli_M.Delete(iIndex_P);
  Appli_L.Destroy;
end;

function TAppliList.GetCount:integer;
begin
  Result := Appli_M.Count;
end;

end.

