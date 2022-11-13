unit Unit2;

interface

uses System.Types;

type
  TArrayExt = array of array of Extended;

  TAction = record
    key: integer;
    value: Extended;
  end;

  TArrayActions = array of array of TArray<TAction>;

  TGridWorld = class
  private
    action_space: TArray<integer>;
    function GetHeight: integer;
    function GetWidth: integer;
    function GetReward_Map(X, Y: integer): Extended;
    function GetShape: TPoint;
  protected
    FReward: TArrayExt;
  public
    move, goal, wall, start, agent: TPoint;
    action_meaning: array [0 .. 3] of string;
    constructor Create;
    destructor Destroy; override;
    function actions: TArray<integer>;
    function states: TArray<TPoint>;
    function next_state(state: TPoint; action: integer): TPoint;
    function reward(state: TPoint; action: integer; next: TPoint): Extended;
    procedure reset;
    function step(action: integer; out next: TPoint;
      out reward: Extended): Boolean;
    procedure setup(out p: TArrayActions; out V: TArrayExt);
    property reward_map[X, Y: integer]: Extended read GetReward_Map; default;
    property width: integer read GetWidth;
    property height: integer read GetHeight;
    property shape: TPoint read GetShape;
  end;

procedure eval_onestep(p: TArrayActions; var V: TArrayExt; env: TGridWorld;
  const gamma: Extended = 0.9);

procedure policy_eval(p: TArrayActions; var V: TArrayExt; env: TGridWorld;
  gamma: Extended; const threshold: Extended = 0.001);

function argmax(d: TArray<TAction>): integer;

procedure greedy_policy(V: TArrayExt; env: TGridWorld; gamma: Extended;
  out new_p: TArrayActions);

procedure policy_iter(env: TGridWorld; gamma: Extended;
  const threshold: Extended; const isRender: Boolean; var p: TArrayActions;
  var V: TArrayExt);

procedure value_iter_onestep(var V: TArrayExt; env: TGridWorld;
  gamma: Extended);

procedure value_iter(var V: TArrayExt; env: TGridWorld; gamma: Extended;
  const threshold: Extended = 0.001; const isRender: Boolean = True);

implementation

uses Math, Unit1;

procedure eval_onestep(p: TArrayActions; var V: TArrayExt; env: TGridWorld;
  const gamma: Extended = 0.9);
var
  r, new_V: Extended;
  next_state: TPoint;
  action: integer;
begin
  for var state in env.states do
  begin
    if state = env.goal then
    begin
      V[state.X, state.Y] := 0;
      continue;
    end;
    new_V := 0;
    for var action_prob in p[state.X, state.Y] do
    begin
      action := action_prob.key;
      next_state := env.next_state(state, action);
      r := env.reward(state, action, next_state);
      new_V := new_V + action_prob.value *
        (r + gamma * V[next_state.X, next_state.Y]);
    end;
    V[state.X, state.Y] := new_V;
  end;
end;

procedure policy_eval(p: TArrayActions; var V: TArrayExt; env: TGridWorld;
  gamma: Extended; const threshold: Extended = 0.001);
var
  old_V: TArrayExt;
  delta, temp: Extended;
begin
  SetLength(old_V, env.width, env.height);
  while True do
  begin
    for var state in env.states do
      old_V[state.X, state.Y] := V[state.X, state.Y];
    eval_onestep(p, V, env, gamma);
    delta := 0;
    for var state in env.states do
    begin
      temp := Abs(V[state.X, state.Y] - old_V[state.X, state.Y]);
      if delta < temp then
        delta := temp;
    end;
    if delta < threshold then
      break;
  end;
  Finalize(old_V);
end;

function argmax(d: TArray<TAction>): integer;
var
  max_value: Extended;
begin
  max_value := Math.NegInfinity;
  result := 0;
  for var data in d do
    if max_value < data.value then
      max_value := data.value;
  for var data in d do
    if data.value = max_value then
      result := data.key;
end;

procedure greedy_policy(V: TArrayExt; env: TGridWorld; gamma: Extended;
  out new_p: TArrayActions);
var
  action_values, action_probs, sample: TArray<TAction>;
  act: TAction;
  next_state: TPoint;
  r, value: Extended;
  max_action: integer;
begin
  SetLength(new_p, env.width, env.height);
  for var state in env.states do
  begin
    action_values := [];
    for var action in env.actions do
    begin
      next_state := env.next_state(state, action);
      r := env.reward(state, action, next_state);
      value := r + gamma * V[next_state.X, next_state.Y];
      act.key := action;
      act.value := value;
      action_values := action_values + [act];
    end;
    max_action := argmax(action_values);
    act.value := 0.0;
    action_probs := [];
    for var i := 0 to High(env.actions) do
    begin
      act.key := i;
      action_probs := action_probs + [act];
    end;
    action_probs[max_action].value := 1.0;
    sample := [];
    for var action in action_probs do
      sample := sample + [action];
    new_p[state.X, state.Y] := sample;
  end;
end;

procedure policy_iter(env: TGridWorld; gamma: Extended;
  const threshold: Extended; const isRender: Boolean; var p: TArrayActions;
  var V: TArrayExt);
var
  new_p: TArrayActions;
begin
  repeat
    policy_eval(p, V, env, gamma, threshold);
    greedy_policy(V, env, gamma, new_p);
    Form1.FormPaint(nil);
    p := new_p;
  until isRender;
end;

function max(values: TArray<Extended>): Extended;
begin
  result := NegInfinity;
  for var value in values do
    if result < value then
      result := value;
end;

procedure value_iter_onestep(var V: TArrayExt; env: TGridWorld;
  gamma: Extended);
var
  action_values: TArray<Extended>;
  next_state: TPoint;
  r, value: Extended;
begin
  for var state in env.states do
  begin
    if state = env.goal then
    begin
      V[state.X, state.Y] := 0;
      continue;
    end;
    action_values := [];
    for var action in env.actions do
    begin
      next_state := env.next_state(state, action);
      r := env.reward(state, action, next_state);
      value := r + gamma * V[next_state.X, next_state.Y];
      action_values := action_values + [value];
    end;
    V[state.X, state.Y] := max(action_values);
  end;
end;

procedure value_iter(var V: TArrayExt; env: TGridWorld; gamma: Extended;
  const threshold: Extended = 0.001; const isRender: Boolean = True);
var
  old_V: TArrayExt;
  delta, temp: Extended;
begin
  SetLength(old_V, env.width, env.height);
  while True do
  begin
    if isRender then
      Form1.FormPaint(nil);
    for var state in env.states do
      old_V[state.X, state.Y] := V[state.X, state.Y];
    value_iter_onestep(V, env, gamma);
    delta := 0;
    for var state in env.states do
    begin
      temp := Abs(V[state.X, state.Y] - old_V[state.X, state.Y]);
      if delta < temp then
        delta := temp;
    end;
    if delta < threshold then
      break;
  end;
end;

{ TGridWorld }

function TGridWorld.actions: TArray<integer>;
begin
  result := action_space;
end;

constructor TGridWorld.Create;
begin
  SetLength(FReward, 4, 3);
  FReward := [[0, 0, 0, 1.0], [0, Nan, 0, -1], [0, 0, 0, 0]];
  goal := Point(3, 0);
  wall := Point(1, 1);
  start := Point(2, 0);
  agent := start;
  action_space := [0, 1, 2, 3];
  action_meaning[0] := 'UP';
  action_meaning[1] := 'DOWN';
  action_meaning[2] := 'LEFT';
  action_meaning[3] := 'RIGHT';
end;

destructor TGridWorld.Destroy;
begin
  Finalize(FReward);
  Finalize(action_space);
  inherited;
end;

function TGridWorld.GetHeight: integer;
begin
  result := Length(FReward);
end;

function TGridWorld.GetReward_Map(X, Y: integer): Extended;
begin
  result := FReward[Y, X];
end;

function TGridWorld.GetShape: TPoint;
begin
  result := Point(width, height);
end;

function TGridWorld.GetWidth: integer;
begin
  result := Length(FReward[0]);
end;

function TGridWorld.next_state(state: TPoint; action: integer): TPoint;
var
  action_move_map: TArray<TPoint>;
  move: TPoint;
begin
  action_move_map := [Point(0, -1), Point(0, 1), Point(-1, 0), Point(1, 0)];
  move := action_move_map[action];
  result := Point(state.X + move.X, state.Y + move.Y);
  if (result.X < 0) or (result.X >= width) or (result.Y < 0) or
    (result.Y >= height) then
    result := state
  else if result = wall then
    result := state;
end;

procedure TGridWorld.reset;
begin
  agent := start;
end;

function TGridWorld.reward(state: TPoint; action: integer; next: TPoint)
  : Extended;
var
  s: TPoint;
begin
  s := next_state(state, action);
  result := reward_map[s.X, s.Y];
end;

procedure TGridWorld.setup(out p: TArrayActions; out V: TArrayExt);
var
  a: TArray<TAction>;
begin
  SetLength(p, width, height);
  for var state in states do
  begin
    SetLength(a, Length(actions));
    for var i := 0 to High(a) do
    begin
      a[i].key := i;
      a[i].value := 0.25;
    end;
    p[state.X, state.Y] := a;
  end;
  SetLength(V, width, height);
  for var state in states do
    V[state.X, state.Y] := 0.0;
end;

function TGridWorld.states: TArray<TPoint>;
begin
  result := [];
  for var j := 0 to height - 1 do
    for var i := 0 to width - 1 do
      result := result + [Point(i, j)];
end;

function TGridWorld.step(action: integer; out next: TPoint;
  out reward: Extended): Boolean;
var
  s: TPoint;
begin
  s := agent;
  next := next_state(s, action);
  reward := Self.reward(s, action, next);
  result := next = goal;
  agent := next;
end;

end.
