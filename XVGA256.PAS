unit xVGA256;

{$G+}  { Zezwol na instrukcje 286 }

(*******************************************************************)
(** //                  XENGINE VGA Unit                       // **)
(** //  (C) 2025-2026 Coded by Adam Kozinski & Dominik Galoch  // **)
(** ///////////////////////////////////////////////////////////// **)
(*******************************************************************)

interface

uses crt, xfiles;

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
                    bfType          : word;     { Typ pliku (musi byc 'BM' = 0x4D42) }
                    bfSize          : longint;  { Calkowity rozmiar pliku (w bajtach) }
                    bfRes1          : word;     { Zarezerwowane (zwykle 0) }
                    bfRes2          : word;     { Zarezerwowane (zwykle 0) }
                    bfOffBits       : longint;  { Przesuniecie od poczatku pliku do danych obrazu }
                    biSize          : longint;  { Rozmiar tego naglowka (zwykle 40 bajtow) }
                    biWidth         : longint;  { Szerokosc obrazu w pikselach }
                    biHeight        : longint;  { Wysokosc obrazu w pikselach }
                    biPlanes        : word;     { Liczba plaszczyzn (zwykle 1) }
                    biBitCount      : word;     { Liczba bitow na piksel (dla 256 kolorow to 8) }
                    biCompression   : longint;  { Typ kompresji (zwykle 0 - brak kompresji) }
                    biSizeImage     : longint;  { Rozmiar danych obrazu }
                    biXPelsPerMeter : longint;  { Rozdzielczosc pozioma (w pikselach na metr) }
                    biYPelsPerMeter : longint;  { Rozdzielczosc pionowa (w pikselach na metr) }
                    biClrUsed       : longint;  { Liczba uzywanych kolorow (256 dla 256 kolorow) }
                    biClrImportant  : longint;  { Liczba waznych kolorow (mozna ustawic na 0) }
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
procedure xLoadBitmapPalPkg(package_name, internal_name : string);                            { Pobierz palete BMP z paczki }
procedure xSavePalFile(filename : string; pal : VGAPalette);                                       { Zapisz palete do pliku }
procedure xLoadPalFile(filename : string; pal : VGAPalette);                                       { Wczytaj palete z pliku }
procedure xGetColor(color_nr : byte; var color : TPalette);                                        { Pobierz wzorzec koloru }
procedure xLoadBitmap(var image : TImage; filename : string);                                             { Wczytaj bitmape }
procedure xLoadBitmapPkg(package_name, internal_name : string; var image : TImage);              { Wczytaj bitmape z paczki }
procedure xFreeImage(var image : TImage);                                                          { Zwolnij pamiec bitmapy }
procedure xSaveBitmap(filename : string);                                                                  { Zapisz bitmape }
procedure xDrawBitmap(buffer_ptr : pointer; x, y : word; image : TImage; transparent : boolean);            { Rysuj bitmape }
procedure xScaleBitmap(original : TImage; var scaled : TImage; new_width, new_height : word);              { Skaluj bitmape }
procedure xRotateBitmap(original : TImage; var rotated : TImage; angle : real);                             { Obroc bitmape }
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

procedure xSetColor(color_nr : byte; r, g, b : byte); assembler;
asm
    mov  dx, 03C8h
    mov  al, color_nr
    out  dx, al
    
    inc  dx
    mov  al, r
    out  dx, al
    mov  al, g
    out  dx, al
    mov  al, b
    out  dx, al
end;

(***********************************************************)

procedure xGetPaletteVGA(var pal : VGAPalette); assembler;
asm
    mov  dx, 03C7h
    xor  al, al
    out  dx, al
    
    les  di, pal
    mov  dx, 03C9h
    mov  cx, 256 * 3
    cld
    
@read_loop:
    in   al, dx
    stosb
    loop @read_loop
end;

(***********************************************************)

procedure xSetPaletteVGA(pal : VGAPalette); assembler;
asm
    mov  dx, 03C8h
    xor  al, al
    out  dx, al
    
    lds  si, pal
    mov  dx, 03C9h
    mov  cx, 256 * 3
    cld
    
@write_loop:
    lodsb
    out  dx, al
    loop @write_loop
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

    asm
        mov  dx, 03C8h
        xor  al, al
        out  dx, al
        
        lea  si, bmp_palette
        mov  dx, 03C9h
        xor  cx, cx
        
    @pal_loop:
        mov  al, [si+2]
        shr  al, 2
        out  dx, al
        mov  al, [si+1]
        shr  al, 2
        out  dx, al
        mov  al, [si]
        shr  al, 2
        out  dx, al
        
        add  si, 4
        inc  cx
        cmp  cx, 256
        jb   @pal_loop
    end;

    close(fd);
end;

(***********************************************************)

procedure xLoadBitmapPalPkg(package_name, internal_name : string);
var
    fd              : file;
    success         : boolean;
    file_size       : longint;
    palette_size    : word;
begin
    xOpenPakFile(package_name, internal_name, fd, file_size, success);
    if not success then exit;

    seek(fd, FilePos(fd) + sizeof(THandleBMP));
    palette_size := sizeof(bmp_palette);
    blockread(fd, bmp_palette, palette_size);

    asm
        mov  dx, 03C8h
        xor  al, al
        out  dx, al
        
        lea  si, bmp_palette
        mov  dx, 03C9h
        xor  cx, cx
        
    @pal_loop:
        mov  al, [si+2]
        shr  al, 2
        out  dx, al
        mov  al, [si+1]
        shr  al, 2
        out  dx, al
        mov  al, [si]
        shr  al, 2
        out  dx, al
        
        add  si, 4
        inc  cx
        cmp  cx, 256
        jb   @pal_loop
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

procedure xGetColor(color_nr : byte; var color : TPalette); assembler;
asm
    mov  dx, 03C7h
    mov  al, color_nr
    out  dx, al
    
    les  di, color
    mov  dx, 03C9h
    
    in   al, dx
    stosb
    in   al, dx
    stosb
    in   al, dx
    stosb
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

    seek(fd, img_meta.bfOffBits);

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
        blockread(fd, image.img_ptr^[(img_meta.biHeight - 1 - current_row) * image.width], counter);

    close(fd);
end;

(***********************************************************)

procedure xLoadBitmapPkg(package_name, internal_name : string; var image : TImage);
var
    fd           : file;
    success      : boolean;
    file_size    : longint;
    img_meta     : THandleBMP;
    counter      : word;
    current_row  : word;
begin
    xOpenPakFile(package_name, internal_name, fd, file_size, success);
    if not success then exit;

    counter := sizeof(THandleBMP);
    blockread(fd, img_meta, counter);
    if counter <> sizeof(THandleBMP) then
    begin
        close(fd);
        exit;
    end;

    if img_meta.bfType <> $4D42 then
    begin
        close(fd);
        exit;
    end;

    if((img_meta.biWidth > SCREEN_WIDTH) or (img_meta.biHeight > SCREEN_HEIGHT)) then
    begin
        close(fd);
        exit;
    end;

    seek(fd, FilePos(fd) + (img_meta.bfOffBits - sizeof(THandleBMP)));

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
        blockread(fd, image.img_ptr^[(img_meta.biHeight - 1 - current_row) * image.width], counter);

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
    row, i      : word;
begin
    with bmp_header do
    begin
        bfType := $4D42;
        bfSize := sizeof(THandleBMP) + sizeof(bmp_pal) + (SCREEN_WIDTH * SCREEN_HEIGHT);
        bfRes1 := 0;
        bfRes2 := 0;
        bfOffBits := sizeof(THandleBMP) + sizeof(bmp_pal);
        biSize := 40;
        biWidth := SCREEN_WIDTH;
        biHeight := SCREEN_HEIGHT;
        biPlanes := 1;
        biBitCount := 8;
        biCompression := 0;
        biSizeImage := SCREEN_WIDTH * SCREEN_HEIGHT;
        biXPelsPerMeter := 0;
        biYPelsPerMeter := 0;
        biClrUsed := 256;
        biClrImportant := 0;
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

procedure xDrawBitmap(buffer_ptr : pointer; x, y : word; image : TImage; transparent : boolean); assembler;
asm
    mov  ax, x
    cmp  ax, SCREEN_WIDTH
    jae  @Exit
    
    mov  ax, y
    cmp  ax, SCREEN_HEIGHT
    jae  @Exit
    
    les  di, image
    mov  ax, es:[di].TImage.width
    add  ax, x
    cmp  ax, SCREEN_WIDTH
    ja   @Exit
    
    mov  ax, es:[di].TImage.height
    add  ax, y
    cmp  ax, SCREEN_HEIGHT
    ja   @Exit
    
    mov  ax, y
    mov  dx, SCREEN_WIDTH
    mul  dx
    add  ax, x
    mov  bx, ax
    
    push ds
    lds  si, image
    mov  cx, [si].TImage.width
    mov  dx, [si].TImage.height
    lds  si, [si].TImage.img_ptr
    
    les  di, buffer_ptr
    add  di, bx
    
    cmp  transparent, 0
    je   @NonTransparent
    
@TransparentLoop:
    push cx
    
@RowLoopTransparent:
    lodsb
    test al, al
    je   @SkipPixel
    stosb
    jmp  @NextPixel
    
@SkipPixel:
    inc  di
    
@NextPixel:
    loop @RowLoopTransparent
    
    pop  cx
    add  di, SCREEN_WIDTH
    sub  di, cx
    
    dec  dx
    jnz  @TransparentLoop
    jmp  @Done
    
@NonTransparent:
    push cx
    
@RowLoop:
    rep  movsb
    
    pop  cx
    add  di, SCREEN_WIDTH
    sub  di, cx
    
    dec  dx
    jnz  @NonTransparent
    
@Done:
    pop  ds
    
@Exit:
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

procedure xRotateBitmap(original : TImage; var rotated : TImage; angle : real);
var
    cos_theta, sin_theta    : real;
    new_width, new_height   : word;
    x, y                    : integer;
    cx, cy, new_cx, new_cy  : real;
    i, j                    : word;
begin
    angle := angle * pi / 180.0;
    cos_theta := cos(angle);
    sin_theta := sin(angle);
    
    new_width := round(abs(original.width * cos_theta) + abs(original.height * sin_theta));
    new_height := round(abs(original.width * sin_theta) + abs(original.height * cos_theta));
    
    rotated.width := new_width;
    rotated.height := new_height;
    rotated.size := new_width * new_height;
    getmem(rotated.img_ptr, rotated.size);
    
    cx := original.width / 2.0;
    cy := original.height / 2.0;
    new_cx := new_width / 2.0;
    new_cy := new_height / 2.0;
    
    for j := 0 to new_height - 1 do
        for i := 0 to new_width - 1 do
        begin
            x := round((i - new_cx) * cos_theta + (j - new_cy) * sin_theta + cx);
            y := round(-(i - new_cx) * sin_theta + (j - new_cy) * cos_theta + cy);
            
            if (x >= 0) and (x < original.width) and (y >= 0) and (y < original.height) then
                rotated.img_ptr^[j * new_width + i] := original.img_ptr^[y * original.width + x]
            else
                rotated.img_ptr^[j * new_width + i] := 0;
        end;
end;

(***********************************************************)

procedure xDrawPixel(buffer_ptr : pointer; x, y : word; color : byte); assembler;
asm
    les  di, buffer_ptr
    mov  ax, y
    mov  bx, ax
    shl  ax, 8
    shl  bx, 6
    add  bx, ax
    add  bx, x
    mov  al, color
    mov  es:[bx], al
end;

(***********************************************************)

procedure xDrawLineHorz(buffer_ptr : pointer; x_start, x_end, y : word; color : byte); assembler;
asm
    les  di, buffer_ptr
    mov  ax, y
    mov  bx, ax
    shl  ax, 8
    shl  bx, 6
    add  bx, ax
    add  bx, x_start
    add  di, bx
    mov  cx, x_end
    sub  cx, x_start
    inc  cx
    mov  al, color
    cld
    rep  stosb
end;

(***********************************************************)

procedure xDrawLineVert(buffer_ptr : pointer; x, y_start, y_end : word; color : byte); assembler;
asm
    les  di, buffer_ptr
    mov  ax, y_start
    mov  bx, ax
    shl  ax, 8
    shl  bx, 6
    add  bx, ax
    add  bx, x
    add  di, bx
    mov  cx, y_end
    sub  cx, y_start
    inc  cx
    mov  al, color

@draw_line_loop:
    mov  es:[di], al
    add  di, 320
    loop @draw_line_loop
end;

(***********************************************************)

procedure xDrawLineDiag(buffer_ptr : pointer; x_start, y_start, x_end, y_end : word; color : byte);
var
    dx, dy, steps, i : integer;
    x, y : real;
    xInc, yInc : real;
begin
    dx := x_end - x_start;
    dy := y_end - y_start;
    if abs(dx) > abs(dy) then steps := abs(dx) else steps := abs(dy);
    if steps = 0 then exit;
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
    asm
        mov  dx, 03C8h
        xor  al, al
        out  dx, al
        mov  dx, 03C9h
        mov  cx, 256 * 3
    @clear:
        xor  al, al
        out  dx, al
        loop @clear
    end;
    
    for idx2 := 0 to 63 do
    begin
        xWaitForVertRetrace;

        for idx1 := 0 to 255 do
        begin
            xGetColor(idx1, color);

            if(color.red < pal[idx1].red) then inc(color.red);
            if(color.green < pal[idx1].green) then inc(color.green);
            if(color.blue < pal[idx1].blue) then inc(color.blue);

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

procedure xCreateBuffer(var buffer_ptr : pointer);
var
    _free_mem : longint;
begin
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

procedure xCopyBuffer(source, target : pointer); assembler;
asm
    push ds
    lds  si, source
    les  di, target
    mov  cx, 32000
    cld
    rep  movsw
    pop  ds
end;

(***********************************************************)

procedure xClearScreen(buffer_ptr : pointer; color : byte); assembler;
asm
    les  di, buffer_ptr
    mov  cx, 32000
    mov  ah, color
    mov  al, ah
    cld
    rep  stosw
end;

(***********************************************************)

procedure xWaitForVertRetrace; assembler;
asm
    mov  dx, 03DAh

@inProgress:
    in   al, dx
    test al, 00001000b
    jnz  @inProgress

@noRetrace:
    in   al, dx
    test al, 00001000b
    jz   @noRetrace
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
begin
    change_x := 0;
    change_y := 0;
    _buffer_ptr := img.img_ptr;
    transparent_color := 0;

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
                les  di, buffer_ptr
                add  di, start_buffer
                lds  si, _buffer_ptr
                add  si, start_source
                mov  cx, _width
                mov  bl, transparent_color
                cld
            @copy_loop:
                lodsb
                cmp  al, bl
                je   @skip_pixel
                mov  es:[di], al
            @skip_pixel:
                inc  di
                loop @copy_loop
                pop  ds
            end;
        end
        else
        begin
            asm
                push ds
                les  di, buffer_ptr
                add  di, start_buffer
                lds  si, _buffer_ptr
                add  si, start_source
                mov  cx, _width
                cld
                rep  movsb
                pop  ds
            end;
        end;
        start_source := start_source + jump_source;
        start_buffer := start_buffer + jump_buffer;
    end;
end;

(***********************************************************)

end.
