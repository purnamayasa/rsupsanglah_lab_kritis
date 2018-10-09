unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Iphttpbroker, IpHtml, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, StdCtrls, Menus, Buttons, HTTPSend, lclintf, ActnList,
  Process

{$IFDEF Windows}
  ,MMSystem
{$ENDIF}

;

type

  { TfrmMain }


  TfrmMain = class(TForm)
    ActionList1: TActionList;
    IpHtmlPanel1: TIpHtmlPanel;
    IpHttpDataProvider1: TIpHttpDataProvider;
    lblTitle: TLabel;
    lblClick: TLabel;
    lblTitle1: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    mnuKeluar: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    PopupMenu1: TPopupMenu;
    btnTutup: TSpeedButton;
    tmrSound: TTimer;
    tmrBlink: TTimer;
    tmrKritis1: TTimer;
    tmrKritis2: TTimer;
    TrayIcon: TTrayIcon;
    procedure btnTutupClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure lblClickClick(Sender: TObject);
    procedure mnuKeluarClick(Sender: TObject);
    procedure tmrBlinkTimer(Sender: TObject);
    procedure tmrKritis1Timer(Sender: TObject);
    procedure tmrKritis2Timer(Sender: TObject);
    procedure tmrSoundTimer(Sender: TObject);
    procedure TrayIconClick(Sender: TObject);
  private
    { private declarations }
    keluar: Boolean;
    xrefresh: Boolean;
    playsound: Boolean;
    onplaysound: Boolean;
  public
    { public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

function StreamToString(Stream : TStream) : String;
var ms : TMemoryStream;
begin
  Result := '';
  ms := TMemoryStream.Create;
  try
    ms.LoadFromStream(Stream);
    SetString(Result,PChar(ms.memory),ms.Size);
  finally
    ms.free;
  end;
end;

function PlaySoundLnx(fileName: String): Boolean;
const
  playerCmd = 'paplay';  // pulseaudio client
var
  AProcess: TProcess;
begin
  AProcess := TProcess.Create(nil);
  with Aprocess do begin
    CommandLine := FindDefaultExecutablePath(playerCmd) +
      ' ' + filename;
    //Options := Options + [poWaitOnExit];
    try
      try
        Execute;
      except
        on E: Exception do
          ShowMessage(E.ClassName +
            ' error raised, with message : ' + E.Message);
      end;
    finally
      Free;
    end;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  HTTP: THTTPSend;
  x: String;
begin
  // Judul
  HTTP := THTTPSend.Create;
  try
    HTTP.ProxyHost := '';
    HTTP.ProxyPort := '';
    HTTP.HTTPMethod('GET', 'http://10.20.2.4/cronjob/tools/critical.php?tipe=title');
    Memo1.Lines.Assign(HTTP.Headers);
    Memo2.Lines.LoadFromStream(HTTP.Document);

    x := Trim(StreamToString(HTTP.Document));

    lblTitle.Caption := x;

  finally
    HTTP.Free;
  end;

  // Informasi klik disini
  HTTP := THTTPSend.Create;
  try
    HTTP.ProxyHost := '';
    HTTP.ProxyPort := '';
    HTTP.HTTPMethod('GET', 'http://10.20.2.4/cronjob/tools/critical.php?tipe=click');
    Memo1.Lines.Assign(HTTP.Headers);
    Memo2.Lines.LoadFromStream(HTTP.Document);

    x := Trim(StreamToString(HTTP.Document));

    lblClick.Caption := x;

  finally
    HTTP.Free;
  end;

  playsound:=false;
  onplaysound:=false;
  xrefresh := false;
  keluar := false;
  TrayIcon.Icon.LoadFromFile('lab_kritis.ico');
  TrayIcon.Show;
  tmrKritis1.Enabled := true;
end;

procedure TfrmMain.FormWindowStateChange(Sender: TObject);
begin
  if WindowState = wsMinimized then
  begin
      Hide;
      TrayIcon.ShowBalloonHint;
  end;
end;

procedure TfrmMain.lblClickClick(Sender: TObject);
var
  HTTP: THTTPSend;
  x: String;
begin
  HTTP := THTTPSend.Create;
  try
    HTTP.ProxyHost := '';
    HTTP.ProxyPort := '';
    HTTP.HTTPMethod('GET', 'http://10.20.2.4/cronjob/tools/critical.php?tipe=url');

    x := StreamToString(HTTP.Document);

    OpenURL(x);
    btnTutupClick(Sender);

  finally
    HTTP.Free;
  end;

end;

procedure TfrmMain.mnuKeluarClick(Sender: TObject);
begin
  keluar := true;
  Close;
end;

procedure TfrmMain.tmrBlinkTimer(Sender: TObject);
begin
  if lblClick.Font.Color = clBlue then
     lblClick.Font.Color := clRed
  else
     lblClick.Font.Color := clBlue;
end;

procedure TfrmMain.btnTutupClick(Sender: TObject);
var
  HTTP: THTTPSend;
  x: String;
begin
  HTTP := THTTPSend.Create;
  try
    HTTP.ProxyHost := '';
    HTTP.ProxyPort := '';
    HTTP.HTTPMethod('GET', 'http://10.20.2.4/cronjob/tools/critical.php?tipe=interval');
    Memo1.Lines.Assign(HTTP.Headers);
    Memo2.Lines.LoadFromStream(HTTP.Document);

    x := Trim(StreamToString(HTTP.Document));

    tmrKritis2.Interval := StrToInt(x);

  finally
    HTTP.Free;
  end;

  Hide;
  tmrKritis1.Enabled := false;
  tmrKritis2.Enabled := true;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if keluar = false then
    begin
      Hide;
      CanClose := false;
      TrayIcon.ShowBalloonHint;
    end;
end;

procedure TfrmMain.tmrKritis1Timer(Sender: TObject);
var
  HTTP: THTTPSend;
  x: String;
begin
  HTTP := THTTPSend.Create;
  try
    HTTP.ProxyHost := '';
    HTTP.ProxyPort := '';
    HTTP.HTTPMethod('GET', 'http://10.20.2.4/cronjob/tools/critical.php?tipe=alert');
    Memo1.Lines.Assign(HTTP.Headers);
    Memo2.Lines.LoadFromStream(HTTP.Document);

    x := Trim(StreamToString(HTTP.Document));

    If x = 'critical' then
    begin
      if xrefresh = false then
      begin
         tmrKritis1.Interval := 5000;
         IpHtmlPanel1.OpenURL('http://10.20.2.4/cronjob/tools/critical.php?tipe=data');
      end;
      //xrefresh := true;
      playsound:=true;
      onplaysound:= false ;
      Show;
    end
    else
    begin
      playsound:=false;
      onplaysound:= false ;
    end;

  finally
    HTTP.Free;
  end;
end;

procedure TfrmMain.tmrKritis2Timer(Sender: TObject);
var
  HTTP: THTTPSend;
  x: String;
begin
  HTTP := THTTPSend.Create;
  try
    HTTP.ProxyHost := '';
    HTTP.ProxyPort := '';
    HTTP.HTTPMethod('GET', 'http://10.20.2.4/cronjob/tools/critical.php?tipe=alert');
    Memo1.Lines.Assign(HTTP.Headers);
    Memo2.Lines.LoadFromStream(HTTP.Document);

    x := Trim(StreamToString(HTTP.Document));

    If x = 'critical' then
    begin
      playsound:=true;
      onplaysound:= false ;
      TrayIconClick(Sender);
    end
    else
    begin
      playsound:=false;
      onplaysound:= false ;
    end;

  finally
    HTTP.Free;
  end;
end;

procedure TfrmMain.tmrSoundTimer(Sender: TObject);
begin
  if playsound = true and onplaysound = false then
  begin
     onplaysound:=true;
     {$IFDEF Windows}
     sndPlaySound(pchar(UTF8ToSys('lab_kritis.wav')), SND_NOSTOP);
     {$ENDIF}
     {$IFDEF UNIX}
     PlaySoundLnx('lab_kritis.wav');
     {$ENDIF}
     onplaysound:=false;
  end;
end;

procedure TfrmMain.TrayIconClick(Sender: TObject);
begin
  IpHtmlPanel1.OpenURL('http://10.20.2.4/cronjob/tools/critical.php?tipe=data');
  xrefresh            := false;
  tmrKritis1.Interval := 1000;
  tmrKritis1.Enabled  := true;
  tmrKritis2.Enabled  := false;
  WindowState         := wsMaximized;
  Show;
end;

end.

