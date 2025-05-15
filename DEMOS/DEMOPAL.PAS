program demopal;

uses crt, xvga256;

var
   licznik : word;

BEGIN
   clrscr;
   xSetVGAMode;
   xLoadColorPalette;

   { umieszczenie 64 odcieni koloru siwego we wzorcach koloru 0 - 63 }
   port[$3c8] := 0;          { zapis rozpoczynamy od wzorca koloru o numerze 0 }

   for licznik := 0 to 63 do
   begin
      port[$3c9] := licznik;
      port[$3c9] := licznik;
      port[$3c9] := licznik;
   end; {koniec petli for}

   { umieszczenie 64 odcieni koloru czerwonego we wzorcach koloru 64 - 127 }
   port[$3c8] := 64;         { zapis rozpoczynamy od wzorca koloru o numerze 64 }

   for licznik := 0 to 63 do
   begin
      port[$3c9] := licznik;
      port[$3c9] := 0;
      port[$3c9] := 0;
   end; {koniec petli for}

   { umieszczenie 64 odcieni koloru zielonego we wzorcach koloru 128 - 191 }
   port[$3c8] := 128;       { zapis rozpoczynamy od wzorca koloru o numerze 128 }

   for licznik := 0 to 63 do
   begin
      port[$3c9] := 0;
      port[$3c9] := licznik;
      port[$3c9] := 0;
   end; {koniec petli for}

   { umieszczenie 64 odcieni koloru niebieskiego we wzorcach koloru 192 - 255 }
   port[$3c8] := 192;       { zapis rozpoczynamy od wzorca koloru o numerze 192 }

   for licznik := 0 to 63 do
   begin
      port[$3c9] := 0;
      port[$3c9] := 0;
      port[$3c9] := licznik;
   end; {koniec petli for}

   for licznik := 0 to 255 do
   begin
      xDrawLineVert(licznik, 0, 199, licznik);
   end;

   readln;
END.