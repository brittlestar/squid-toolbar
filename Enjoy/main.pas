unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, jpeg, ExtCtrls, StdCtrls, JvWizard, JvExControls, JvComponent,
  jvgnugettext;

type
  TMainForm = class(TForm)
    JvWizard1: TJvWizard;
    JvWizardInteriorPage1: TJvWizardInteriorPage;
    Panel2: TPanel;
    Label2: TLabel;
    Panel3: TPanel;
    Image1: TImage;
    Panel4: TPanel;
    Image2: TImage;
    JvWizardInteriorPage2: TJvWizardInteriorPage;
    Label1: TLabel;
    Panel1: TPanel;
    Label3: TLabel;
    Panel6: TPanel;
    Image4: TImage;
    JvWizardInteriorPage3: TJvWizardInteriorPage;
    Panel5: TPanel;
    Label6: TLabel;
    Label7: TLabel;
    Panel7: TPanel;
    Image3: TImage;
    JvWizardInteriorPage4: TJvWizardInteriorPage;
    Panel8: TPanel;
    Label12: TLabel;
    Panel9: TPanel;
    Image5: TImage;
    Label13: TLabel;
    Panel10: TPanel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Panel11: TPanel;
    Label8: TLabel;
    Label9: TLabel;
    Label4: TLabel;
    procedure JvWizardInteriorPage4FinishButtonClick(Sender: TObject;
      var Stop: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure JvWizard1CancelButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.JvWizardInteriorPage4FinishButtonClick(Sender: TObject;
  var Stop: Boolean);
begin
  Close;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // translation stuff
  TranslateComponent(self);
end;

procedure TMainForm.JvWizard1CancelButtonClick(Sender: TObject);
begin
  Close;
end;

end.
