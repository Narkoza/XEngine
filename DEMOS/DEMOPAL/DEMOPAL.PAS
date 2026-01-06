program demopal;

uses crt, xvga256;

var
   licznik : word;

BEGIN
   clrscr;
   xSetVGAMode;

   { umieszczenie 64 odcieni koloru siwego we wzorcach koloru 0 - 63 }
   for licznik := 0 to 63 do
   begin
      xSetColor(licznik, licznik, licznik, licznik);
   end; {koniec petli for}

   { umieszczenie 64 odcieni koloru czerwonego we wzorcach koloru 64 - 127 }
   for licznik := 0 to 63 do
   begin
      xSetColor(64 + licznik, licznik, 0, 0);
   end; {koniec petli for}

   { umieszczenie 64 odcieni koloru zielonego we wzorcach koloru 128 - 191 }
   for licznik := 0 to 63 do
   begin
      xSetColor(128 + licznik, 0, licznik, 0);
   end; {koniec petli for}

   { umieszczenie 64 odcieni koloru niebieskiego we wzorcach koloru 192 - 255 }
   for licznik := 0 to 63 do
   begin
      xSetColor(192 + licznik, 0, 0, licznik);
   end; {koniec petli for}

   for licznik := 0 to 255 do
   begin
      xDrawLineVert(Ptr(VGA_SEGMENT, 0), licznik, 0, 199, licznik);
   end;

   readln;
   xSetTxtMode;
END.