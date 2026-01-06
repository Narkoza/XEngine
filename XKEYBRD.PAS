{$g+}
unit xKeybrd;

(**************************************************************)
(** //              XENGINE Keyboard Unit                 // **)
(** //  (C) 2025 Coded by Adam Kozinski & Dominik Galoch  // **)
(** //////////////////////////////////////////////////////// **)
(**************************************************************)

interface

uses dos;

type TKeyboardEvent = procedure;

var
    OldInt09        : pointer;                  { stara procedura obslugi przerwania klawiatury }
    key             : array[1..127] of boolean;
    any_pressed     : boolean;
    key_delay       : word;
    keyboard_event  : TKeyboardEvent;

{//  T A B L I C A  S K A N  K O D O W  K L A W I A T U R Y  //}
{//////////////////////////////////////////////////////////////}

const
    KEY_ESC         = 1;
    KEY_1           = 2;
    KEY_2           = 3;
    KEY_3           = 4;
    KEY_4           = 5;
    KEY_5           = 6;
    KEY_6           = 7;
    KEY_7           = 8;
    KEY_8           = 9;
    KEY_9           = 10;
    KEY_0           = 11;
    KEY_MINUS       = 12;
    KEY_EQUAL       = 13;
    KEY_BACKSPACE   = 14;
    KEY_TAB         = 15;
    KEY_Q           = 16;
    KEY_W           = 17;
    KEY_E           = 18;
    KEY_R           = 19;
    KEY_T           = 20;
    KEY_Y           = 21;
    KEY_U           = 22;
    KEY_I           = 23;
    KEY_O           = 24;
    KEY_P           = 25;
    KEY_LEFTBRACE   = 26;
    KEY_RIGHTBRACE  = 27;
    KEY_ENTER       = 28;
    KEY_CTRL        = 29;
    KEY_A           = 30;
    KEY_S           = 31;
    KEY_D           = 32;
    KEY_F           = 33;
    KEY_G           = 34;
    KEY_H           = 35;
    KEY_J           = 36;
    KEY_K           = 37;
    KEY_L           = 38;
    KEY_SEMICOLON   = 39;
    KEY_APOSTROPHE  = 40;
    KEY_GRAVE       = 41;
    KEY_LEFTSHIFT   = 42;
    KEY_BACKSLASH   = 43;
    KEY_Z           = 44;
    KEY_X           = 45;
    KEY_C           = 46;
    KEY_V           = 47;
    KEY_B           = 48;
    KEY_N           = 49;
    KEY_M           = 50;
    KEY_COMMA       = 51;
    KEY_DOT         = 52;
    KEY_SLASH       = 53;
    KEY_RIGHTSHIFT  = 54;
    KEY_KPASTERISK  = 55;
    KEY_ALT         = 56;
    KEY_SPACE       = 57;
    KEY_CAPSLOCK    = 58;
    KEY_F1          = 59;
    KEY_F2          = 60;
    KEY_F3          = 61;
    KEY_F4          = 62;
    KEY_F5          = 63;
    KEY_F6          = 64;
    KEY_F7          = 65;
    KEY_F8          = 66;
    KEY_F9          = 67;
    KEY_F10         = 68;
    KEY_NUMLOCK     = 69;
    KEY_SCROLLLOCK  = 70;
    KEY_HOME        = 71;
    KEY_UP          = 72;
    KEY_PAGEUP      = 73;
    KEY_KPMINUS     = 74;
    KEY_LEFT        = 75;
    KEY_KP5         = 76;
    KEY_RIGHT       = 77;
    KEY_KPPLUS      = 78;
    KEY_END         = 79;
    KEY_DOWN        = 80;
    KEY_PAGEDOWN    = 81;
    KEY_INSERT      = 82;
    KEY_KPDOT       = 83;
    KEY_F11         = 87;
    KEY_F12         = 88;

    KEY_WAIT : integer = 0;

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

procedure xKeyboardInit;                                                     { Wlacz klawiature }
procedure xDisableKeyboard;                                                 { Wylacz klawiature }
procedure xClearKeyboard;                                              { Czysc bufor klawiatury }
function  xKeyRetrace : boolean;               { Zarzadzaj czestotliwoscia naciskanych klawiszy }

{//////////////////////////////////////////////////////////}

implementation

(***********************************************************)

{$f+}
procedure xNewInt09; interrupt;
begin
    if assigned(keyboard_event) then
        keyboard_event;

    asm
        sti

        xor ch, ch             { Ustaw CH na 0, uzywamy tutaj bajtow! }

        mov dx, $60            { Ustaw DX na port $60 (port klawiatury) }
        in al, dx              { Pobierz bajt z klawiatury }
        mov cl, al             { Umiesc go w CL do uzycia }
        and cl, $7f            { AND CL z 127 (MOD 128) }

        mov bx, offset key     { Pobierz offset tablicy KEY z wartosciami logicznymi }
        dec bx
        add bx, cx             { Dodaj znaleziony klawisz do BX }
        mov si, bx             { Umiesc obliczony offset w DS:[SI] }

        shr al, 7              { Podziel AL przez 128 }
        xor al, 1
        mov [si], al           { Umiesc TRUE lub FALSE w pozycji tablicy dla znalezionego klawisza }
        mov any_pressed, al    { Ustaw ANYPRESSED na TRUE lub FALSE }
        mov dx, $61
        in al, dx              { Pobierz bajt z portu }
        mov cl, al
        or al, $80
        out dx, al
        mov al, cl
        out dx, al
        cli

        mov ax, $20
        mov dx, $20
        out dx, ax
    end;
end;
{$f-}

(***********************************************************)

procedure xKeyboardInit;
var 
    n : byte;
begin
    any_pressed  := FALSE;
    ExitProc    := addr(xDisableKeyboard);
    GetIntVec($09, OldInt09);
    SetIntVec($09, addr(xNewInt09));
    for n := 1 to 127 do 
        key[n] := FALSE;
end;

(***********************************************************)

procedure xDisableKeyboard;
begin
    SetIntVec($09, OldInt09);
end;

(***********************************************************)

procedure xClearKeyboard; assembler;
asm
    mov ax, 0c00h
    int 21h
end;

(***********************************************************)

function xKeyRetrace : boolean;
begin
    xKeyRetrace := FALSE;

    if KEY_WAIT > 0 then 
    begin 
        dec(key_delay);
        exit; 
    end;

    KEY_WAIT := key_delay;
    xKeyRetrace := TRUE;
end;

(***********************************************************)

begin
    key_delay := 1; FillChar(key, sizeof(key), 0);
    keyboard_event := NIL;
end.