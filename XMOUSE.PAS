unit xMouse;

interface

var
   MOUSE_LEFT, MOUSE_MIDDLE, MOUSE_RIGHT : boolean;
   MOUSE_X, MOUSE_Y : word;

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

procedure xShowMouse;                               { Pokaz kursor myszy }
procedure xHideMouse;                               { Ukryj kursor myszy }
procedure xResetMouse;                              { Zresetuj kursor myszy }
procedure xMouseUpdate;                             { Sprawdzaj status myszy }
procedure xSetMouseSpeed(SpeedX, SpeedY : word);    { Ustaw predkosc myszy }

implementation

{*****************************************************************************}

procedure xShowMouse;
begin
    asm
        mov ax, 0001h                   {laduj 0001h do AX}
        int 33h                         {wywolaj przerwanie 33h}
    end;
end;

procedure xHideMouse;
begin
    asm
        mov ax, 0002h                   {laduj 0002h do AX}
        int 33h                         {wywolaj przerwanie 33h}
    end;
end;

procedure xResetMouse;
begin
    xHideMouse;
    xShowMouse;
end;

procedure xSetMouseSpeed(SpeedX, SpeedY : word);
begin
    asm
        mov ax, 001Ah
        mov bx, SpeedX
        mov cx, SpeedY
        int 33h
    end;
end;

procedure xMouseUpdate;
var
    temp : word;
    temp_pos_x, temp_pos_y : word;
begin
    asm
        mov ax, 0003h                   {laduj 00003h do AX}
        int 33h                         {wywolaj przerwanie 33h}
        mov word ptr temp, bx           {laduj BX do temp}
        mov word ptr temp_pos_x, cx     {laduj CX do temp_pos_x}
        mov word ptr temp_pos_y, dx     {laduj DX do temp_pos_y}
    end;

    MOUSE_X := temp_pos_x;
    MOUSE_Y := temp_pos_y;

    if ( (temp and $01) <> 0 ) then MOUSE_LEFT := TRUE else MOUSE_LEFT := FALSE;
    if ( (temp and $02) <> 0 ) then MOUSE_RIGHT := TRUE else MOUSE_RIGHT := FALSE;
    if ( (temp and $04) <> 0 ) then MOUSE_MIDDLE := TRUE else MOUSE_MIDDLE := FALSE;
end;

{*****************************************************************************}

end.