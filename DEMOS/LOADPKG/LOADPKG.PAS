program loadpkg;

uses crt, xvga256, xfont, xsound;

var
    image: TImage;
    wav: TWavData;
    key: char;
begin
    xSetVGAMode;
    xCreateBuffer(buffer_ptr);

    xLoadFontPkg('data.pak', 'font.bmp');
    xLoadBitmapPkg('data.pak', 'valley.bmp', image);
    xLoadBitmapPalPkg('data.pak', 'valley.bmp');
    xDrawBitmap(buffer_ptr, 0, 0, image, false);

    xText(buffer_ptr, 10, 10, 'Hello from Package!', 15);
    xCopyBuffer(buffer_ptr, ptr(VGA_SEGMENT, 0));

    if xSBDetect then
    begin
        xSBInit;
        xLoadSoundPkg('data.pak', 'test.wav', wav);
        xPlaySound(wav, 0);
    end;

repeat
      delay(10);
until keypressed;
key := readkey;

if xSBDetect then
begin
    xSBStop;
    xSBDeinit;
end;

xFreeImage(image);
xFreeBuffer(buffer_ptr);
xSetTxtMode;

end.