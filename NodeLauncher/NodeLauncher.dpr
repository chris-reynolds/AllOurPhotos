program NodeLauncher;

uses
  SvcMgr,
  servNodeLauncher in 'servNodeLauncher.pas' {srvNodeLauncher: TService};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TsrvNodeLauncher, srvNodeLauncher);
  Application.Run;
end.
