program XChess;

uses crt, xVGA256, xTimer, xMouse, xFont;

const
  BOARD_SIZE = 8;
  SQUARE_SIZE = 23;       { Size of the board square in pixels }
  BOARD_X = 70;           { Starting position of the board X }
  BOARD_Y = 0;            { Starting position of the board Y }
  WHITE = 255;            { White color }
  BLACK = 0;              { Black color }
  LIGHT_SQUARE = 200;     { Light square }
  DARK_SQUARE = 100;      { Dark square }
  SELECT_COLOR = 15;      { Selection color }
  INF = 10000;
  MAX_MOVES = 200;
  MAX_DISPLAY_LINES = 18; { Maximum number of moves displayed on the screen before clearing the list }

type
  TPiece = (Empty, WPawn, WKnight, WBishop, WRook, WQueen, WKing,
            BPawn, BKnight, BBishop, BRook, BQueen, BKing);

  TBoard = array[0..7, 0..7] of TPiece;

  TMove = record
    FromX, FromY: Integer;
    ToX, ToY: Integer;
  end;

var
  Board: TBoard;
  Images: array[TPiece] of TImage;
  Buffer: Pointer;
  CurrentPlayer: Boolean;  { True: White, False: Black }
  SelectedX, SelectedY: Integer;
  InCheck: Boolean;
  GameOver: Boolean;
  Winner: String;
  EnPassantFile: Integer;
  WhiteKingMoved, BlackKingMoved: Boolean;
  WhiteQRookMoved, WhiteKRookMoved: Boolean;
  BlackQRookMoved, BlackKRookMoved: Boolean;
  Moves: array[0..MAX_MOVES-1] of String;
  MoveCount: Integer;

function Sign(Value: Integer): Integer;
begin
  if Value > 0 then Sign := 1
  else if Value < 0 then Sign := -1
  else Sign := 0;
end;

function Max(A, B: Integer): Integer;
begin
  if A > B then Max := A else Max := B;
end;

function Min(A, B: Integer): Integer;
begin
  if A < B then Min := A else Min := B;
end;

procedure LoadPieceImages;
begin
  { Assume that BMP files exist in the directory, e.g. white_pawn.bmp sized 24x24 }
  xLoadBitmap(Images[WPawn], 'data\wpawn.bmp');
  xLoadBitmap(Images[WKnight], 'data\wknight.bmp');
  xLoadBitmap(Images[WBishop], 'data\wbishop.bmp');
  xLoadBitmap(Images[WRook], 'data\wrook.bmp');
  xLoadBitmap(Images[WQueen], 'data\wqueen.bmp');
  xLoadBitmap(Images[WKing], 'data\wking.bmp');
  xLoadBitmap(Images[BPawn], 'data\bpawn.bmp');
  xLoadBitmap(Images[BKnight], 'data\bknight.bmp');
  xLoadBitmap(Images[BBishop], 'data\bbishop.bmp');
  xLoadBitmap(Images[BRook], 'data\brook.bmp');
  xLoadBitmap(Images[BQueen], 'data\bqueen.bmp');
  xLoadBitmap(Images[BKing], 'data\bking.bmp');
end;

procedure FreePieceImages;
var
  P: TPiece;
begin
  for P := WPawn to BKing do
    xFreeImage(Images[P]);
end;

procedure InitBoard;
var
  x, y: Integer;
begin
  for y := 0 to 7 do
    for x := 0 to 7 do
      Board[x, y] := Empty;

  { White pieces }
  for x := 0 to 7 do Board[x, 6] := WPawn;
  Board[0, 7] := WRook; Board[1, 7] := WKnight; Board[2, 7] := WBishop;
  Board[3, 7] := WQueen; Board[4, 7] := WKing;
  Board[5, 7] := WBishop; Board[6, 7] := WKnight; Board[7, 7] := WRook;

  { Black pieces }
  for x := 0 to 7 do Board[x, 1] := BPawn;
  Board[0, 0] := BRook; Board[1, 0] := BKnight; Board[2, 0] := BBishop;
  Board[3, 0] := BQueen; Board[4, 0] := BKing;
  Board[5, 0] := BBishop; Board[6, 0] := BKnight; Board[7, 0] := BRook;
end;

function IsWhitePiece(P: TPiece): Boolean;
begin
  IsWhitePiece := (P >= WPawn) and (P <= WKing);
end;

function IsBlackPiece(P: TPiece): Boolean;
begin
  IsBlackPiece := (P >= BPawn) and (P <= BKing);
end;

function IsOpponentPiece(Current: Boolean; P: TPiece): Boolean;
begin
  if Current then
    IsOpponentPiece := IsBlackPiece(P)
  else
    IsOpponentPiece := IsWhitePiece(P);
end;

function IsOwnPiece(Current: Boolean; P: TPiece): Boolean;
begin
  if Current then
    IsOwnPiece := IsWhitePiece(P)
  else
    IsOwnPiece := IsBlackPiece(P);
end;

function IsInCheck(Current: Boolean): Boolean; forward;

function GetPieceValue(P: TPiece): Integer;
begin
  case P of
    WPawn, BPawn: GetPieceValue := 1;
    WKnight, BKnight, WBishop, BBishop: GetPieceValue := 3;
    WRook, BRook: GetPieceValue := 5;
    WQueen, BQueen: GetPieceValue := 9;
    else GetPieceValue := 0;
  end;
end;

function EvaluateBoard: Integer;
var
  x, y: Integer;
  score: Integer;
begin
  score := 0;
  for y := 0 to 7 do
    for x := 0 to 7 do
    begin
      if IsBlackPiece(Board[x, y]) then
        score := score + GetPieceValue(Board[x, y])
      else if IsWhitePiece(Board[x, y]) then
        score := score - GetPieceValue(Board[x, y]);
    end;
  EvaluateBoard := score;
end;

function ValidMove(FromX, FromY, ToX, ToY: Integer; Current: Boolean): Boolean;
var
  P: TPiece;
  dx, dy, i, forward: Integer;
  KingMoved, RookMoved: Boolean;
  RookP: TPiece;
  RookX, PassX: Integer;
  TempP: TPiece;
begin
  ValidMove := False;
  if (ToX < 0) or (ToX > 7) or (ToY < 0) or (ToY > 7) then Exit;
  P := Board[FromX, FromY];
  if IsOwnPiece(Current, Board[ToX, ToY]) then Exit;

  dx := ToX - FromX;
  dy := ToY - FromY;

  case P of
    WPawn, BPawn:
      begin
        if Current then forward := -1 else forward := 1;
        if (dy = forward) and (dx = 0) and (Board[ToX, ToY] = Empty) then ValidMove := True
        else if (dy = 2*forward) and (dx = 0) and ((Current and (FromY = 6)) or
                (not Current and (FromY = 1))) and (Board[ToX, ToY] = Empty)
                and (Board[FromX, FromY + forward] = Empty) then ValidMove := True
        else if (dy = forward) and (Abs(dx) = 1) and IsOpponentPiece(Current, Board[ToX, ToY]) then ValidMove := True
        else if (dy = forward) and (Abs(dx) = 1) and (Board[ToX, ToY] = Empty) and (EnPassantFile = ToX)
                and ((Current and (FromY = 3)) or (not Current and (FromY = 4)))
                and IsOpponentPiece(Current, Board[ToX, FromY]) then ValidMove := True;
      end;

    WKnight, BKnight:
      begin
        dx := Abs(ToX - FromX);
        dy := Abs(ToY - FromY);
        if ((dx = 1) and (dy = 2)) or ((dx = 2) and (dy = 1)) then ValidMove := True;
      end;

    WBishop, BBishop:
      begin
        dx := Abs(ToX - FromX);
        dy := Abs(ToY - FromY);
        if dx <> dy then Exit;
        dx := Sign(ToX - FromX);
        dy := Sign(ToY - FromY);
        for i := 1 to Abs(ToX - FromX) - 1 do
          if Board[FromX + i*dx, FromY + i*dy] <> Empty then Exit;
        ValidMove := True;
      end;

    WRook, BRook:
      begin
        if (ToX <> FromX) and (ToY <> FromY) then Exit;
        if ToX = FromX then
        begin
          dy := Sign(ToY - FromY);
          for i := 1 to Abs(ToY - FromY) - 1 do
            if Board[FromX, FromY + i*dy] <> Empty then Exit;
        end
        else
        begin
          dx := Sign(ToX - FromX);
          for i := 1 to Abs(ToX - FromX) - 1 do
            if Board[FromX + i*dx, FromY] <> Empty then Exit;
        end;
        ValidMove := True;
      end;

    WQueen, BQueen:
      begin
        { Combination of rook and bishop }
        dx := Abs(ToX - FromX);
        dy := Abs(ToY - FromY);
        if (dx <> 0) and (dy <> 0) and (dx <> dy) then Exit;
        if dx = 0 then dx := 0 else dx := Sign(ToX - FromX);
        if dy = 0 then dy := 0 else dy := Sign(ToY - FromY);
        for i := 1 to Max(Abs(ToX - FromX), Abs(ToY - FromY)) - 1 do
          if Board[FromX + i*dx, FromY + i*dy] <> Empty then Exit;
        ValidMove := True;
      end;

    WKing, BKing:
      begin
        dx := Abs(ToX - FromX);
        dy := Abs(ToY - FromY);
        if (dx <= 1) and (dy <= 1) then ValidMove := True
        else if (dy = 0) and (dx = 2) then
        begin
          if Current then
            KingMoved := WhiteKingMoved
          else
            KingMoved := BlackKingMoved;
          if KingMoved or IsInCheck(Current) then Exit;
          dx := ToX - FromX;  { Restore signed dx }
          if dx > 0 then  { Kingside }
          begin
            RookX := 7;
            PassX := 5;
            if Current then
              RookMoved := WhiteKRookMoved
            else
              RookMoved := BlackKRookMoved;
            if (Board[5, FromY] <> Empty) or (Board[6, FromY] <> Empty) then Exit;
          end
          else if dx < 0 then  { Queenside }
          begin
            RookX := 0;
            PassX := 3;
            if Current then
              RookMoved := WhiteQRookMoved
            else
              RookMoved := BlackQRookMoved;
            if (Board[1, FromY] <> Empty) or (Board[2, FromY] <> Empty) or (Board[3, FromY] <> Empty) then Exit;
          end
          else Exit;
          if Current then
            RookP := WRook
          else
            RookP := BRook;
          if RookMoved or (Board[RookX, FromY] <> RookP) then Exit;
          { Check if pass square is in check }
          TempP := Board[FromX, FromY];
          Board[FromX, FromY] := Empty;
          Board[PassX, FromY] := TempP;
          if IsInCheck(Current) then
          begin
            Board[FromX, FromY] := TempP;
            Board[PassX, FromY] := Empty;
            Exit;
          end;
          Board[FromX, FromY] := TempP;
          Board[PassX, FromY] := Empty;
          ValidMove := True;
        end;
      end;
  end;
end;

function FindKing(Current: Boolean; var KX, KY: Integer): Boolean;
var
  x, y: Integer;
begin
  FindKing := False;
  for y := 0 to 7 do
    for x := 0 to 7 do
      if ((Current and (Board[x, y] = WKing)) or (not Current and (Board[x, y] = BKing))) then
      begin
        KX := x;
        KY := y;
        FindKing := True;
        Exit;
      end;
end;

function IsInCheck(Current: Boolean): Boolean;
var
  KX, KY, x, y: Integer;
begin
  IsInCheck := False;
  if not FindKing(Current, KX, KY) then Exit;
  for y := 0 to 7 do
    for x := 0 to 7 do
      if IsOpponentPiece(Current, Board[x, y]) and ValidMove(x, y, KX, KY, not Current) then
      begin
        IsInCheck := True;
        Exit;
      end;
end;

function HasValidMoves(Current: Boolean): Boolean;
var
  FromX, FromY, ToX, ToY: Integer;
  TempBoard: TBoard;
  P: TPiece;
  dx, dy: Integer;
  was_empty: Boolean;
  RookX, NewRookX: Integer;
  TempEnPassantFile: Integer;
  TempWhiteKingMoved, TempBlackKingMoved: Boolean;
  TempWhiteQRookMoved, TempWhiteKRookMoved: Boolean;
  TempBlackQRookMoved, TempBlackKRookMoved: Boolean;
begin
  HasValidMoves := False;
  for FromY := 0 to 7 do
    for FromX := 0 to 7 do
      if IsOwnPiece(Current, Board[FromX, FromY]) then
        for ToY := 0 to 7 do
          for ToX := 0 to 7 do
            if ValidMove(FromX, FromY, ToX, ToY, Current) then
            begin
              { Simulate move and check if not in check }
              TempBoard := Board;
              TempEnPassantFile := EnPassantFile;
              TempWhiteKingMoved := WhiteKingMoved;
              TempBlackKingMoved := BlackKingMoved;
              TempWhiteQRookMoved := WhiteQRookMoved;
              TempWhiteKRookMoved := WhiteKRookMoved;
              TempBlackQRookMoved := BlackQRookMoved;
              TempBlackKRookMoved := BlackKRookMoved;
              P := Board[FromX, FromY];
              dx := ToX - FromX;
              dy := ToY - FromY;
              was_empty := (Board[ToX, ToY] = Empty);
              Board[ToX, ToY] := P;
              Board[FromX, FromY] := Empty;
              if ((P = WPawn) or (P = BPawn)) and (Abs(dx) = 1) and was_empty then
                Board[ToX, FromY] := Empty;
              if ((P = WKing) or (P = BKing)) and (Abs(dx) = 2) then
              begin
                if dx > 0 then
                begin
                  RookX := 7;
                  NewRookX := 5;
                end
                else
                begin
                  RookX := 0;
                  NewRookX := 3;
                end;
                Board[NewRookX, ToY] := Board[RookX, ToY];
                Board[RookX, ToY] := Empty;
              end;
              if (P = WPawn) and (ToY = 0) then Board[ToX, ToY] := WQueen
              else if (P = BPawn) and (ToY = 7) then Board[ToX, ToY] := BQueen;
              if not IsInCheck(Current) then
              begin
                HasValidMoves := True;
                Board := TempBoard;
                EnPassantFile := TempEnPassantFile;
                WhiteKingMoved := TempWhiteKingMoved;
                BlackKingMoved := TempBlackKingMoved;
                WhiteQRookMoved := TempWhiteQRookMoved;
                WhiteKRookMoved := TempWhiteKRookMoved;
                BlackQRookMoved := TempBlackQRookMoved;
                BlackKRookMoved := TempBlackKRookMoved;
                Exit;
              end;
              Board := TempBoard;
              EnPassantFile := TempEnPassantFile;
              WhiteKingMoved := TempWhiteKingMoved;
              BlackKingMoved := TempBlackKingMoved;
              WhiteQRookMoved := TempWhiteQRookMoved;
              WhiteKRookMoved := TempWhiteKRookMoved;
              BlackQRookMoved := TempBlackQRookMoved;
              BlackKRookMoved := TempBlackKRookMoved;
            end;
end;

procedure AddMove(FromX, FromY, ToX, ToY: Integer);
var
  from_str, to_str: String;
  s1, s2: String;
begin
  Str(8 - FromY, s1);
  Str(8 - ToY, s2);
  from_str := Chr(Ord('a') + FromX) + s1;
  to_str := Chr(Ord('a') + ToX) + s2;
  if MoveCount < MAX_MOVES then
  begin
    Moves[MoveCount] := from_str + to_str;
    Inc(MoveCount);
  end;
end;

procedure MakeMove(FromX, FromY, ToX, ToY: Integer);
var
  P: TPiece;
  was_empty: Boolean;
  dx, dy: Integer;
  RookX, NewRookX: Integer;
begin
  P := Board[FromX, FromY];
  dx := ToX - FromX;
  dy := ToY - FromY;
  was_empty := (Board[ToX, ToY] = Empty);
  Board[ToX, ToY] := P;
  Board[FromX, FromY] := Empty;
  { En passant }
  if ((P = WPawn) or (P = BPawn)) and (Abs(dx) = 1) and was_empty then
    Board[ToX, FromY] := Empty;
  { Castling }
  if ((P = WKing) or (P = BKing)) and (Abs(dx) = 2) then
  begin
    if dx > 0 then
    begin
      RookX := 7;
      NewRookX := 5;
    end
    else
    begin
      RookX := 0;
      NewRookX := 3;
    end;
    Board[NewRookX, ToY] := Board[RookX, ToY];
    Board[RookX, ToY] := Empty;
    { Set castling flags }
    if P = WKing then
    begin
      WhiteKingMoved := True;
      if dx > 0 then WhiteKRookMoved := True else WhiteQRookMoved := True;
    end
    else
    begin
      BlackKingMoved := True;
      if dx > 0 then BlackKRookMoved := True else BlackQRookMoved := True;
    end;
  end;
  { Pawn promotion }
  if (P = WPawn) and (ToY = 0) then Board[ToX, ToY] := WQueen
  else if (P = BPawn) and (ToY = 7) then Board[ToX, ToY] := BQueen;
  { Set en passant }
  if ((P = WPawn) or (P = BPawn)) and (Abs(dy) = 2) then
    EnPassantFile := ToX
  else
    EnPassantFile := -1;
  { Set movement flags }
  case P of
    WKing: WhiteKingMoved := True;
    BKing: BlackKingMoved := True;
    WRook:
      begin
        if (FromX = 0) and (FromY = 7) then WhiteQRookMoved := True;
        if (FromX = 7) and (FromY = 7) then WhiteKRookMoved := True;
      end;
    BRook:
      begin
        if (FromX = 0) and (FromY = 0) then BlackQRookMoved := True;
        if (FromX = 7) and (FromY = 0) then BlackKRookMoved := True;
      end;
  end;
end;

procedure ComputerMove;
var
  FromX, FromY, ToX, ToY: Integer;
  OppFromX, OppFromY, OppToX, OppToY: Integer;
  BestMoves: array[1..100] of TMove;
  NumBest: Integer;
  MaxScore: Integer;
  MoveScore: Integer;
  MinOppScore: Integer;
  OppSafeMove: Boolean;
  TempBoard, InnerTempBoard: TBoard;
  TempEnPassantFile, InnerTempEnPassantFile: Integer;
  TempWhiteKingMoved, InnerTempWhiteKingMoved: Boolean;
  TempBlackKingMoved, InnerTempBlackKingMoved: Boolean;
  TempWhiteQRookMoved, InnerTempWhiteQRookMoved: Boolean;
  TempWhiteKRookMoved, InnerTempWhiteKRookMoved: Boolean;
  TempBlackQRookMoved, InnerTempBlackQRookMoved: Boolean;
  TempBlackKRookMoved, InnerTempBlackKRookMoved: Boolean;
  eval: Integer;
  I: Integer;
  BestMove: TMove;
begin
  NumBest := 0;
  MaxScore := -INF;
  for FromY := 0 to 7 do
    for FromX := 0 to 7 do
      if IsOwnPiece(CurrentPlayer, Board[FromX, FromY]) then
        for ToY := 0 to 7 do
          for ToX := 0 to 7 do
            if ValidMove(FromX, FromY, ToX, ToY, CurrentPlayer) then
            begin
              TempBoard := Board;
              TempEnPassantFile := EnPassantFile;
              TempWhiteKingMoved := WhiteKingMoved;
              TempBlackKingMoved := BlackKingMoved;
              TempWhiteQRookMoved := WhiteQRookMoved;
              TempWhiteKRookMoved := WhiteKRookMoved;
              TempBlackQRookMoved := BlackQRookMoved;
              TempBlackKRookMoved := BlackKRookMoved;
              MakeMove(FromX, FromY, ToX, ToY);
              if IsInCheck(CurrentPlayer) then
              begin
                Board := TempBoard;
                EnPassantFile := TempEnPassantFile;
                WhiteKingMoved := TempWhiteKingMoved;
                BlackKingMoved := TempBlackKingMoved;
                WhiteQRookMoved := TempWhiteQRookMoved;
                WhiteKRookMoved := TempWhiteKRookMoved;
                BlackQRookMoved := TempBlackQRookMoved;
                BlackKRookMoved := TempBlackKRookMoved;
                continue;
              end;
              MinOppScore := INF;
              OppSafeMove := False;
              for OppFromY := 0 to 7 do
                for OppFromX := 0 to 7 do
                  if IsOwnPiece(not CurrentPlayer, Board[OppFromX, OppFromY]) then
                    for OppToY := 0 to 7 do
                      for OppToX := 0 to 7 do
                        if ValidMove(OppFromX, OppFromY, OppToX, OppToY, not CurrentPlayer) then
                        begin
                          InnerTempBoard := Board;
                          InnerTempEnPassantFile := EnPassantFile;
                          InnerTempWhiteKingMoved := WhiteKingMoved;
                          InnerTempBlackKingMoved := BlackKingMoved;
                          InnerTempWhiteQRookMoved := WhiteQRookMoved;
                          InnerTempWhiteKRookMoved := WhiteKRookMoved;
                          InnerTempBlackQRookMoved := BlackQRookMoved;
                          InnerTempBlackKRookMoved := BlackKRookMoved;
                          MakeMove(OppFromX, OppFromY, OppToX, OppToY);
                          if not IsInCheck(not CurrentPlayer) then
                          begin
                            OppSafeMove := True;
                            eval := EvaluateBoard;
                            MinOppScore := Min(MinOppScore, eval);
                          end;
                          Board := InnerTempBoard;
                          EnPassantFile := InnerTempEnPassantFile;
                          WhiteKingMoved := InnerTempWhiteKingMoved;
                          BlackKingMoved := InnerTempBlackKingMoved;
                          WhiteQRookMoved := InnerTempWhiteQRookMoved;
                          WhiteKRookMoved := InnerTempWhiteKRookMoved;
                          BlackQRookMoved := InnerTempBlackQRookMoved;
                          BlackKRookMoved := InnerTempBlackKRookMoved;
                        end;
              if OppSafeMove then
                MoveScore := MinOppScore
              else
              begin
                if IsInCheck(not CurrentPlayer) then
                  MoveScore := INF  { checkmate for opponent }
                else
                  MoveScore := 0;  { stalemate }
              end;
              if MoveScore > MaxScore then
              begin
                MaxScore := MoveScore;
                NumBest := 1;
                BestMoves[NumBest].FromX := FromX;
                BestMoves[NumBest].FromY := FromY;
                BestMoves[NumBest].ToX := ToX;
                BestMoves[NumBest].ToY := ToY;
              end
              else if MoveScore = MaxScore then
              begin
                Inc(NumBest);
                BestMoves[NumBest].FromX := FromX;
                BestMoves[NumBest].FromY := FromY;
                BestMoves[NumBest].ToX := ToX;
                BestMoves[NumBest].ToY := ToY;
              end;
              Board := TempBoard;
              EnPassantFile := TempEnPassantFile;
              WhiteKingMoved := TempWhiteKingMoved;
              BlackKingMoved := TempBlackKingMoved;
              WhiteQRookMoved := TempWhiteQRookMoved;
              WhiteKRookMoved := TempWhiteKRookMoved;
              BlackQRookMoved := TempBlackQRookMoved;
              BlackKRookMoved := TempBlackKRookMoved;
            end;
  if NumBest > 0 then
  begin
    I := Random(NumBest) + 1;
    BestMove := BestMoves[I];
    MakeMove(BestMove.FromX, BestMove.FromY, BestMove.ToX, BestMove.ToY);
    AddMove(BestMove.FromX, BestMove.FromY, BestMove.ToX, BestMove.ToY);
  end;
end;

procedure DrawBoard;
var
  x, y: Integer;
  Color: Byte;
  s: String;
begin
  xClearScreen(Buffer, BLACK);
  for y := 0 to 7 do
    for x := 0 to 7 do
    begin
      if ((x + y) mod 2 = 0) then Color := LIGHT_SQUARE else Color := DARK_SQUARE;
      xDrawRect(Buffer, BOARD_X + x * SQUARE_SIZE, BOARD_Y + y * SQUARE_SIZE, SQUARE_SIZE, SQUARE_SIZE, Color, True);
      if Board[x, y] <> Empty then
        xDrawBitmap(Buffer, BOARD_X + x * SQUARE_SIZE, BOARD_Y + y * SQUARE_SIZE, Images[Board[x, y]], True);
    end;
  if (SelectedX >= 0) then
    xDrawRect(Buffer, BOARD_X + SelectedX * SQUARE_SIZE, BOARD_Y + SelectedY * SQUARE_SIZE,
                      SQUARE_SIZE, SQUARE_SIZE, SELECT_COLOR, False);

  { Numbers 1-8 on the left }
  for y := 0 to 7 do
  begin
    Str(8 - y, s);
    xText(Buffer, BOARD_X - 15, BOARD_Y + y * SQUARE_SIZE + (SQUARE_SIZE div 2) - 5, s, WHITE);
  end;

  { Letters a-h at the bottom }
  for x := 0 to 7 do
  begin
    s := Chr(Ord('a') + x);
    xText(Buffer, BOARD_X + x * SQUARE_SIZE + (SQUARE_SIZE div 2) - 5, BOARD_Y + BOARD_SIZE * SQUARE_SIZE + 5, s, WHITE);
  end;
end;

procedure DrawUI;
begin
  xText(Buffer, 10, 10, 'Turn:', WHITE);
  if CurrentPlayer then
    xDrawRect(Buffer, 22, 20, 10, 10, WHITE, True)
  else
    xDrawRect(Buffer, 22, 20, 10, 10, 13, True);
  if InCheck then
    xText(Buffer, 10, 40, 'Check!', WHITE);
  if GameOver then
  begin
    xText(Buffer, 10, 60, 'Game over:', WHITE);
    xText(Buffer, 10, 70, Winner, WHITE);
  end;

end;

procedure DrawMoves;
var
  i, j, moveY, start: Integer;
begin
  moveY := 10;
  xText(Buffer, 260, moveY, 'Moves:', WHITE);
  moveY := moveY + 10;
  if MoveCount = 0 then exit;
  start := ((MoveCount - 1) div MAX_DISPLAY_LINES) * MAX_DISPLAY_LINES;
  j := 0;
  for i := start to MoveCount - 1 do
  begin
    xText(Buffer, 260, moveY + j * 10, Moves[i], WHITE);
    Inc(j);
  end;
end;

procedure HandleInput;
var
  ClickX, ClickY: Integer;
  TempBoard: TBoard;
  TempEnPassantFile: Integer;
  TempWhiteKingMoved, TempBlackKingMoved: Boolean;
  TempWhiteQRookMoved, TempWhiteKRookMoved: Boolean;
  TempBlackQRookMoved, TempBlackKRookMoved: Boolean;
begin
  xMouseUpdate;
  if MOUSE_LEFT then
  begin
    ClickX := (MOUSE_X - BOARD_X) div SQUARE_SIZE;
    ClickY := (MOUSE_Y - BOARD_Y) div SQUARE_SIZE;
    if (ClickX >= 0) and (ClickX < 8) and (ClickY >= 0) and (ClickY < 8) then
    begin
      if (SelectedX < 0) then
      begin
        if IsOwnPiece(CurrentPlayer, Board[ClickX, ClickY]) then
        begin
          SelectedX := ClickX;
          SelectedY := ClickY;
        end;
      end
      else
      begin
        if ValidMove(SelectedX, SelectedY, ClickX, ClickY, CurrentPlayer) then
        begin
          TempBoard := Board;
          TempEnPassantFile := EnPassantFile;
          TempWhiteKingMoved := WhiteKingMoved;
          TempBlackKingMoved := BlackKingMoved;
          TempWhiteQRookMoved := WhiteQRookMoved;
          TempWhiteKRookMoved := WhiteKRookMoved;
          TempBlackQRookMoved := BlackQRookMoved;
          TempBlackKRookMoved := BlackKRookMoved;
          MakeMove(SelectedX, SelectedY, ClickX, ClickY);
          if not IsInCheck(CurrentPlayer) then
          begin
            AddMove(SelectedX, SelectedY, ClickX, ClickY);
            SelectedX := -1;
            CurrentPlayer := not CurrentPlayer;
          end
          else
          begin
            Board := TempBoard;
            EnPassantFile := TempEnPassantFile;
            WhiteKingMoved := TempWhiteKingMoved;
            BlackKingMoved := TempBlackKingMoved;
            WhiteQRookMoved := TempWhiteQRookMoved;
            WhiteKRookMoved := TempWhiteKRookMoved;
            BlackQRookMoved := TempBlackQRookMoved;
            BlackKRookMoved := TempBlackKRookMoved;
            SelectedX := -1;
          end;
        end
        else
          SelectedX := -1;
      end;
    end;
    xWait(50);  { Debounce }
  end;
end;

procedure CheckGameState;
begin
  InCheck := IsInCheck(CurrentPlayer);
  if InCheck and not HasValidMoves(CurrentPlayer) then
  begin
    GameOver := True;
    if CurrentPlayer then Winner := 'Black wins!' else Winner := 'White wins!';
  end
  else if not HasValidMoves(CurrentPlayer) then
  begin
    GameOver := True;
    Winner := 'Stalemate!';
  end;
end;

begin
  Randomize;
  xSetVGAMode;
  xInitTimer(1000);
  if not xMouseInit then Halt(1);
  xShowMouse;
  xSetMouseArea(0, 319, 0, 199);
  xCreateBuffer(Buffer);
  xLoadPaletteBMP('data\wking.bmp');
  xSetColor(15, 63, 63, 63);
  LoadPieceImages;
  InitBoard;
  EnPassantFile := -1;
  WhiteKingMoved := False;
  BlackKingMoved := False;
  WhiteQRookMoved := False;
  WhiteKRookMoved := False;
  BlackQRookMoved := False;
  BlackKRookMoved := False;
  MoveCount := 0;
  CurrentPlayer := True;  { White starts }
  SelectedX := -1;
  GameOver := False;

  while not KeyPressed do
  begin
    if not CurrentPlayer then  { Computer's turn (black) }
    begin
      ComputerMove;
      CurrentPlayer := True;
    end;

    HandleInput;
    CheckGameState;
    DrawBoard;
    DrawUI;
    DrawMoves;
    xHideMouse;  { Hide mouse before copying buffer to prevent flicker }
    xCopyBuffer(Buffer, Ptr(VGA_SEGMENT, 0));
    xShowMouse;  { Show mouse after copying }
    xWait(50);
  end;

  FreePieceImages;
  xFreeBuffer(Buffer);
  xRestoreTimer;
  xHideMouse;
  xSetTxtMode;
end.