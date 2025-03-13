unit xJoy;

(**************************************************************)
(** //              XENGINE Joystick Unit                 // **)
(** //  (C) 2025 Coded by Adam Kozinski & Dominik Galoch  // **)
(** //////////////////////////////////////////////////////// **)
(**************************************************************)

interface

const
    JOYSTICK_PORT = $201; { Definicja portu joysticka }

var
    JOY_LEFT, JOY_RIGHT, JOY_UP, JOY_DOWN,                           { Flagi kierunkow joysticka }
    JOY_BUTTON_1, JOY_BUTTON_2, JOY_BUTTON_PRESSED, JOY_WAITBUTTON,  { Flagi przyciskow }
    JOY_ENABLED, JOY_CALIBRATED : boolean;                           { Flagi stanu joysticka }

type TJoystick = record
                    X, Y, XLeft, XRight, YUp, YDown,                 { Pozycja joysticka }
                    XCenter, YCenter, XMin, XMax, YMin, YMax : Word; { Parametry kalibracji }
                end;

var
    Joy : TJoystick; { Zmienna przechowujaca stan joysticka }

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

procedure xJoyInit;      { Inicjalizacja joysticka }
procedure xJoyUpdate;    { Aktualizacja stanu joysticka }
procedure xJoyReset;     { Resetowanie joysticka }
procedure xJoyCalibrate; { Kalibracja joysticka }

{//////////////////////////////////////////////////////////}

implementation

(**********************************************************)

procedure xJoyInit;
begin
    JOY_ENABLED := TRUE; { Ustawienie flagi wlaczonego joysticka }
end;

(**********************************************************)

procedure xJoyUpdate;
begin
    Joy.X := 0; { Zerowanie pozycji X }
    Joy.Y := 0; { Zerowanie pozycji Y }

    if JOY_ENABLED then
    begin
        asm
            pushf
            xor cx, cx              { Zerowanie rejestru CX }
            mov dx, JOYSTICK_PORT   { Ustawienie portu joysticka }
            in  al, dx              { Odczyt z portu }
            not al
            mov ah, al
            and ax, 2010h           { Sprawdzanie przyciskow }
            mov JOY_BUTTON_1, al    { Zapisanie stanu przycisku 1 }
            shr ah, 1
            mov JOY_BUTTON_2, ah    { Zapisanie stanu przycisku 2 }
            mov bx, 0201h
            cli
            out dx, al              { Wyslanie danych do portu }
            mov ah, 0
        @@1:
            in   al, dx             { Odczyt danych joysticka }
            and  al, bl
            add  Joy.X, ax          { Zbieranie danych X }
            in   al, dx
            and  al, bh
            shr  al, 1
            add  Joy.Y, ax          { Zbieranie danych Y }
            in   al, dx
            test al, 3
            jz   @@2
            inc  cx
            jnz  @@1
            mov  JOY_ENABLED, 0     { Wylaczenie joysticka, jesli nie dziala }
        @@2:
            popf
        end;

        if JOY_ENABLED and (not JOY_WAITBUTTON) then
        begin
            { Sprawdzanie stanu kierunkow na podstawie wartosci X i Y }
            JOY_LEFT  := (Joy.X < Joy.XLeft);
            JOY_RIGHT := (Joy.X > Joy.XRight);
            JOY_UP    := (Joy.Y < Joy.YUp);
            JOY_DOWN  := (Joy.Y > Joy.YDown);
        end
        else
        begin
            { Wylaczenie kierunkow, gdy nie oczekujemy na przycisk }
            JOY_LEFT  := FALSE;
            JOY_RIGHT := FALSE;
            JOY_UP    := FALSE;
            JOY_DOWN  := FALSE;

            JOY_BUTTON_PRESSED := JOY_BUTTON_PRESSED or JOY_BUTTON_1 or JOY_BUTTON_2;
            JOY_BUTTON_1 := FALSE;
            JOY_BUTTON_2 := FALSE;
        end;
    end;
end;

(**********************************************************)

procedure xJoyReset;
var
    i : Integer;
    TotalX, TotalY : LongInt;
begin
    xJoyInit;   { Inicjalizacja joysticka }
    xJoyUpdate; { Aktualizacja stanu joysticka }

    if JOY_ENABLED then
    begin
        TotalX := 0; { Zerowanie sumy X }
        TotalY := 0; { Zerowanie sumy Y }

        for i := 1 to 16 do
        begin
            xJoyUpdate;         { Aktualizacja stanu joysticka }
            Inc(TotalX, Joy.X); { Dodawanie wartosci X do sumy }
            Inc(TotalY, Joy.Y); { Dodawanie wartosci Y do sumy }
        end;

        { Ustalanie srednich wartosci X i Y }
        Joy.X       := TotalX div 16;
        Joy.Y       := TotalY div 16;
        Joy.XCenter := Joy.X;
        Joy.YCenter := Joy.Y;
        Joy.XMin    := Joy.X;
        Joy.YMin    := Joy.Y;
        Joy.XMax    := Joy.X;
        Joy.YMax    := Joy.Y;
        Joy.XLeft   := Joy.X;
        Joy.YUp     := Joy.Y;
        Joy.XRight  := Joy.X;
        Joy.YUp     := Joy.Y;

        xJoyUpdate;
        JOY_CALIBRATED := FALSE; { Ustawienie flagi kalibracji na falsz }
    end;
end;

(**********************************************************)

procedure xJoyCalibrate;
begin
    xJoyUpdate; { Aktualizacja stanu joysticka }

    if JOY_ENABLED then
    begin
        { Sprawdzanie wartosci X i Y oraz aktualizacja minimalnych i maksymalnych }
        if Joy.X < Joy.XMin then
        begin
            Joy.XMin  := Joy.X;
            Joy.XLeft := (Joy.XMin + Joy.XCenter) div 2;
        end;

        if Joy.Y < Joy.YMin then
        begin
            Joy.YMin := Joy.Y;
            Joy.YUp  := (Joy.YMin + Joy.YCenter) div 2;
        end;

        if Joy.X > Joy.XMax then
        begin
            Joy.XMax   := Joy.X;
            Joy.XRight := (Joy.XMax + Joy.XCenter) div 2;
        end;

        if Joy.Y > Joy.YMax then
        begin
            Joy.YMax  := Joy.Y;
            Joy.YDown := (Joy.YMax + Joy.YCenter) div 2;
        end;

        JOY_CALIBRATED := TRUE; { Ustawienie flagi kalibracji na prawde }
    end;
end;

(**********************************************************)

BEGIN
    JOY_CALIBRATED := FALSE; { Ustawienie flagi kalibracji na falsz }
    JOY_WAITBUTTON := FALSE; { Ustawienie flagi oczekiwania na przycisk na falsz }
    xJoyUpdate;              { Aktualizacja stanu joysticka }
END.
