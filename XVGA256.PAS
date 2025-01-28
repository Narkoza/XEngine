unit xVGA256;

interface

uses crt;

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

procedure xSetVGAMode;                           { Ustaw tryb VGA 320x200x256 }
procedure xSetTxtMode;                           { Ustaw tryb tekstowy }
procedure xDrawPixel(x, y : word; color : byte); { Rysuj piksel }
procedure xDrawLineHorizontal(x_start, x_end, y: word; color : byte); { Rysuj line pozioma }
procedure xDrawLineVertical(x, y_start, y_end : word; color : byte); { Rysuj linie pionowa }
procedure xFillScreen(color : byte); { Wypelnij ekran kolorem }

implementation

{*****************************************************************************}

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

procedure xDrawLineHorizontal(x_start, x_end, y: word; color : byte);
begin
    asm
        mov cx, x_end
        sub cx, x_start
        add cx, 1
        mov ax, y
        mov di, ax
        shl ax, 8
        shl di, 6
        add di, ax
        add di, x_start
        mov ax, 0a000h
        mov es, ax
        mov al, color
        cld
        rep stosb
    end;
end;

procedure xDrawLineVertical(x, y_start, y_end : word; color : byte);
begin
    asm
        mov cx, y_end
        sub cx, y_start
        add cx, 1
        mov ax, y_start
        mov di, ax
        shl ax, 8
        shl di, 6
        add di, ax
        add di, x
        mov ax, 0a000h
        mov es, ax
        mov al, color

        @draw_line_loop:
        mov es:[di], al
        add di, 320
        loop @draw_line_loop
    end;
end;

procedure xFillScreen(color : byte);
begin
    asm
        mov ax, 0a000h
        mov es, ax
        mov di, 0
        mov cx, 32000
        mov ah, color
        mov al, ah
        cld
        rep stosw
    end;
end;

{*****************************************************************************}

end.
