unit xMouse;

(**************************************************************)
(** //              XENGINE Mouse Unit                    // **)
(** //  (C) 2025 Coded by Adam Kozinski & Dominik Galoch  // **)
(** //////////////////////////////////////////////////////// **)
(**************************************************************)

interface

var
   MOUSE_LEFT, MOUSE_MIDDLE, MOUSE_RIGHT : boolean;
   MOUSE_X, MOUSE_Y : word;

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

function xMouseInit : boolean;                          { Sprawdzaj czy mysz jest zainstalowana }
procedure xShowMouse;                                   { Pokaz kursor myszy }
procedure xHideMouse;                                   { Ukryj kursor myszy }
procedure xResetMouse;                                  { Zresetuj kursor myszy }
procedure xSetMousePosition(PosX, PosY : word);         { Ustaw pozycje kursora myszy na ekranie }
procedure xMouseUpdate;                                 { Sprawdzaj status myszy }
procedure xSetMouseSpeed(SpeedX, SpeedY : word);        { Ustaw predkosc myszy }
procedure xSetMouseArea(MinX, MaxX, MinY, MaxY : word); { Ustaw obszar ekranu dla ruchu kursora myszy }

{//////////////////////////////////////////////////////////}

implementation

(***********************************************************)

function xMouseInit : boolean;
begin
    asm
        mov ax, 0000h                   { Zaladuj 0000h do AX }
        int 33h                         { Wywolaj przerwanie 33h }
        mov @result, al
    end;
end;

(***********************************************************)

procedure xShowMouse;
begin
    asm
        mov ax, 0001h                   { Zaladuj 0001h do AX }
        int 33h                         { Wywolaj przerwanie 33h }
    end;
end;

(***********************************************************)

procedure xHideMouse;
begin
    asm
        mov ax, 0002h                   { Zaladuj 0002h do AX }
        int 33h                         { Wywolaj przerwanie 33h }
    end;
end;

(***********************************************************)

procedure xResetMouse;
begin
    xHideMouse;
    xShowMouse;
end;

(***********************************************************)

procedure xSetMousePosition(PosX, PosY : word);
begin
    asm
        mov ax, 0004h                   { Zaladuj kod przerwania 33h dla ustawienia pozycji kursora }
        mov cx, PosX                    { Zaladuj wartosc X do rejestru CX }
        mov dx, PosY                    { Zaladuj wartosc Y do rejestru DX }
        int 33h                         { Wywolaj przerwanie 33h }
    end;
end;

(***********************************************************)

procedure xSetMouseSpeed(SpeedX, SpeedY : word);
begin
    asm
        mov ax, 001Ah
        mov bx, SpeedX
        mov cx, SpeedY
        int 33h
    end;
end;

(***********************************************************)

procedure xMouseUpdate;
var
    temp : word;
    temp_pos_x, temp_pos_y : word;
begin
    asm
        mov ax, 0003h                   { Zaladuj 00003h do AX }
        int 33h                         { Wywolaj przerwanie 33h }
        mov word ptr temp, bx           { Zaladuj BX do temp}
        mov word ptr temp_pos_x, cx     { Zaladuj CX do temp_pos_x }
        mov word ptr temp_pos_y, dx     { Zaladuj DX do temp_pos_y }
    end;

    MOUSE_X := temp_pos_x;
    MOUSE_Y := temp_pos_y;

    if ( (temp and $01) <> 0 ) then MOUSE_LEFT := TRUE else MOUSE_LEFT := FALSE;
    if ( (temp and $02) <> 0 ) then MOUSE_RIGHT := TRUE else MOUSE_RIGHT := FALSE;
    if ( (temp and $04) <> 0 ) then MOUSE_MIDDLE := TRUE else MOUSE_MIDDLE := FALSE;
end;

(***********************************************************)

procedure xSetMouseArea(MinX, MaxX, MinY, MaxY : word);
begin
    asm
        mov ax, 0007h
        shl MinX, 1
        shl MaxX, 1
        mov cx, MinX
        mov dx, MaxX
        int 33h
        mov ax, 0008h
        mov cx, MinY
        mov dx, MaxY
        int 33h
    end;
end;

(***********************************************************)

end.
