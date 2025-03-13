program mouse;

uses crt, xvga256, xmouse;

BEGIN
   clrscr;

   { Sprawdzaj czy mysz jest zainstalowana }
   if not (xInitMouse) then
   begin
        writeln('Mouse does not exist!');
        readln;
        halt;
   end;

   xSetVGAMode;                  { Ustaw tryb VGA }
   xShowMouse;                   { Pokaz kursor myszy }
   xSetMouseSpeed(10,10);        { Ustaw predkosc myszy }
   xSetMouseArea(0,150,0,100);   { Ustaw obszar ekranu dla ruchu kursora myszy }

   while (True) do
   begin
      xMouseUpdate; { Sprawdzaj status myszy }

      if(MOUSE_LEFT) then
      begin
         xDrawPixel(MOUSE_X div 2, MOUSE_Y, random(256)); { Rysuj piksel o losowym kolorze }
         {xResetMouse;}
      end;

      if(MOUSE_RIGHT) then
      begin
         xHideMouse; { Ukryj kursor myszy }
         break;
      end;

   end;

   xSetTXTMode; { Wyjdz z trybu graficznego }
   clrscr;
   readln;
END.