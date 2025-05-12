unit xSound;

(**************************************************************)
(** //              XENGINE Sound Unit                    // **)
(** //  (C) 2025 Coded by Adam Kozinski & Dominik Galoch  // **)
(** //////////////////////////////////////////////////////// **)
(**************************************************************)

interface

uses xtimer;

type
    TNote = (C, Cis, D, Dis, E, F, Fis, G, Gis, A, Ais, B);

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

procedure xPlayNote(note : TNote; octave : integer; time : word);   { Graj dzwiek z PC Speakera }
procedure xPause(time : word);                                      { Pauza }

{//////////////////////////////////////////////////////////}

implementation

const
    NOTE_FREQUENCIES : array[TNote] of real = (
        261.63,  { C4 }
        277.18,  { C#4 }
        293.66,  { D4 }
        311.13,  { D#4 }
        329.63,  { E4 }
        349.23,  { F4 }
        369.99,  { F#4 }
        392.00,  { G4 }
        415.30,  { G#4 }
        440.00,  { A4 }
        466.16,  { A#4 }
        493.88   { B4 }
    );

procedure xSetCounter(frequency : word); assembler;
asm
    cmp frequency, 0
    je @zero
    mov dx, 0012h
    mov ax, 3456h
    div frequency
    mov cx, ax
    mov al, 0B6h
    out 43h, al
    mov al, cl
    out 42h, al
    mov al, ch
    out 42h, al
    jmp @exit
    @zero:
        xor al, al
        out 42h, al
        out 42h, al
    @exit:
end;

procedure xSpeakerOn; assembler;
asm
    in al, 61h
    or al, 03h
    out 61h, al
end;

procedure xSpeakerOff; assembler;
asm
    in al, 61h
    and al, 0FCh
    out 61h, al
end;

procedure xPlayNote(note : TNote; octave : integer; time : word);
var
    frequency: real;
    int_frequency: word;
    octave_shift: integer;
begin
    octave_shift := octave - 4;
    frequency := NOTE_FREQUENCIES[note] * Exp(octave_shift * Ln(2));
    int_frequency := Round(frequency);
    xSetCounter(int_frequency);
    xSpeakerOn;
    xWait(time);
    xSpeakerOff;
end;

procedure xPause(time : word);
begin
    xSpeakerOff;
    xWait(time);
end;

end.