unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  IniPropStorage, ExtCtrls, Process, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    Bevel1: TBevel;
    CheckBox1: TCheckBox;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    SetBtn: TSpeedButton;
    ResetBtn: TSpeedButton;
    ChangeBtn: TSpeedButton;
    StaticText1: TStaticText;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SetBtnClick(Sender: TObject);
    procedure ResetBtnClick(Sender: TObject);
    procedure CheckAutoStart;
    procedure ChangeBtnClick(Sender: TObject);
    procedure GetDisplayAndStatistic;

  private

  public

  end;

resourcestring
  SAutoStart = 'Autostart: ';
  SAutoStartNone = 'Autostart: none';
  SScaleTheDisplay = 'Scale the display ';
  SNoPrimaryDisplay = 'Primary display not found!';
  SNoSecondMonitor = 'The second monitor was not found!';

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.GetDisplayAndStatistic;
var
  s: ansistring;
begin
  //Запуск скрипта обнаружения дисплеев
  RunCommand('/bin/bash', ['-c', '"' + ExtractFileDir(Application.ExeName) +
    '/start.sh' + '"'], s);

  //Primary-Дисплей существует?
  RunCommand('/bin/bash', ['-c', 'xrandr --listactivemonitors | grep "\*"'], s);
  if Trim(s) = '' then
  begin
    MessageDlg(SNoPrimaryDisplay, mtWarning, [mbOK], 0);
    Application.Terminate;
  end;

  //Вывод списка мониторов, если Монитор только 1 - выход
  RunCommand('/bin/bash', ['-c', 'xrandr --listactivemonitors'], s);
  if Pos('1:', Trim(s)) = 0 then
  begin
    MessageDlg(SNoSecondMonitor, mtWarning, [mbOK], 0);
    Application.Terminate;
  end;
  Label1.Caption := Trim(s);

  //Имя вывода TV
  RunCommand('/bin/bash', ['-c',
    'xrandr --listactivemonitors | grep -ivE "mon|\*" | cut -f6 -d" "'], s);
  MainForm.Caption := Application.Title + ' [' + Trim(s) + ']';
  CheckBox1.Caption := SScaleTheDisplay + Trim(s);

  //Установка размеров формы
  MainForm.Width := Label3.Left + Label3.Width + 50;
  MainForm.Height := Label3.Top + Label3.Height + StaticText1.Height + 10;
end;

//Проверка Автостарта
procedure TMainForm.CheckAutoStart;
begin
  //Автостарт присутствует?
  if FileExists(GetUserDir + '.config/autostart/tv-display.desktop') then
    Label2.Caption := SAutoStart + '~/.config/autostart/tv-display.desktop'
  else
    Label2.Caption := SAutoStartNone;
end;

procedure TMainForm.ChangeBtnClick(Sender: TObject);
var
  s: ansistring;
  dtv: string;
begin
  Application.ProcessMessages;

  //Получаем имя дисплея TV
  RunCommand('/bin/bash', ['-c', 'cat ~/.config/tvconnector/disp | tail -n1'], s);
  dtv := Trim(s);

  //Меняем местами
  RunCommand('/bin/bash', ['-c', 'xrandr --output ' + dtv + ' --primary'], s);

  GetDisplayAndStatistic;
end;

//Рабочая директория
procedure TMainForm.FormCreate(Sender: TObject);
begin
  if not DirectoryExists(GetUserDir + '.config') then MkDir(GetUserDir + '.config');
  if not DirectoryExists(GetUserDir + '.config/tvconnector') then
    MkDir(GetUserDir + '.config/tvconnector');

  //Папка автостарта
  if not DirectoryExists(GetUserDir + '.config/autostart') then
    MkDir(GetUserDir + '.config/autostart');

  //Файл настройки (позиция формы, чекбокс)
  IniPropStorage1.IniFileName := GetUserDir + '.config/tvconnector/tvconnector.conf';

  //Проверка Автостарта
  CheckAutoStart;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  s: ansistring;
begin
  //Удаляем прежний список режимов TV
  DeleteFile(GetUserDir + '.config/tvconnector/disp');
  DeleteFile(GetUserDir + '.config/tvconnector/list0');

  GetDisplayAndStatistic;
end;

procedure TMainForm.SetBtnClick(Sender: TObject);
var
  s: ansistring;
  L: TStringList;
  dtv, dprim, rprim, command: string;
begin
  try
    L := TStringList.Create;

    Application.ProcessMessages;

    //Узнаём имя Primary Display
    RunCommand('/bin/bash', ['-c',
      'cat ~/.config/tvconnector/disp | head -n1 | cut -f1 -d" "'], s);
    dprim := Trim(s);

    //Узнаём резолюцию Primary Display
    RunCommand('/bin/bash', ['-c',
      'cat ~/.config/tvconnector/list0 | grep "\*" | cut -f1 -d" "'], s);
    rprim := Trim(s);

    //Узнаём имя TV-дисплея
    RunCommand('/bin/bash', ['-c', 'cat ~/.config/tvconnector/disp | tail -n1'], s);
    dtv := Trim(s);

    //Создаём команду
    if CheckBox1.Checked then
      command := 'xrandr --output ' + dtv + ' --off --output ' +
        dprim + ' --off; xrandr --output ' + dprim + ' --primary --mode ' +
        rprim + ' --output ' + dtv + ' --auto --scale-from ' + rprim
    else
      command := 'xrandr --output ' + dprim + ' --off --output ' +
        dtv + ' --off; xrandr --output ' + dprim + ' --primary --mode ' +
        rprim + ' --output ' + dtv + ' --auto';

    //Устанавливаем настройки TV-дисплея
    RunCommand('/bin/bash', ['-c', command], s);

    //Создаём ярлык автозапуска для установки настроек TV при перезагрузке
    L.Add('[Desktop Entry]');
    L.Add('Name=TV-Display');
    L.Add('Exec=bash -c ' + '''' + command + '''');
    L.Add('Type=Application');
    L.Add('Categories=Utility');
    L.Add('Terminal=false');

    //Сохраняем ярлык автозапуска
    L.SaveToFile(GetUserDir + '.config/autostart/tv-display.desktop');

    //Проверка Автостарта
    CheckAutoStart;
  finally
    L.Free;
  end;
end;

//Сброс дополнительного дисплея
procedure TMainForm.ResetBtnClick(Sender: TObject);
var
  s: ansistring;
  dtv: string;
begin
  Application.ProcessMessages;

  CheckBox1.Checked := False;

  //Узнаём имя TV-дисплея
  RunCommand('/bin/bash', ['-c', 'cat ~/.config/tvconnector/disp | tail -n1'], s);
  dtv := Trim(s);

  RunCommand('/bin/bash', ['-c', 'xrandr --output ' + dtv +
    ' --off; xrandr --output ' + dtv + ' --auto'], s);

  //Удаляем ярлык автозапуска
  DeleteFile(GetUserDir + '.config/autostart/tv-display.desktop');

  //Проверка Автостарта
  CheckAutoStart;
end;

end.
