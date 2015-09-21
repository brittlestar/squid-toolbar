program enjoy;

uses
  Forms,
  Graphics,
  Main in 'main.pas' {MainForm},
  JvGnugettext;

{$R *.res}

begin
  // force language
  if ParamCount=1 then UseLanguage(ParamStr(1));

  textdomain('Enjoy');
  TP_GlobalIgnoreClass(TFont);

  Application.Initialize;
  Application.Title := 'Squid Help Wizard';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
