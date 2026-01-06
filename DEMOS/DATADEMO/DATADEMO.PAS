program readdata;

uses xFiles;

type
    TGameState = record
                    level: integer;
                    score: longint;
                    lives: byte;
                end;

var
    gameState: TGameState;

begin
    gameState.level := 1;
    gameState.score := 0;
    gameState.lives := 3;

    xSaveFile('SAVEGAME.DAT', gameState, SizeOf(TGameState));
    xLoadFile('SAVEGAME.DAT', gameState, SizeOf(TGameState));
end.