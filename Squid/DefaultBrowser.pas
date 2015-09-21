{******************************************************************************}
{                                                                              }
{ DefaultBrowser                                                               }
{                                                                              }
{ The contents of this file are subject to the Mozilla Public License Version  }
{ 1.0 (the "License"); you may not use this file except in compliance with the }
{ License. You may obtain a copy of the License at http://www.mozilla.org/MPL/ }
{                                                                              }
{ Software distributed under the License is distributed on an "AS IS" basis,   }
{ WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for }
{ the specific language governing rights and limitations under the License.    }
{                                                                              }
{ The Original Code is DefaultBrowser.pas.                                     }
{                                                                              }
{ The Initial Developer of the Original Code is Matthias Thoma                 }
{ All Rights Reserved.                                                         }
{                                                                              }
{ Contributor(s): LongPathName derived from code by Rudolph Velthuis           }
{                                                                              }
{                                                                              }
{ Contact:  Matthias Thoma (ma.thoma@gmx.de)                                   }
{                                                                              }
{ Bugfix: FileClose was missing.                                               }
{                                                                              }
{******************************************************************************}

unit DefaultBrowser;

interface

uses SysUtils;

type
  TBrowserInformation = record
    Name: string;
    Path: string;
    Version: string;
  end;

function LongPathName(ShortPathName_P: string): string;
function GetDefaultBrowser: TBrowserInformation;

type
  EGetDefaultBrowser = class(Exception);

implementation

uses Windows, ShellApi, ShlObj, ActiveX, Dialogs;

// returns default browser information
function GetDefaultBrowser: TBrowserInformation;
var
  Tmp_L, Res_L: PChar;
  Version_L, VersionInformation_L: Pointer;
  Handle_L, VersionInformationSize_L: Integer;
  Dummy_L: Cardinal;
begin
  Tmp_L := StrAlloc(255);
  Res_L := StrAlloc(255);

  Version_L := nil;
  try
    // let's try to create a .htm file to identify associated application
    GetTempPath(255, Tmp_L);
    Handle_L := FileCreate(Tmp_L + 'htmpl.htm');
    if Handle_L <> -1 then
    begin
      if FindExecutable('htmpl.htm', Tmp_L, Res_L) > 32 then
      begin
        Result.Name := ExtractFileName(Res_L);
        Result.Path := LongPathName(ExtractFilePath(Res_L));

        // try to determine the browser version
        VersionInformationSize_L := GetFileVersionInfoSize(Res_L, Dummy_L);

        if VersionInformationSize_L > 0 then
        begin
          GetMem(VersionInformation_L, VersionInformationSize_L);
          GetFileVersionInfo(Res_L, 0, VersionInformationSize_L, VersionInformation_L);

          VerQueryValue(VersionInformation_L, ('\\StringFileInfo\\040904E4\\ProductVersion'),
            Pointer(Version_L), Dummy_L);

          if Version_L <> nil then
            Result.Version := PChar(Version_L);

          FreeMem(VersionInformation_L);
        end;
      end else begin
        raise EGetDefaultBrowser.Create('Can''t determine the executable.');
      end;

      FileClose(Handle_L);
      SysUtils.DeleteFile(Tmp_L + 'htmpl.htm');
    end else begin
      raise EGetDefaultBrowser.Create('Can''t create temporary file.');
    end;
  finally
    StrDispose(Tmp_L);
    StrDispose(Res_L);
  end;
end;

function LongPathName(ShortPathName_P: string): string;
var
  ItemIDList_L: PItemIDList;
  Desktop_L: IShellFolder;
  AnsiPathName_L, WidePathName_L: string;
begin
  Result := ShortPathName_P;
  if Succeeded(SHGetDesktopFolder(Desktop_L)) then
  begin
    WidePathName_L := ShortPathName_P;
    if Succeeded(Desktop_L.ParseDisplayName(0, nil, PWideChar(WidePathName_L),
      ULONG(nil^), ItemIDList_L, ULONG(nil^))) then

    try
      SetLength(AnsiPathName_L, MAX_PATH);
      SHGetPathFromIDList(ItemIDList_L, PWideChar(AnsiPathName_L));
      Result := PWideChar(AnsiPathName_L);
    finally
      CoTaskMemFree(ItemIDList_L);
    end;
  end;
end;

end.
