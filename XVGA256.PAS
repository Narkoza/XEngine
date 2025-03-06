unit xVGA256;

interface

type TPalette = record
                    red: byte;
                    green: byte;
                    blue: byte;
                end;

var
     color_array : array[0..255] of TPalette;

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

procedure xSetVGAMode;                                              { Ustaw tryb VGA 320x200x256c }
procedure xSetTxtMode;                                              { Ustaw tryb tekstowy }
procedure xLoadColorPalette;                                        { Zaladuj palete kolorow VGA }
procedure xDrawPixel(x, y : word; color : byte);                    { Rysuj piksel }
procedure xDrawLineHorz(x_start, x_end, y: word; color : byte);     { Rysuj linie pozioma }
procedure xDrawLineVert(x, y_start, y_end : word; color : byte);    { Rysuj linie pionowa }

procedure xDrawRectangle(x_start, y_start, x_len, y_len : word; color : byte; fill_color : boolean);    { Rysuj prostokat }
procedure xDrawSquare(x_start, y_start, len : word; color: byte; fill_color : boolean);                 { Rysuj kwadrat }
procedure xDrawCircle(x_start, y_start, c_radius : word; color: byte; fill_color : boolean);            { Rysuj kolo }
procedure xDrawCircleAsm(x_start, y_start, c_radius : word; color: byte);

procedure xFillScreen(color : byte);                                { Wypelnij ekran kolorem }

implementation

(***********************************************************)

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

procedure xDrawRectangle(x_start, y_start, x_len, y_len : word; color : byte; fill_color : boolean);
var
    y : word;
begin
    if fill_color then
    begin
        for y := y_start to y_start + y_len do
        begin
            xDrawLineHorz(x_start, x_start + x_len, y, color);
        end;
    end

    else

    begin
        xDrawLineHorz(x_start, x_start + x_len, y_start, color);
        xDrawLineHorz(x_start, x_start + x_len, y_start + y_len, color);
        xDrawLineVert(x_start, y_start, y_start + y_len, color);
        xDrawLineVert(x_start + x_len, y_start, y_start + y_len, color);
    end;
end;

procedure xDrawSquare(x_start, y_start, len : word; color: byte; fill_color : boolean);
begin
    xDrawRectangle(x_start, y_start, len, len, color, fill_color);
end;

procedure xDrawCircle(x_start, y_start, c_radius : word; color: byte; fill_color : boolean);
var
    x, y : word;
    d : integer;
begin
    x := 0;
    y := c_radius;
    d := 3 - 2 * c_radius;

    while x <= y do
    begin
        xDrawPixel(x_start + x, y_start + y, color);
        xDrawPixel(x_start - x, y_start + y, color);
        xDrawPixel(x_start + x, y_start - y, color);
        xDrawPixel(x_start - x, y_start - y, color);
        xDrawPixel(x_start + y, y_start + x, color);
        xDrawPixel(x_start - y, y_start + x, color);
        xDrawPixel(x_start + y, y_start - x, color);
        xDrawPixel(x_start - y, y_start - x, color);

        if fill_color then
        begin
            xDrawLineHorz(x_start - x, x_start + x, y_start + y, color); 
            xDrawLineHorz(x_start - x, x_start + x, y_start - y, color); 
            xDrawLineHorz(x_start - y, x_start + y, y_start + x, color); 
            xDrawLineHorz(x_start - y, x_start + y, y_start - x, color); 
        end;

        if d < 0 then
            d := d + 4 * x + 6
        else
        begin
            d := d + 4 * (x - y) + 10;
            Dec(y);
        end;

        Inc(x);
    end;

    if fill_color then
    begin
        for y := 0 to c_radius do
        begin
            x := Round(Sqrt(c_radius * c_radius - y * y));
            xDrawLineHorz(x_start - x, x_start + x, y_start + y, color);
            xDrawLineHorz(x_start - x, x_start + x, y_start - y, color);
        end;
    end;
end;

procedure xDrawCircleAsm(x_start, y_start, c_radius : word; color: byte);
begin
asm
    { Initialize registers }
    mov ax, c_radius         { Load the radius into AX }
    mov bx, 0                { Initialize x = 0 }
    mov dx, ax               { Initialize y = radius (y = c_radius) }
    mov cx, 3                { d = 3 - 2 * radius, so start with d = 3 }
    sub cx, ax               { d = 3 - 2 * radius }
    mov si, x_start          { Load x_start into SI (x_center) }
    mov di, y_start          { Load y_start into DI (y_center) }
    
@draw_circle_loop:
    { Plot points for all 8 octants of the circle }
    { Plot the points (x + h, y + k), (x + h, -y + k), (-x + h, y + k), (-x + h, -y + k), }
    { (y + h, x + k), (y + h, -x + k), (-y + h, x + k), (-y + h, -x + k) }

    { Plot point (x + x_start, y + y_start) }
    add bx, si               { x_start + x }
    add dx, di               { y_start + y }
    mov ax, bx
    mov bx, dx
    call xDrawPixel

    { Plot point (x + x_start, -y + y_start) }
    sub dx, di               { y_start - y }
    mov ax, bx
    mov bx, dx
    call xDrawPixel

    { Plot point (-x + x_start, y + y_start) }
    sub bx, si               { x_start - x }
    add dx, di               { y_start + y }
    mov ax, bx
    mov bx, dx
    call xDrawPixel

    { Plot point (-x + x_start, -y + y_start) }
    sub bx, si               { x_start - x }
    sub dx, di               { y_start - y }
    mov ax, bx
    mov bx, dx
    call xDrawPixel

    { Plot point (y + x_start, x + y_start) }
    add bx, si               { y_start + y }
    add dx, di               { x_start + x }
    mov ax, bx
    mov bx, dx
    call xDrawPixel

    { Plot point (y + x_start, -x + y_start) }
    add bx, si               { y_start + y }
    sub dx, di               { x_start - x }
    mov ax, bx
    mov bx, dx
    call xDrawPixel

    { Plot point (-y + x_start, x + y_start) }
    sub bx, si               { x_start - y }
    add dx, di               { x_start + x }
    mov ax, bx
    mov bx, dx
    call xDrawPixel

    { Plot point (-y + x_start, -x + y_start) }
    sub bx, si               { x_start - y }
    sub dx, di               { x_start - x }
    mov ax, bx
    mov bx, dx
    call xDrawPixel

    { Update decision parameter and coordinates }
    add bx, 1                { Increment x }
    cmp cx, 0                { Check if d < 0 }
    jge @skip_decrement
    { Update decision variable }
    { d = d + 4 * x + 6 }
    add cx, bx               { d = d + 4 * x }
    add cx, 6                { d = d + 6 }
    jmp @check_loop

@skip_decrement:
    { Update decision variable }
    { d = d + 4 * (x - y) + 10 }
    sub dx, bx               { y -= 1 }
    sub cx, dx               { d = d + 4 * (x - y) }
    add cx, 10               { d = d + 10 }

@check_loop:
    cmp bx, dx               { Check if x >= y }
    jle @draw_circle_loop     { Loop if x <= y }

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

(***********************************************************)

end.
