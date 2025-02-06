unit xVGA256;

interface

type color_palette = record
                        red: byte;
                        green: byte;
                        blue: byte;
                     end;

var
     color_array : array[0..255] of color_palette;

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

procedure xSetVGAMode;                                                          { Ustaw tryb VGA 320x200x256 }
procedure xSetTxtMode;                                                          { Ustaw tryb tekstowy }
procedure xLoadColorPalette;                                                    { Zaladuj palete kolorow VGA }
procedure xDrawPixel(x, y : word; color : byte);                                { Rysuj piksel }
procedure xDrawLineHorz(x_start, x_end, y: word; color : byte);                 { Rysuj line pozioma }
procedure xDrawLineVert(x, y_start, y_end : word; color : byte);                { Rysuj linie pionowa }
procedure xDrawRectangle(x_start, y_start, x_len, y_len : word; color : byte);  { Rysuj prostokat }
procedure xDrawSquare(x_start, y_start, len : word; color: byte);               { Rysuj kwadrat}
procedure xFillScreen(color : byte);                                            { Wypelnij ekran kolorem }

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

procedure xLoadColorPalette;
    var 
        idx : byte;
    begin

    for idx := 0 to 255 do
    begin
        color_array[idx].red := port[$3c9];
        color_array[idx].green := port[$3c9];
        color_array[idx].blue := port[$3c9];
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

procedure xDrawLineHorz(x_start, x_end, y: word; color : byte);
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

procedure xDrawLineVert(x, y_start, y_end : word; color : byte);
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

procedure xDrawRectangle(x_start, y_start, x_len, y_len : word; color : byte);
begin
    xDrawLineHorz(x_start, x_start + x_len, y_start, color);
    xDrawLineHorz(x_start, x_start + x_len, y_start + y_len, color);
    xDrawLineVert(x_start, y_start, y_start + y_len, color);
    xDrawLineVert(x_start + x_len, y_start, y_start + y_len, color);
end;

procedure xDrawSquare(x_start, y_start, len : word; color: byte);
begin
    xDrawRectangle(x_start, y_start, len, len, color);
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
