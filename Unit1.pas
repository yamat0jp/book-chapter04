unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, Vcl.ToolWin, Vcl.ActnCtrls;

type
  TForm1 = class(TForm)
    ActionManager1: TActionManager;
    Action1: TAction;
    ActionToolBar1: TActionToolBar;
    Action2: TAction;
    reset: TAction;
    procedure Action1Execute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure Action2Execute(Sender: TObject);
    procedure resetExecute(Sender: TObject);
  private
    { Private êÈåæ }
  public
    { Public êÈåæ }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses Unit2, Math, System.UITypes;

var
  world: TGridWorld;
  p: TArrayActions;
  V: TArrayExt;

procedure TForm1.Action1Execute(Sender: TObject);
begin
  policy_iter(world, 0.9, 0.001, true, p, V);
end;

procedure TForm1.Action2Execute(Sender: TObject);
var
  gamma: Extended;
begin
  gamma := 0.9;
  value_iter(V, world, gamma);
  greedy_policy(V, world, gamma, p);
  FormPaint(nil);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  world := TGridWorld.Create;
  world.setup(p, V);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  world.Free;
  Finalize(p);
  Finalize(V);
end;

procedure TForm1.FormPaint(Sender: TObject);
var
  e: Extended;
begin
  for var i := 0 to world.width do
    for var j := 0 to world.height do
    begin
      Canvas.MoveTo(50 + i * 100, 50);
      Canvas.LineTo(50 + i * 100, 50 + j * 100);
      Canvas.MoveTo(50, 50 + j * 100);
      Canvas.LineTo(50 + i * 100, 50 + j * 100);
    end;
  for var i := 0 to world.width - 1 do
    for var j := 0 to world.height - 1 do
    begin
      e := world.reward_map[i, j];
      if isNan(e) then
      begin
        Canvas.Brush.color := clBlack;
        Canvas.FloodFill(60 + i * 100, 60 + j * 100, Canvas.Pen.color,
          fsBorder);
        Canvas.Brush.color := clBtnFace;
      end
      else if e = -1.0 then
        Canvas.TextOut(50 + i * 100, 50 + j * 100, 'R:-1.0')
      else if e = 1.0 then
        Canvas.TextOut(50 + world.goal.X * 100, 50 + world.goal.Y * 100,
          'R:1.0(GOAL)');
      Canvas.TextOut(50 + 20 + i * 100, 50 + 20 + j * 100,
        FloatToStrF(V[i, j], ffNumber, 18, 2));
      for var action in p[i, j] do
        if action.value = 1 then
          Canvas.TextOut(50 + 50 + i * 100, 50 + 50 + j * 100,
            world.action_meaning[action.key]);
    end;
end;

procedure TForm1.resetExecute(Sender: TObject);
begin
  Canvas.Brush.color := clBtnFace;
  Canvas.FillRect(ClientRect);
  Finalize(p);
  Finalize(V);
  world.setup(p, V);
end;

end.
