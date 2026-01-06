program imgtest;

uses crt, xvga256, xkeybrd;

var
   img          : TImage;
   pal          : VGAPalette;
   buffer_ptr   : pointer;

begin
  clrscr;
  xSetVGAMode;
  xKeyboardInit;
  xCreateBuffer(buffer_ptr);

  xLoadPaletteBMP('valley.bmp');
  xLoadBitmap(img, 'valley.bmp');
  xClearScreen(buffer_ptr, 4);

  xGetPaletteVGA(pal);           { Pobieranie palety }
  xFadeOut(1);                   { Wygaszanie ekranu }

  xDrawBitmap(buffer_ptr, 0, 0, img, FALSE);
  xWaitForVertRetrace;
  xCopyBuffer(buffer_ptr, ptr(VGA_SEGMENT, 0));

  xFadeIn(pal, 15);              { Rozjasnianie ekranu }

  { Glowna petla programu }
  while not key[KEY_ESC] do
  begin
    xClearScreen(buffer_ptr, 4);  { Czyszczenie bufora }
    xDrawBitmap(buffer_ptr, 0, 0, img, FALSE);
    xWaitForVertRetrace;
    xCopyBuffer(buffer_ptr, ptr(VGA_SEGMENT, 0));
  end;

  xFadeOut(20);
  {xMeltScreen(buffer_ptr, 0);}
  xDisableKeyboard;
  xFreeImage(img);
  xFreeBuffer(buffer_ptr);  { Zwolnienie bufora }
  xSetTxtMode;
end.