unit servNodeLauncher;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs;

type
  TsrvNodeLauncher = class(TService)
    procedure ServiceStart(Sender: TService; var Started: Boolean);
  private
    fDirectory : string;
    fCommand : string;
    fParameters : string;
    fProcHandle :longint;
    procedure launch;
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  srvNodeLauncher: TsrvNodeLauncher;

implementation
uses shellapi,inifiles;
{$R *.DFM}

function getParameter(section:string;const name,defaultValue:string):string;
var
  mSiteFileName : string;
begin
    mSiteFileName := changeFileExt(paramstr(0),'.ini');
    with TIniFile.Create(mSiteFileName) do
    try
      result := ReadString(section,name,defaultValue);
    finally
      free;
    end;
end; {of getParameter}

procedure ErrorMess(Mess,Title:string);
var
   Temp :array[0..255] of Char;
   temp2 :array[0..255] of Char;
begin
   StrPCopy(Temp,Mess);
   StrPCopy(Temp2,Title);
   srvNodeLauncher.LogMessage(Temp+^m^j+Temp2);
end;

function ExecuteFile(const FileName, Params, DefaultDir: string;
  ShowCmd: Integer): THandle;
var
  zFileName, zParams, zDir: array[0..200] of Char;
  parent :THandle;
begin
//  if Application.MainForm = nil then
    parent := 0;
//  else
//    parent := Application.MainForm.Handle;
  Result := ShellExecute(parent, nil,
    StrPCopy(zFileName, FileName), StrPCopy(zParams, Params),
    StrPCopy(zDir, DefaultDir), ShowCmd);
end;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  srvNodeLauncher.Controller(CtrlCode);
end;

function TsrvNodeLauncher.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TsrvNodeLauncher.launch;
var
  ErrText : string;
  zFileName, zParams, zDir: array[0..200] of Char;
begin
   fProcHandle := ShellExecute(0, nil,
    StrPCopy(zFileName, fCommand), StrPCopy(zParams, fparameters),
    StrPCopy(zDir, fdirectory), SW_HIDE);
    //ExecuteFile(fCommand,fparameters,fdirectory,SW_HIDE);
   if (fProcHandle>=0) and (fProcHandle<32) then
   begin
      case fProcHandle of
      0: ErrText := 'System was Out of Memory';
      2: ErrText := 'File not found';
      3: ErrText := 'Path not found';
      5: ErrText := 'Attempt to dynamically link to a task';
      6: ErrText := 'Library required separate data segments';
      8: ErrText := 'Insufficient memory to start application';
      10: ErrText := 'Windows version is incorrect';
      11: ErrText := 'Executable file was invalid';
      12: ErrText := 'Application was designed for different OS';
      13: ErrText := 'Application was designed for DOS4.0';
      14: ErrText := 'Type of Executable is unknown';
      15: ErrText := 'Attempted to load real-mode application';
      16: ErrText := 'Attempt to load second instance';
      19: ErrText := 'Attempt to load compressed executable';
      20: ErrText := 'DLL library file was invalid';
      21: ErrText := 'Application requires 32-bits';
      else
         ErrText := 'Failed to load with error'+inttostr(fProcHandle);
      end; {case }
      ErrorMess(ErrText+ ' : '+fCommand,' Failed to execute using '+fparameters+' in '+fDirectory);
   end;
end;  // of launch

procedure TsrvNodeLauncher.ServiceStart(Sender: TService; var Started: Boolean);
begin
  fDirectory := getparameter('startup','directory',extractfilePath(paramstr(0)));
  fCommand := getparameter('startup','command','METEOR.bat');
  fParameters := getparameter('startup','parameters','RUN');
  LogMessage('startup directory:'+fDirectory, EVENTLOG_INFORMATION_TYPE);
  LogMessage('startup parameters:'+fParameters, EVENTLOG_INFORMATION_TYPE);
  LogMessage('startup command:'+fCommand, EVENTLOG_INFORMATION_TYPE);
  launch;
end;

end.

