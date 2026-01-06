program XTetris;

uses
  crt, xVGA256, xKeybrd, xTimer, xFont;

const
  BOARD_WIDTH = 10;
  BOARD_HEIGHT = 20;
  BLOCK_SIZE = 8;
  BOARD_X = 120;
  BOARD_Y = 20;
  NEXT_X = 220;
  NEXT_Y = 20;
  LEVEL_LINES = 10;
  BASE_DROP_TIME = 1000;  { ms per drop at level 1 }

type
  TPoint = record
    dx, dy: integer;
  end;

  TShape = array[0..3] of array[0..3] of TPoint;  { 4 rotations, 4 blocks }

const
  SHAPES: array[0..6] of array[0..3] of array[0..3] of TPoint = (
    (  { I }
      ((dx:0;dy:0), (dx:1;dy:0), (dx:2;dy:0), (dx:3;dy:0)),
      ((dx:0;dy:0), (dx:0;dy:1), (dx:0;dy:2), (dx:0;dy:3)),
      ((dx:0;dy:0), (dx:1;dy:0), (dx:2;dy:0), (dx:3;dy:0)),
      ((dx:0;dy:0), (dx:0;dy:1), (dx:0;dy:2), (dx:0;dy:3))
    ),
    (  { O }
      ((dx:0;dy:0), (dx:0;dy:1), (dx:1;dy:0), (dx:1;dy:1)),
      ((dx:0;dy:0), (dx:0;dy:1), (dx:1;dy:0), (dx:1;dy:1)),
      ((dx:0;dy:0), (dx:0;dy:1), (dx:1;dy:0), (dx:1;dy:1)),
      ((dx:0;dy:0), (dx:0;dy:1), (dx:1;dy:0), (dx:1;dy:1))
    ),
    (  { T }
      ((dx:0;dy:0), (dx:1;dy:0), (dx:2;dy:0), (dx:1;dy:1)),
      ((dx:0;dy:0), (dx:0;dy:1), (dx:0;dy:2), (dx:1;dy:1)),
      ((dx:0;dy:1), (dx:1;dy:1), (dx:2;dy:1), (dx:1;dy:0)),
      ((dx:1;dy:0), (dx:1;dy:1), (dx:1;dy:2), (dx:0;dy:1))
    ),
    (  { S }
      ((dx:1;dy:0), (dx:2;dy:0), (dx:0;dy:1), (dx:1;dy:1)),
      ((dx:0;dy:0), (dx:0;dy:1), (dx:1;dy:1), (dx:1;dy:2)),
      ((dx:1;dy:0), (dx:2;dy:0), (dx:0;dy:1), (dx:1;dy:1)),
      ((dx:0;dy:0), (dx:0;dy:1), (dx:1;dy:1), (dx:1;dy:2))
    ),
    (  { Z }
      ((dx:0;dy:0), (dx:1;dy:0), (dx:1;dy:1), (dx:2;dy:1)),
      ((dx:1;dy:0), (dx:0;dy:1), (dx:1;dy:1), (dx:0;dy:2)),
      ((dx:0;dy:0), (dx:1;dy:0), (dx:1;dy:1), (dx:2;dy:1)),
      ((dx:1;dy:0), (dx:0;dy:1), (dx:1;dy:1), (dx:0;dy:2))
    ),
    (  { J }
      ((dx:0;dy:0), (dx:0;dy:1), (dx:1;dy:1), (dx:2;dy:1)),
      ((dx:0;dy:0), (dx:1;dy:0), (dx:0;dy:1), (dx:0;dy:2)),
      ((dx:0;dy:0), (dx:1;dy:0), (dx:2;dy:0), (dx:2;dy:1)),
      ((dx:1;dy:0), (dx:1;dy:1), (dx:0;dy:2), (dx:1;dy:2))
    ),
    (  { L }
      ((dx:2;dy:0), (dx:0;dy:1), (dx:1;dy:1), (dx:2;dy:1)),
      ((dx:0;dy:0), (dx:0;dy:1), (dx:0;dy:2), (dx:1;dy:2)),
      ((dx:0;dy:0), (dx:1;dy:0), (dx:2;dy:0), (dx:0;dy:1)),
      ((dx:0;dy:0), (dx:1;dy:0), (dx:1;dy:1), (dx:1;dy:2))
    )
  );

var
  buffer: pointer;
  board: array[0..BOARD_HEIGHT-1, 0..BOARD_WIDTH-1] of byte;
  current_type, next_type: integer;
  current_x, current_y: integer;
  current_rot: integer;
  score: longint;
  lines_cleared: integer;
  level: integer;
  last_drop_time: longint;
  drop_interval: longint;
  game_over: boolean;

function IntToStr(i: longint): string;
var
  s: string;
begin
  Str(i, s);
  IntToStr := s;
end;

procedure InitGame;
var
  i, j: integer;
begin
  xSetVGAMode;
  xCreateBuffer(buffer);
  xKeyboardInit;
  xInitTimer(1000);  { 1000 Hz for smooth timing }

  { Set colors }
  xSetColor(0, 0, 0, 0);    { Black background }
  xSetColor(1, 0, 63, 63);  { Cyan for I }
  xSetColor(2, 63, 63, 0);  { Yellow for O }
  xSetColor(3, 63, 0, 63);  { Magenta for T }
  xSetColor(4, 0, 63, 0);   { Green for S }
  xSetColor(5, 63, 0, 0);   { Red for Z }
  xSetColor(6, 0, 0, 63);   { Blue for J }
  xSetColor(7, 63, 32, 0);  { Orange for L }
  xSetColor(8, 32, 32, 32); { Gray for borders }

  { Initialize board }
  for i := 0 to BOARD_HEIGHT - 1 do
    for j := 0 to BOARD_WIDTH - 1 do
      board[i, j] := 0;

  randomize;
  current_type := random(7);
  next_type := random(7);
  current_x := BOARD_WIDTH div 2 - 2;
  current_y := -1;  { Start above }
  current_rot := 0;
  score := 0;
  lines_cleared := 0;
  level := 1;
  drop_interval := BASE_DROP_TIME;
  last_drop_time := xGetTime;
  game_over := false;
end;

function CheckCollision(t, rot, x, y: integer): boolean;
var
  i: integer;
  nx, ny: integer;
begin
  CheckCollision := false;
  for i := 0 to 3 do
  begin
    nx := x + SHAPES[t][rot][i].dx;
    ny := y + SHAPES[t][rot][i].dy;
    if (nx < 0) or (nx >= BOARD_WIDTH) or (ny >= BOARD_HEIGHT) or ((ny >= 0) and (board[ny][nx] <> 0)) then
    begin
      CheckCollision := true;
      exit;
    end;
  end;
end;

procedure PlacePiece;
var
  i: integer;
  nx, ny: integer;
begin
  for i := 0 to 3 do
  begin
    nx := current_x + SHAPES[current_type][current_rot][i].dx;
    ny := current_y + SHAPES[current_type][current_rot][i].dy;
    if ny < 0 then
    begin
      game_over := true;
      exit;
    end;
    if ny < BOARD_HEIGHT then
      board[ny][nx] := current_type + 1;  { Colors 1-7 }
  end;
end;

procedure ClearLines;
var
  i, j, k: integer;
  full: boolean;
  cleared: integer;
begin
  cleared := 0;
  i := BOARD_HEIGHT - 1;
  while i >= 0 do
  begin
    full := true;
    for j := 0 to BOARD_WIDTH - 1 do
      if board[i][j] = 0 then
      begin
        full := false;
        break;
      end;
    if full then
    begin
      inc(cleared);
      for k := i downto 1 do
        for j := 0 to BOARD_WIDTH - 1 do
          board[k][j] := board[k-1][j];
      for j := 0 to BOARD_WIDTH - 1 do
        board[0][j] := 0;
    end
    else
      dec(i);
  end;
  inc(lines_cleared, cleared);
  case cleared of
    1: inc(score, 40 * level);
    2: inc(score, 100 * level);
    3: inc(score, 300 * level);
    4: inc(score, 1200 * level);
  end;
  if lines_cleared div LEVEL_LINES + 1 > level then
  begin
    inc(level);
    drop_interval := BASE_DROP_TIME - (level - 1) * 100;
    if drop_interval < 100 then drop_interval := 100;
  end;
end;

procedure NewPiece;
begin
  current_type := next_type;
  next_type := random(7);
  current_x := BOARD_WIDTH div 2 - 2;
  current_y := -2;  { Adjust for shape }
  current_rot := 0;
  if CheckCollision(current_type, current_rot, current_x, current_y) then
    game_over := true;
end;

procedure DrawBoard;
var
  i, j, k: integer;
  str_score, str_level, str_lines: string;  { str_lives usunięte, bo nie jest używane }
begin
  xClearScreen(buffer, 0);

  { Draw board border }
  xDrawRect(buffer, BOARD_X - 2, BOARD_Y - 2, BOARD_WIDTH * BLOCK_SIZE + 4, BOARD_HEIGHT * BLOCK_SIZE + 4, 8, false);

  { Draw board }
  for i := 0 to BOARD_HEIGHT - 1 do
    for j := 0 to BOARD_WIDTH - 1 do
      if board[i][j] <> 0 then
        xDrawRect(buffer, BOARD_X + j * BLOCK_SIZE, BOARD_Y + i * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE, board[i][j], true);

  { Draw current piece }
  for i := 0 to 3 do
  begin
    j := current_x + SHAPES[current_type][current_rot][i].dx;
    k := current_y + SHAPES[current_type][current_rot][i].dy;
    if k >= 0 then
      xDrawRect(buffer, BOARD_X + j * BLOCK_SIZE, BOARD_Y + k * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE, current_type + 1, true);
  end;

  { Draw next piece }
  xText(buffer, NEXT_X, NEXT_Y - 10, 'Next:', 7);
  for i := 0 to 3 do
  begin
    j := SHAPES[next_type][0][i].dx;
    k := SHAPES[next_type][0][i].dy;
    xDrawRect(buffer, NEXT_X + j * BLOCK_SIZE, NEXT_Y + k * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE, next_type + 1, true);
  end;

  { Draw score, level, and lines }
  str(score, str_score);
  str(level, str_level);
  str(lines_cleared, str_lines);  { Poprawka: konwersja lines_cleared na string }
  xText(buffer, 10, 10, 'Score: ' + str_score, 7);
  xText(buffer, 10, 30, 'Level: ' + str_level, 7);
  xText(buffer, 10, 50, 'Lines: ' + str_lines, 7);

  xWaitForVertRetrace;
  xCopyBuffer(buffer, ptr(VGA_SEGMENT, 0));
end;

procedure HandleInput;
var
  new_rot: integer;
begin
  if key[KEY_LEFT] then
    if not CheckCollision(current_type, current_rot, current_x - 1, current_y) then
    begin
      dec(current_x);
      xWait(28);
    end;

  if key[KEY_RIGHT] then
    if not CheckCollision(current_type, current_rot, current_x + 1, current_y) then
    begin
      inc(current_x);
      xWait(28);
    end;

  if key[KEY_DOWN] then
    if not CheckCollision(current_type, current_rot, current_x, current_y + 1) then
    begin
      inc(current_y);
      xWait(25);
    end;

  if key[KEY_UP] then
  begin
    new_rot := (current_rot + 1) mod 4;
    if not CheckCollision(current_type, new_rot, current_x, current_y) then
      current_rot := new_rot;
    xWait(106);
  end;

  if key[KEY_SPACE] then
  begin
    while not CheckCollision(current_type, current_rot, current_x, current_y + 1) do
      inc(current_y);
    xWait(50);
    inc(score, level);  { Bonus for hard drop }
  end;
end;

procedure Update;
var
  current_time: longint;
begin
  current_time := xGetTime;
  if current_time - last_drop_time >= drop_interval then
  begin
    if not CheckCollision(current_type, current_rot, current_x, current_y + 1) then
      inc(current_y)
    else
    begin
      PlacePiece;
      ClearLines;
      NewPiece;
    end;
    last_drop_time := current_time;
  end;
end;

procedure EndGame;
var
  str_score: string;
begin
  str(score, str_score);
  xClearScreen(buffer, 0);
  xText(buffer, 120, 90, 'Game Over!', 1);
  xText(buffer, 120, 100, 'Score: ' + str_score, 7);
  xCopyBuffer(buffer, ptr(VGA_SEGMENT, 0));
  Delay(3000);
  xFreeBuffer(buffer);
  xDisableKeyboard;
  xRestoreTimer;
  xSetTxtMode;
end;

begin
  InitGame;
  while not game_over and not key[KEY_ESC] do
  begin
    HandleInput;
    Update;
    DrawBoard;
    xWait(16);  { ~60 FPS }
    xClearKeyboard;
  end;
  EndGame;
end.