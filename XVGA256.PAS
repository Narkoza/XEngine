unit xVGA256;

{$G+}  { Zezwol na instrukcje 286 }

(**************************************************************)
(** //                 XENGINE VGA Unit                   // **)
(** //  (C) 2025 Coded by Adam Kozinski & Dominik Galoch  // **)
(** //////////////////////////////////////////////////////// **)
(**************************************************************)

interface

uses crt;

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

    TRectangle = record
                    x : integer;
                    y : integer;
                    width : integer;
                    height : integer;
                 end;

    VGAPalette = array[0..255] of TPalette;

var
    bmp_palette : array[0..255] of TPaletteBMP;
    buffer_ptr  : pointer;

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

procedure xSetVGAMode;                                                                       { Ustaw tryb 13h, 320x200x256c }
procedure xSetTxtMode;                                                                                { Ustaw tryb tekstowy }
procedure xSetColor(color_nr : byte; r, g, b : byte);                                                { Ustaw wzorzec koloru }
procedure xGetPaletteVGA(var pal : VGAPalette);                                                        { Pobierz palete VGA }
procedure xSetPaletteVGA(pal : VGAPalette);                                                             { Zapisz palete VGA }
procedure xLoadPaletteBMP(filename : string);                                                          { Pobierz palete BMP }
procedure xSavePalFile(filename : string; pal : VGAPalette);                                       { Zapisz palete do pliku }
procedure xLoadPalFile(filename : string; pal : VGAPalette);                                       { Wczytaj palete z pliku }
procedure xGetColor(color_nr : byte; var color : TPalette);                                        { Pobierz wzorzec koloru }
procedure xLoadBitmap(var image : TImage; filename : string);                                             { Wczytaj bitmape }
procedure xFreeImage(var image : TImage);                                                          { Zwolnij pamiec bitmapy }
procedure xSaveBitmap(filename : string);                                                                  { Zapisz bitmape }
procedure xDrawBitmap(buffer_ptr : pointer; x, y : word; image : TImage; transparent : boolean);            { Rysuj bitmape }
procedure xScaleBitmap(original : TImage; var scaled : TImage; new_width, new_height : word);              { Skaluj bitmape }
procedure xDrawPixel(buffer_ptr : pointer; x, y : word; color : byte);                                       { Rysuj piksel }
procedure xDrawLineHorz(buffer_ptr : pointer; x_start, x_end, y : word; color : byte);                { Rysuj linie pozioma }
procedure xDrawLineVert(buffer_ptr : pointer; x, y_start, y_end : word; color : byte);                { Rysuj linie pionowa }
procedure xDrawLineDiag(buffer_ptr : pointer; x_start, y_start, x_end, y_end : word; color : byte);    { Rysuj linie ukosna }
procedure xDrawRect(buffer_ptr : pointer; x1, y1, width, height : word; color : byte; fill : boolean);    { Rysuj prostokat }
procedure xDrawSquare(buffer_ptr : pointer; x, y, len : word; color : byte; fill_color : boolean);          { Rysuj kwadrat }
procedure xDrawCircle(buffer_ptr : pointer; x_start, y_start, radius : word; color : byte; fill : boolean);    { Rysuj kolo }
procedure xFadeOut(time : byte);                                                                              { Wygas ekran }
procedure xFadeIn(var pal : VGAPalette; time : byte);                                                     { Rozjasnij ekran }
procedure xMeltScreen(buffer_ptr : pointer; color : byte);                                             { Roztapianie ekranu }
procedure xFloodScreen(buffer_ptr : pointer; color, time : byte);                                      { Zalej ekran ciecza }
procedure xScreenOff(buffer_ptr : pointer; color1, color2 : byte; time : integer);                 { Wygas ekran (Efekt TV) }
procedure xCreateBuffer(var buffer_ptr : pointer);                                    { Zaalokuj pamiec dla drugiego bufora }
procedure xFreeBuffer(var buffer_ptr : pointer);                                           { Zwolnij pamiec drugiego bufora }
procedure xCopyBuffer(source, target : pointer);                                           { Kopiuj bufor ze zrodla do celu }
procedure xClearScreen(buffer_ptr : pointer; color : byte);                                        { Wypelnij ekran kolorem }
procedure xWaitForVertRetrace;                                                               { Czekaj na powrot pionowy CRT }
procedure xCopyImageArea(buffer_ptr : pointer; source, target : TRectangle;                          { Kopiuj obszar obrazu }
                                      img : TImage; transparent : boolean);

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

procedure xSavePalFile(filename : string; pal : VGAPalette);
var
    fd : file of VGAPalette;
begin
    assign(fd, filename);
    rewrite(fd);
    write(fd, pal);
    close(fd);
end;

(***********************************************************)

procedure xLoadPalFile(filename : string; pal : VGAPalette);
var
    fd : file of VGAPalette;
begin
    assign(fd, filename);
    reset(fd);
    read(fd, pal);
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

procedure xLoadBitmap(var image : TImage; filename : string);
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

procedure xFreeImage(var image : TImage);
begin
    if image.img_ptr <> nil then
    begin
        freemem(image.img_ptr, image.size);
        image.img_ptr := nil;
    end;
end;

(***********************************************************)

procedure xSaveBitmap(filename : string);
var
    fd          : file;
    bmp_header  : THandleBMP;
    palette     : VGAPalette;
    bmp_pal     : array[0..255] of TPaletteBMP;
    row_data    : array[0..SCREEN_WIDTH-1] of byte;
    row         : word;
    i           : word;
begin
    with bmp_header do
    begin
        bfType          := $4D42;
        bfSize          := sizeof(THandleBMP) + sizeof(bmp_pal) + (SCREEN_WIDTH * SCREEN_HEIGHT);
        bfRes1          := 0;
        bfRes2          := 0;
        bfOffBits       := sizeof(THandleBMP) + sizeof(bmp_pal);
        biSize          := 40;
        biWidth         := SCREEN_WIDTH;
        biHeight        := SCREEN_HEIGHT;
        biPlanes        := 1;
        biBitCount      := 8;
        biCompression   := 0;
        biSizeImage     := SCREEN_WIDTH * SCREEN_HEIGHT;
        biXPelsPerMeter := 0;
        biYPelsPerMeter := 0;
        biClrUsed       := 256;
        biClrImportant  := 0;
    end;

    xGetPaletteVGA(palette);

    for i := 0 to 255 do
    begin
        bmp_pal[i].blue := palette[i].blue shl 2;
        bmp_pal[i].green := palette[i].green shl 2;
        bmp_pal[i].red := palette[i].red shl 2;
        bmp_pal[i].reserved := 0;
    end;

    assign(fd, filename);
    rewrite(fd, 1);

    blockwrite(fd, bmp_header, sizeof(THandleBMP));
    blockwrite(fd, bmp_pal, sizeof(bmp_pal));

    for row := 0 to SCREEN_HEIGHT - 1 do
    begin
        for i := 0 to SCREEN_WIDTH - 1 do
            row_data[i] := mem[VGA_SEGMENT:((SCREEN_HEIGHT - 1 - row) * SCREEN_WIDTH) + i];

        blockwrite(fd, row_data, SCREEN_WIDTH);
    end;

    close(fd);
end;

(***********************************************************)

procedure xDrawBitmap(buffer_ptr : pointer; x, y : word; image : TImage; transparent : boolean);
var
    counter             : word;
    buffer_offset       : word;
    pixel               : byte;
    transparent_color   : byte;
begin
    if (x >= SCREEN_WIDTH) or (y >= SCREEN_HEIGHT) or
    (x + image.width > SCREEN_WIDTH) or (y + image.height > SCREEN_HEIGHT) then exit;

    transparent_color := 0;  { Indeks 0 jako kolor przezroczysty }
    buffer_offset := y * SCREEN_WIDTH + x;

    for counter := 0 to image.size - 1 do
    begin
        pixel := image.img_ptr^[counter];
        if not transparent or (pixel <> transparent_color) then
            mem[seg(buffer_ptr^):buffer_offset + ofs(buffer_ptr^)] := pixel;
            inc(buffer_offset);
        if (counter mod image.width) = image.width - 1 then
            inc(buffer_offset, SCREEN_WIDTH - image.width);
    end;
end;

(***********************************************************)

procedure xScaleBitmap(original : TImage; var scaled : TImage; new_width, new_height : word);
var
    x_ratio, y_ratio    : real;
    x, y, src_x, src_y  : word;
begin
    x_ratio := original.width / new_width;
    y_ratio := original.height / new_height;

    scaled.width := new_width;
    scaled.height := new_height;
    scaled.size := new_width * new_height;
    getmem(scaled.img_ptr, scaled.size);

    for y := 0 to new_height - 1 do
        for x := 0 to new_width - 1 do
        begin
            src_x := round(x * x_ratio);
            src_y := round(y * y_ratio);
            if (src_x < original.width) and (src_y < original.height) then
                scaled.img_ptr^[y * new_width + x] := original.img_ptr^[src_y * original.width + src_x]
            else
                scaled.img_ptr^[y * new_width + x] := 0;
        end;
end;

(***********************************************************)

procedure xDrawPixel(buffer_ptr : pointer; x, y : word; color : byte);
begin
    asm
        les di, buffer_ptr       { Zaladuj segment i offset bufora do ES:DI }
        mov ax, y
        mov bx, ax
        shl ax, 8                { y * 256 }
        shl bx, 6                { y * 64 }
        add bx, ax               { y * (256 + 64) = y * 320 }
        add bx, x                { y * 320 + x }
        mov al, color
        mov byte ptr es:[bx], al { Zapisz kolor w buforze }
    end;
end;

(***********************************************************)

procedure xDrawLineHorz(buffer_ptr : pointer; x_start, x_end, y : word; color : byte);
begin
    asm
        les di, buffer_ptr       { Zaladuj segment i offset bufora do ES:DI }
        mov ax, y
        mov bx, ax
        shl ax, 8                { y * 256 }
        shl bx, 6                { y * 64 }
        add bx, ax               { y * 320 }
        add bx, x_start          { y * 320 + x_start }
        add di, bx               { DI = DI + (y * 320 + x_start) }
        mov cx, x_end
        sub cx, x_start
        add cx, 1                { CX = x_end - x_start + 1 }
        mov al, color
        cld
        rep stosb                { Wypelnij linie kolorem }
    end;
end;

(***********************************************************)

procedure xDrawLineVert(buffer_ptr : pointer; x, y_start, y_end : word; color : byte);
begin
    asm
        les di, buffer_ptr       { Zaladuj segment i offset bufora do ES:DI }
        mov ax, y_start
        mov bx, ax
        shl ax, 8                { y_start * 256 }
        shl bx, 6                { y_start * 64 }
        add bx, ax               { y_start * 320 }
        add bx, x                { y_start * 320 + x }
        add di, bx               { DI = poczatkowy offset w buforze }
        mov cx, y_end
        sub cx, y_start
        add cx, 1                { CX = liczba pikseli do narysowania }
        mov al, color            { Zaladuj kolor do AL }

        @draw_line_loop:
        mov es:[di], al          { Zapisz kolor w buforze }
        add di, 320              { Przesun do nastepnego wiersza }
        loop @draw_line_loop     { Powtarzaj dla kazdego piksela }
    end;
end;

(***********************************************************)

procedure xDrawLineDiag(buffer_ptr : pointer; x_start, y_start, x_end, y_end : word; color : byte);
var
    dx, dy, steps, i : integer;
    x, y, xInc, yInc : real;
begin
    dx := x_end - x_start;
    dy := y_end - y_start;
    if abs(dx) > abs(dy) then steps := abs(dx) else steps := abs(dy);
    xInc := dx / steps;
    yInc := dy / steps;
    x := x_start;
    y := y_start;
    for i := 0 to steps do
    begin
        xDrawPixel(buffer_ptr, round(x), round(y), color);
        x := x + xInc;
        y := y + yInc;
    end;
end;

(***********************************************************)

procedure xDrawRect(buffer_ptr : pointer; x1, y1, width, height : word; color : byte; fill : boolean);
var
    y : word;
begin
    if fill then
    begin
        for y := y1 to y1 + height - 1 do
            xDrawLineHorz(buffer_ptr, x1, x1 + width - 1, y, color);
    end
    else
    begin
        xDrawLineHorz(buffer_ptr, x1, x1 + width - 1, y1, color);
        xDrawLineHorz(buffer_ptr, x1, x1 + width - 1, y1 + height - 1, color);
        xDrawLineVert(buffer_ptr, x1, y1, y1 + height - 1, color);
        xDrawLineVert(buffer_ptr, x1 + width - 1, y1, y1 + height - 1, color);
    end;
end;

(***********************************************************)

procedure xDrawSquare(buffer_ptr : pointer; x, y, len : word; color : byte; fill_color : boolean);
begin
    xDrawRect(buffer_ptr, x, y, len, len, color, fill_color);
end;

(***********************************************************)

procedure xDrawCircle(buffer_ptr : pointer; x_start, y_start, radius : word; color : byte; fill : boolean);
var
    x, y, d : integer;
begin
    x := 0;
    y := radius;
    d := 3 - 2 * radius;
    while x <= y do
    begin
        if fill then
        begin
            xDrawLineHorz(buffer_ptr, x_start - x, x_start + x, y_start + y, color);
            xDrawLineHorz(buffer_ptr, x_start - x, x_start + x, y_start - y, color);
            xDrawLineHorz(buffer_ptr, x_start - y, x_start + y, y_start + x, color);
            xDrawLineHorz(buffer_ptr, x_start - y, x_start + y, y_start - x, color);
        end
        else
        begin
            xDrawPixel(buffer_ptr, x_start + x, y_start + y, color);
            xDrawPixel(buffer_ptr, x_start - x, y_start + y, color);
            xDrawPixel(buffer_ptr, x_start + x, y_start - y, color);
            xDrawPixel(buffer_ptr, x_start - x, y_start - y, color);
            xDrawPixel(buffer_ptr, x_start + y, y_start + x, color);
            xDrawPixel(buffer_ptr, x_start - y, y_start + x, color);
            xDrawPixel(buffer_ptr, x_start + y, y_start - x, color);
            xDrawPixel(buffer_ptr, x_start - y, y_start - x, color);
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
end;

(***********************************************************)

procedure xFadeOut(time : byte);
var
    idx1, idx2  : byte;
    color       : TPalette;
begin
    for idx2 := 0 to 63 do
    begin
        xWaitForVertRetrace;

        for idx1 := 0 to 255 do
        begin

            xGetColor(idx1, color);

            if(color.red > 0) then dec(color.red);
            if(color.green > 0) then dec(color.green);
            if(color.blue > 0) then dec(color.blue);

            xSetColor(idx1, color.red, color.green, color.blue);

        end;

        if(time <> 0) then delay(time);
    end;
end;

(***********************************************************)

procedure xFadeIn(var pal : VGAPalette; time : byte);
var
    idx1, idx2  : byte;
    color       : TPalette;
begin
    port[$3C8] := 0;
    for idx1 := 0 to 255 do
    begin
        port[$3C9] := 0;
        port[$3C9] := 0;
        port[$3C9] := 0;
    end;

    for idx2 := 0 to 63 do
    begin
        xWaitForVertRetrace;

        for idx1 := 0 to 255 do
        begin
            xGetColor(idx1, color);

            if(color.red < pal[idx1].red) then
                inc(color.red);

            if(color.green < pal[idx1].green) then
                inc(color.green);

            if(color.blue < pal[idx1].blue) then
                inc(color.blue);

            xSetColor(idx1, color.red, color.green, color.blue);
        end;

        if(time <> 0) then delay(time);
    end;
end;

(***********************************************************)

procedure xMeltScreen(buffer_ptr : pointer; color : byte);
var
    idx : longint;
begin
    for idx := 0 to 800000 do
    begin
        xDrawPixel(buffer_ptr, random(320), random(200), color);
        if((idx mod 10000) = 0) then
        begin
            delay(2);
            xWaitForVertRetrace;
            xCopyBuffer(buffer_ptr, ptr(VGA_SEGMENT, 0));
        end;
    end;
end;

(***********************************************************)

procedure xFloodScreen(buffer_ptr : pointer; color, time : byte);
var
    line_pos_y      : array[0..319] of byte;
    fragment_size   : array[0..319] of byte;
    idx1, idx2      : word;
begin
    for idx1 := 0 to 319 do
    begin
        line_pos_y[idx1] := 0;
        fragment_size[idx1] := random(7) + 2;
    end;

    for idx1 := 0 to 99 do
    begin
        for idx2 := 0 to 319 do
        begin
            if(line_pos_y[idx2] + fragment_size[idx2] < 200) then
            begin
                xDrawLineVert(buffer_ptr, idx2, line_pos_y[idx2], line_pos_y[idx2] + fragment_size[idx2], color);
                inc(line_pos_y[idx2], fragment_size[idx2]);
            end else
            begin
                xDrawLineVert(buffer_ptr, idx2, line_pos_y[idx2], 199, color);
            end;
        end;

        xWaitForVertRetrace;
        xCopyBuffer(buffer_ptr, ptr(VGA_SEGMENT, 0));

        if(time <> 0) then delay(time);
    end;
end;

(***********************************************************)

procedure xScreenOff(buffer_ptr : pointer; color1, color2 : byte; time : integer);
var
    temp : VGAPalette;
    i    : word;
begin
    xGetPaletteVGA(temp);

    for i := 1 to SCREEN_HEIGHT div 2 do
    begin
        xWaitForVertRetrace;
        xDrawLineHorz(buffer_ptr, 0, SCREEN_WIDTH - 1, i - 1, color1);
        xDrawLineHorz(buffer_ptr, 0, SCREEN_WIDTH - 1, i, color2);
        xDrawLineHorz(buffer_ptr, 0, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1 - i, color2);
        xDrawLineHorz(buffer_ptr, 0, SCREEN_WIDTH - 1, SCREEN_HEIGHT - i, color1);
        if time > 0 then delay(time);
        xCopyBuffer(buffer_ptr, ptr(VGA_SEGMENT, 0));
    end;

    for i := 0 to (SCREEN_WIDTH div 2) - 2 do
    begin
        xWaitForVertRetrace;
        xDrawPixel(buffer_ptr, i, (SCREEN_HEIGHT div 2) - 1, color1);
        xDrawPixel(buffer_ptr, SCREEN_WIDTH - 1 - i, (SCREEN_HEIGHT div 2) - 1, color1);
        if time > 0 then delay(time);
        xCopyBuffer(buffer_ptr, ptr(VGA_SEGMENT, 0));
    end;

    xFadeOut(time * 5);

    i := (SCREEN_WIDTH div 2) - 1;
    xDrawPixel(buffer_ptr, i, (SCREEN_HEIGHT div 2) - 1, color1);
    xDrawPixel(buffer_ptr, SCREEN_WIDTH - 1 - i, (SCREEN_HEIGHT div 2) - 1, color1);
    xCopyBuffer(buffer_ptr, ptr(VGA_SEGMENT, 0));

    xSetPaletteVGA(temp);
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

procedure xCopyBuffer(source, target : pointer);
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

procedure xClearScreen(buffer_ptr : pointer; color : byte);
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

procedure xCopyImageArea(buffer_ptr : pointer; source, target : TRectangle; img : TImage; transparent : boolean);
var
    counter_y                   : word;
    start_source, start_buffer  : word;
    jump_source                 : word;
    jump_buffer                 : word;
    change_x, change_y          : word;
    _buffer_ptr                 : pointer;
    _width                      : integer;
    transparent_color           : byte;
    pixel                       : byte;
begin
    change_x := 0;
    change_y := 0;
    _buffer_ptr := img.img_ptr;
    transparent_color := 0; { Indeks 0 jako kolor przezroczysty }

    if(target.x > 319) then exit;
    if(target.y > 199) then exit;
    if(target.x + target.width <= 0) then exit;
    if(target.y + target.height <= 0) then exit;

    if(target.x < 0) then
    begin
        target.width := target.width + target.x;
        change_x := -target.x;
        target.x := 0;
    end;

    if(target.y < 0) then
    begin
        target.height := target.height + target.y;
        change_y  := -target.y;
        target.y := 0;
    end;

    if( (target.x + target.width) > 319) then target.width := 320 - target.x;
    if( (target.y + target.height) > 199) then target.height := 200 - target.y;

    start_source := source.x + change_x + ((source.y + change_y) * img.width);
    start_buffer := target.x + target.y * 320;

    jump_source := source.width;
    if (source.x > 0) then jump_source := jump_source + source.x;
    if (source.x + source.width <= img.width - 1) then
        jump_source := jump_source + img.width - (source.x + source.width);

    jump_buffer := target.width;
    if (target.x > 0 ) then jump_buffer := jump_buffer + target.x;
    if (target.x + target.width <= 319) then jump_buffer := jump_buffer + 320 - (target.x + target.width);

    _width := target.width;

    for counter_y := 0 to target.height - 1 do
    begin
        if transparent then
        begin
            asm
                push ds
                les di, buffer_ptr
                add di, start_buffer
                lds si, _buffer_ptr
                add si, start_source
                mov cx, _width
                mov bl, transparent_color
                cld
            @copy_loop:
                lodsb
                cmp al, bl
                je @skip_pixel
                mov es:[di], al
            @skip_pixel:
                inc di
                loop @copy_loop
                pop ds
            end;
        end
        else
        begin
            asm
                push ds
                les di, buffer_ptr
                add di, start_buffer
                lds si, _buffer_ptr
                add si, start_source
                mov cx, _width
                cld
                rep movsb
                pop ds
            end;
        end;
        start_source := start_source + jump_source;
        start_buffer := start_buffer + jump_buffer;
    end;
end;

(***********************************************************)

end.
