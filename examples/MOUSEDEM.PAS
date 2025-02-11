program mouse;

uses crt, xvga256, xmouse;

BEGIN
   clrscr;
   xSetVGAMode;   { Ustaw tryb VGA }
   xShowMouse;    { Pokaz kursor myszy }
   xSetMouseSpeed(10,10); { Ustaw predkosc myszy }

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