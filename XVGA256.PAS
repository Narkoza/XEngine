unit xVGA256;

{$G+}  { Zezwol na instrukcje 286 }

interface

const
    SCREEN_WIDTH    = 320;
    SCREEN_HEIGHT   = 200;
    VGA_SEGMENT     = $A000;
    MAX_BUFFER_SIZE = SCREEN_WIDTH * SCREEN_HEIGHT;

type
    TImageBuffer = array[0..63999] of byte;

    TImage = record
                width   : word;
                height  : word;
                img_ptr : ^TImageBuffer;
                size    : word;
             end;

    THandleBMP = record
                    bfType          : word;    { Typ pliku (musi byc 'BM' = 0x4D42) }
                    bfSize          : longint; { Calkowity rozmiar pliku (w bajtach) }
                    bfRes1          : word;    { Zarezerwowane (zwykle 0) }
                    bfRes2          : word;    { Zarezerwowane (zwykle 0) }
                    bfOffBits       : longint; { Przesuniecie od poczatku pliku do danych obrazu }
                    biSize          : longint; { Rozmiar tego naglowka (zwykle 40 bajtow) }
                    biWidth         : longint; { Szerokosc obrazu w pikselach }
                    biHeight        : longint; { Wysokosc obrazu w pikselach }
                    biPlanes        : word;    { Liczba plaszczyzn (zwykle 1) }
                    biBitCount      : word;    { Liczba bitow na piksel (dla 256 kolorow to 8) }
                    biCompression   : longint; { Typ kompresji (zwykle 0 - brak kompresji) }
                    biSizeImage     : longint; { Rozmiar danych obrazu }
                    biXPelsPerMeter : longint; { Rozdzielczosc pozioma (w pikselach na metr) }
                    biYPelsPerMeter : longint; { Rozdzielczosc pionowa (w pikselach na metr) }
                    biClrUsed       : longint; { Liczba uzywanych kolorow (256 dla 256 kolorow) }
                    biClrImportant  : longint; { Liczba waznych kolorow (mozna ustawic na 0) }
                end;

    TPaletteBMP = record
                    blue        : byte;
                    green       : byte;
                    red         : byte;
                    reserved    : byte;
                end;

    TPalette = record
                    red     : byte;
                    green   : byte;
                    blue    : byte;
                end;

    VGAPalette = array[0..255] of TPalette;

var
    bmp_palette : array[0..255] of TPaletteBMP;
    buffer_ptr  : pointer;

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

procedure xSetVGAMode;                                                                      { Ustaw tryb 13h, 320x200x256c }
procedure xSetTxtMode;                                                                               { Ustaw tryb tekstowy }
procedure xSetColor(color_nr : byte; r, g, b : byte);                                               { Ustaw wzorzec koloru }
procedure xGetPaletteVGA(var pal : VGAPalette);                                                       { Pobierz palete VGA }
procedure xSetPaletteVGA(pal : VGAPalette);                                                            { Zapisz palete VGA }
procedure xLoadPaletteBMP(filename : string);                                                         { Pobierz palete BMP }
procedure xGetColor(color_nr : byte; var color : TPalette);                                       { Pobierz wzorzec koloru }
procedure xLoadBMP(var image : TImage; filename : string);                                               { Wczytaj bitmape }
procedure xDrawBMP(var image : TImage);                                                                    { Rysuj bitmape }
procedure xDrawPixel(x, y : word; color : byte);                                                            { Rysuj piksel }
procedure xDrawLineHorz(x_start, x_end, y : word; color : byte);                                     { Rysuj linie pozioma }
procedure xDrawLineVert(x, y_start, y_end : word; color : byte);                                     { Rysuj linie pionowa }
procedure xDrawLineDiag(x_start, y_start, x_end, y_end : word; color : byte);                         { Rysuj linie ukosna }
procedure xDrawRectangle(x_start, y_start, x_len, y_len : word; color : byte; fill_color : boolean);     { Rysuj prostokat }
procedure xDrawSquare(x, y, len : word; color: byte; fill_color : boolean);                                { Rysuj kwadrat }
procedure xDrawCircle(x_start, y_start, radius : word; color: byte; fill_color : boolean);                    { Rysuj kolo }
{procedure xDrawCircleAsm(x_start, y_start, c_radius : word; color: byte);}
procedure xFillScreen(color : byte);                                                              { Wypelnij ekran kolorem }
procedure xCreateBuffer(var buffer_ptr : pointer);                                   { Zaalokuj pamiec dla drugiego bufora }
procedure xFreeBuffer(var buffer_ptr : pointer);                                          { Zwolnij pamiec drugiego bufora }
procedure xCopyBuffer(target, source : pointer);                                          { Kopiuj bufor ze zrodla do celu }
procedure xFillBuffer(buffer_ptr : pointer; color : byte);                                        { Wypelnij bufor kolorem }
procedure xWaitForVertRetrace;                                                              { Czekaj na powrot pionowy CRT }

{//////////////////////////////////////////////////////////}

implementation

(***********************************************************)

procedure xSetVGAMode;
begin
    asm
        mov AX, 13h
        int 10h
    end;
end;

(***********************************************************)

procedure xSetTxtMode;
begin
    asm
        mov AX, 0003h
        int 10h
    end;
end;

(***********************************************************)

procedure xSetColor(color_nr : byte; r, g, b : byte);
begin
    { Okreslamy numer wzorca koloru ktory chcemy zmodyfikowac }
    port[$3c8] := color_nr;

    { Wysylamy do portu 3c9h intensywnosc podstawowych kolorow }
    port[$3c9] := r;
    port[$3c9] := g;
    port[$3c9] := b;
end;

(***********************************************************)

procedure xGetPaletteVGA(var pal : VGAPalette);
var
    idx : byte;
begin
    { Chcemy odczytac cala palete kolorow, dlatego tez rozpoczynamy
    jej czytanie od pierwszego wzorca koloru }
    port[$3c7] := 0;

    { Odczytanie palety kolorow }
    for idx := 0 to 255 do
    begin
        pal[idx].red    := port[$3c9];
        pal[idx].green  := port[$3c9];
        pal[idx].blue   := port[$3c9];
    end;
end;

(***********************************************************)

procedure xSetPaletteVGA(pal : VGAPalette);
var
    idx : byte;
begin
    { Chcemy zapisac cala palete kolorow, dlatego tez rozpoczynamy
    jej czytanie od pierwszego wzorca koloru }
    port[$3c8] := 0;

    { Zapis palety kolorow }
    for idx := 0 to 255 do
    begin
        pal[idx].red    := port[$3c9];
        pal[idx].green  := port[$3c9];
        pal[idx].blue   := port[$3c9];
    end;
end;

(***********************************************************)

procedure xLoadPaletteBMP(filename : string);
var
    fd           : file;
    counter      : word;
    palette_size : word;
begin
    assign(fd, filename);
    reset(fd, 1);

    seek(fd, sizeof(THandleBMP));

    palette_size := sizeof(bmp_palette);

    blockread(fd, bmp_palette, palette_size);

    port[$3c8] := 0;

    { Odczytanie palety kolorow }
    for counter := 0 to 255 do
    begin
        port[$3c9] := bmp_palette[counter].red shr 2;
        port[$3c9] := bmp_palette[counter].green shr 2;
        port[$3c9] := bmp_palette[counter].blue shr 2;
    end;

    close(fd);
end;

(***********************************************************)

procedure xGetColor(color_nr : byte; var color : TPalette);
begin
    { Okreslamy numer wzorca koloru ktory chcemy pobrac }
    port[$3c7] := color_nr;

    { Pobieramy z portu 3c9h intensywnosc podstawowych kolorow }
    color.red   := port[$3c9];
    color.green := port[$3c9];
    color.blue  := port[$3c9];
end;

(***********************************************************)

procedure xLoadBMP(var image : TImage; filename : string);
var
    fd           : file;
    img_meta     : THandleBMP;
    counter      : word;
    current_row  : word;
begin

    assign(fd, filename);
    reset(fd, 1);

    counter := sizeof(THandleBMP);
    blockread(fd, img_meta, counter);

    if((img_meta.biWidth > SCREEN_WIDTH) or (img_meta.biHeight > SCREEN_HEIGHT)) then
    begin
        close(fd);
        exit;
    end;

    seek(fd,1078);

    image.width   := img_meta.biWidth;
    image.height  := img_meta.biHeight;
    image.size    := img_meta.biWidth * img_meta.biHeight;

    if(maxavail < image.size) then
    begin
        close(fd);
        exit;
    end;

    getmem(image.img_ptr, image.size);

    counter := img_meta.biWidth;

    for current_row := 0 to img_meta.biHeight - 1 do
    begin
        blockread(fd, image.img_ptr^[(img_meta.biHeight - 1 - current_row) * image.width], counter);
    end;

    close(fd);

end;

(***********************************************************)

procedure xDrawBMP(var image : TImage);
var
    counter : word;
begin
    for counter := 0 to image.size do
        mem[VGA_SEGMENT:counter] := image.img_ptr^[counter];
end;

(***********************************************************)

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

(***********************************************************)

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

(***********************************************************)

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

(***********************************************************)

procedure xDrawLineDiag(x_start, y_start, x_end, y_end : word; color : byte);
var
    current_x, current_y : word;
    sign : shortint;
    tmp : word;
    ratio : word;
begin
    if y_start = y_end then
    begin
        xDrawLineHorz(x_start, x_end, y_start, color);
        exit;
    end;

    { Zamien wspolrzedne jesli x_start > x_end }
    if x_start > x_end then
    begin
        tmp := x_end;
        x_end := x_start;
        x_start := tmp;
        tmp := y_end;
        y_end := y_start;
        y_start := tmp;
    end;

    if y_start > y_end then
    begin
        sign := 1;
        ratio := y_start - y_end;
    end
    else
    begin
        sign := -1;
        ratio := y_end - y_start;
    end;

    xDrawPixel(x_start, y_start, color);
    xDrawPixel(x_end, y_end, color);

    current_y := y_start;

    for current_x := x_start + 1 to x_end do
    begin
        xDrawPixel(current_x, current_y, color);
        if (current_x mod ratio) <> 0 then
            current_y := current_y + sign;
    end;
end;

(***********************************************************)

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

(***********************************************************)

procedure xDrawSquare(x, y, len : word; color: byte; fill_color : boolean);
begin
    xDrawRectangle(x, y, len, len, color, fill_color);
end;

(***********************************************************)

procedure xDrawCircle(x_start, y_start, radius : word; color: byte; fill_color : boolean);
var
    x, y : word;
    d : integer;
begin
    x := 0;
    y := radius;
    d := 3 - 2 * radius;

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
        for y := 0 to radius do
        begin
            x := Round(Sqrt(radius * radius - y * y));
            xDrawLineHorz(x_start - x, x_start + x, y_start + y, color);
            xDrawLineHorz(x_start - x, x_start + x, y_start - y, color);
        end;
    end;
end;

(***********************************************************)

(*
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
*)

(***********************************************************)

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

procedure xCreateBuffer(var buffer_ptr : pointer);
var
    _free_mem : longint;
begin
    { Sprawdzamy czy system posiada wystarczajaco duzo wolnej pamieci }
    _free_mem := maxavail;
    if(_free_mem < MAX_BUFFER_SIZE) then exit;

    getmem(buffer_ptr, MAX_BUFFER_SIZE);
end;

(***********************************************************)

procedure xFreeBuffer(var buffer_ptr : pointer);
begin
    freemem(buffer_ptr, MAX_BUFFER_SIZE);
end;

(***********************************************************)

procedure xCopyBuffer(target, source : pointer);
begin
    asm
        push ds
        lds si, source
        les di, target
        mov cx, 32000
        cld
        rep movsw
        pop ds
    end;
end;

(***********************************************************)

procedure xFillBuffer(buffer_ptr : pointer; color : byte);
begin
    asm
        les di, buffer_ptr
        mov cx, 32000
        mov ah, color
        mov al, ah
        cld
        rep stosw
    end;
end;

(***********************************************************)

procedure xWaitForVertRetrace;
begin
    asm
        mov dx, 3dah

        @inProgress:
        in  al, dx
        test al, 00001000b
        jnz @inProgress

        @noRetrace:
        in al, dx
        test al, 00001000b
        jz @noRetrace
    end;
end;

(***********************************************************)

end.
