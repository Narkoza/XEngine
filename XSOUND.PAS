unit xSound;

(**************************************************************)
(** //              XENGINE Sound Unit                    // **)
(** //  (C) 2025 Coded by Adam Kozinski & Dominik Galoch  // **)
(** //////////////////////////////////////////////////////// **)
(**************************************************************)

interface

uses xtimer;

const
    { DSP all ports }
    DSP_MIXER_PORT      = 0x224;
    DSP_MIXER_DATA_PORT = 0x225;
    DSP_RESET           = 0x226;
    DSP_READ            = 0x22A;
    DSP_WRITE           = 0x22C;
    DSP_READ_STATUS_8   = 0x22E;
    DSP_READ_STATUS_16  = 0x22F;

    { DSP Write commands }
    DSP_SET_TIME_CONST    = 0x40;
    DSP_SET_OUT_SMPL_RATE = 0x41;
    DSP_TURN_ON_SPEAKER   = 0xD1;
    DSP_TURN_OFF_SPEAKER  = 0xD3;
    DSP_STOP_PLAYING_8    = 0xD0;
    DSP_RESUME_PBAK_8     = 0xD4;
    DSP_STOP_PLAYING_16   = 0xD5;
    DSP_RESUME_PBAK_16    = 0xD6;
    DSP_GET_VERSION       = 0xE1;

    { DSP mixer port commands }
    DSP_MASTER_VOLUME = 0x22;
    DSP_SET_IRQ       = 0x80;

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

procedure xWaitForBit7(port_num : byte, rvalue : byte);
begin
    while (port[port_num] and 0x80 = rvalue) do ;
end;

procedure xWaitForBit7UntilSet(port_num : byte);
var
    xWaitForBit7(port_num, 128);
end;

procedure xWaitForBit7UntilUnset(port_num : byte);
var
    xWaitForBit7(port_num, 0);
end;

procedure xDSPWrite(data : byte);
begin
    xWaitForBit7UntilSet(DSP_WRITE);
    port[DSP_WRITE] := data;
end;

procedure xDSPRead;
begin
    xWaitForBit7UntilUnset(DSP_READ);
    result := port[DSP_READ];
end;

procedure xSB16Init;
begin
    port[DSP_RESET] := 1;
    delay(3);

    { wait for status 'ready' }
    while (port[DSP_READ_STATUS_8] and 0x80 = 0x80) do ;

    port[DSP_RESET] := 0;

    if (port(DSP_READ) != 0xAA) then
    begin
        { print test data - sound blaster niewykryty / IO error }
        exit;
    end
    else
    begin
        { print test data - sound blaster wykryty, kontynuuj }
    end;
end;

end.