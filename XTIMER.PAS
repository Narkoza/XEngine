unit xTimer;

(**************************************************************)
(** //               XENGINE Timer Unit                   // **)
(** //  (C) 2025 Coded by Adam Kozinski & Dominik Galoch  // **)
(** //////////////////////////////////////////////////////// **)
(**************************************************************)

interface

uses dos;

var
    OldInt1C    : pointer;          { Przechowuje oryginalny wektor przerwania }
    timer_count  : longint;         { Licznik czasu w milisekundach }

{//////////////////////////////////////////////////////////}
{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

procedure xInitTimer(freq : word);  { Inicjalizuje timer z podana czestotliwoscia w Hz }
function xGetTime : longint;        { Zwraca aktualny czas w milisekundach }
procedure xWait(ms : word);         { Czeka przez podana liczbe milisekund }
procedure xRestoreTimer;

{//////////////////////////////////////////////////////////}

implementation

(***********************************************************)

procedure NewInt1C; interrupt;
begin
    Inc(timer_count);   { Zwieksza licznik przy kazdym przerwaniu }
    asm
        mov al, 20h     { Wysyla sygnal EOI do kontrolera przerwan }
        out 20h, al
    end;
end;

(***********************************************************)

procedure xInitTimer(freq : word);
var
    count : word;
begin
    if freq = 0 then freq := 1000;  { Domyslna czestotliwosc: 1000 Hz }
    count := 1193180 div freq;      { Oblicza wartosc dla PIT }

    asm
        cli                         { Wylacza przerwania }
        mov al, 36h                 { Ustawia tryb pracy PIT (kanal 0, tryb 2) }
        out 43h, al
        mov ax, count               { Wyslanie mlodszego i starszego bajtu }
        out 40h, al
        mov al, ah
        out 40h, al
        sti                         { Wlacza przerwania }
    end;

    GetIntVec($1C, OldInt1C);       { Zapisuje oryginalny wektor przerwania }
    SetIntVec($1C, @NewInt1C);      { Ustawia nowa procedure obslugi przerwania }
    timer_count := 0;               { Zeruje licznik }
end;

(***********************************************************)

function xGetTime : longint;
begin
    xGetTime := timer_count;         { Zwraca aktualny czas }
end;

(***********************************************************)

procedure xWait(ms : word);
var
    start : LongInt;
begin
    start := xGetTime;               { Pobiera czas startowy }
    while xGetTime - start < ms do;  { Czeka, az uplynie zadany czas }
end;

(***********************************************************)

procedure xRestoreTimer;
begin
    SetIntVec($1C, OldInt1C);       { Przywraca oryginalny wektor przerwania }
    asm
        cli
        mov al, 36h                 { Przywraca domyslne ustawienia PIT }
        out 43h, al
        mov ax, 0
        out 40h, al
        mov al, ah
        out 40h, al
        sti
    end;
end;

(***********************************************************)

begin
    xInitTimer(1000);  { Inicjalizuje timer z czestotliwoscia 1000 Hz }
    { Uwaga: Wywolaj procedure xRestoreTimer przy zakonczeniu programu! }
end.