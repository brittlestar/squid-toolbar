program Squid;

uses
  Windows,
  Forms,
  Graphics,
  Main in 'Main.pas' {MainForm},
  AppliList in 'AppliList.pas',
  Lnk in 'Lnk.pas',
  DefaultBrowser in 'DefaultBrowser.pas',
  jvgnugettext;

{$R *.res}

var
  hMutex_M: cardinal;

begin
  // force language
  if ParamCount = 1 then
    UseLanguage(ParamStr(1));

  // gnugettext stuff
  textdomain('Squid');
  TP_GlobalIgnoreClass(TFont);

  hMutex_M := CreateMutex(nil, True, 'BrittlestarSQUID');
  if (hMutex_M <> 0) and (GetLastError = 0) then
  begin
    Application.Initialize;
    Application.Title := 'Squid';
  Application.CreateForm(TMainForm, MainForm);
    Application.Run;
    if hMutex_M <> 0 then
      CloseHandle(hMutex_M);
  end;
end.
