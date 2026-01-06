program mouse;

uses crt, xvga256, xmouse;

const
   MyArrowCursor : TCursor = (
      $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF,  { Maska AND - wiersz 1-8 }
      $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF,  { Maska AND - wiersz 9-16 }
      $8000, $C000, $8000, $0000, $0000, $0000, $0000, $0000,  { Maska XOR - wiersz 1-8 }
      $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000   { Maska XOR - wiersz 9-16 }
   );

BEGIN
   clrscr;

   { Sprawdzaj czy mysz jest zainstalowana }
   if not (xMouseInit) then
   begin
        writeln('ERROR: Mouse driver not found!');
        writeln('Please load a DOS mouse driver.');
        readln;
        halt;
   end;

   xSetVGAMode;                                 { Ustaw tryb VGA }
   {xSetMouseCursor(0,0,MyArrowCursor);}
   xShowMouse;                                  { Pokaz kursor myszy }
   xSetMouseSpeed(50,50);                       { Ustaw predkosc myszy }
   xSetMouseArea(0,319,0,199);                  { Ustaw obszar ekranu dla ruchu kursora myszy }
   xSetMousePosition((320 div 2) * 2, 200 div 2);     { Ustaw pozycje kursora myszy }

   while (True) do
   begin
      xMouseUpdate; { Sprawdzaj status myszy }

      if(MOUSE_LEFT) then
      begin
         xDrawPixel(ptr(VGA_SEGMENT, 0), MOUSE_X, MOUSE_Y, random(256)); { Rysuj piksel o losowym kolorze }
      end;

      if(MOUSE_MIDDLE) then
      begin
         xResetMouse;
      end;

      if(MOUSE_RIGHT) then
      begin
         xHideMouse; { Ukryj kursor myszy }
         break;
      end;

   end;

   xSetTxtMode; { Wyjdz z trybu graficznego }
   clrscr;
   readln;
END.