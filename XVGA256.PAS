unit xVGA256;

interface

uses crt;

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

procedure xSetVGAMode;                           { Ustaw tryb VGA 320x200x256 }
procedure xSetTxtMode;                           { Ustaw tryb tekstowy }
procedure xDrawPixel(x, y : word; color : byte); { Rysuj piksel }

implementation

{--------------}

procedure xSetVGAMode;
begin
    asm
        mov AX, 13h
        int 10h      
    end;
end;


procedure xSetTxtMode;
begin
    asm
        mov AX, 0003h
        int 10h
    end;
end;


procedure xDrawPixel(x, y : word; color : byte);
begin
    asm
        mov ax, y
        mov di, ax
        shl ax, 8
        shl di, 6
        add di, ax
        add di, x
        mov ax, 0a000h
        mov es, ax
        mov al, color
        mov byte ptr es:[di], al
    end;
end;

{--------------}

end.
