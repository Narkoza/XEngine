unit xSound;

(**************************************************************)
(** //                XENGINE Sound Unit                  // **)
(** //  (C) 2025 Coded by Adam Kozinski & Dominik Galoch  // **)
(** //////////////////////////////////////////////////////// **)
(**************************************************************)

interface

uses crt, xtimer, dos, xmem. xfiles;

type
    TNote = (C, Cis, D, Dis, E, F, Fis, G, Gis, A, Ais, B); { PC SPEAKER NOTES }

const
    { GROK4 TEST }
    DMA_CHANNEL = 1;             { 8-bit DMA channel }
    DMA_MASK_PORT = $0A;         { DMA mask port }
    DMA_MODE_PORT = $0B;         { DMA mode port }
    DMA_CLEAR_PTR_PORT = $0C;    { DMA flip-flop clear port }
    DMA_START_ADDR_PORT = $02;   { DMA address port for ch1 }
    DMA_COUNT_PORT = $03;        { DMA count port for ch1 }
    DMA_PAGE_PORT = $83;         { DMA page port for ch1 }

    { DSP all ports }
    DSP_MIXER_PORT        = $224;
    DSP_MIXER_DATA_PORT   = $225;
    DSP_RESET             = $226;
    DSP_READ              = $22A;
    DSP_WRITE             = $22C;
    DSP_READ_STATUS_8     = $22E;
    DSP_READ_STATUS_16    = $22F;

    { DSP Write commands }
    DSP_SET_TIME_CONST    = $40;
    DSP_SET_OUT_SMPL_RATE = $41;
    DSP_TURN_ON_SPEAKER   = $D1;
    DSP_TURN_OFF_SPEAKER  = $D3;
    DSP_STOP_PLAYING_8    = $D0;
    DSP_RESUME_PBAK_8     = $D4;
    DSP_STOP_PLAYING_16   = $D5;
    DSP_RESUME_PBAK_16    = $D6;
    DSP_GET_VERSION       = $E1;

    { DSP mixer port commands }
    DSP_MASTER_VOLUME     = $22;
    DSP_SET_IRQ           = $80;

    { PC SPEAKER NOTE FREQUENCIES }
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

var
    OldIntVec: pointer;               { To store the original interrupt vector }
    sound_buff_ptr: pointer;          { Sound buffer }
    EightBitDMAInterrupt: boolean;    { Flag for 8-bit DMA or SB-MIDI interrupt }
    SixteenBitDMAInterrupt: boolean;  { Flag for 16-bit DMA interrupt }
    MPU401Interrupt: boolean;         { Flag for MPU-401 interrupt }

    { PC SPEAKER VARIABLES }
    isPlaying: boolean;
    remainingTicks: word;
    currentFreq: word;

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

procedure xSoundInit;
procedure xReadSoundFile(const filename : string);
procedure xPlaySine(frequency: word; duration: integer);
procedure xWaitForBit7(port_num : byte; rvalue : word);
procedure xWaitForBit7UntilSet(port_num : word);
procedure xWaitForBit7UntilUnset(port_num : word);
procedure xDSPWrite(data : word);
function xDSPRead : word;
procedure xSB16Init;
procedure xInstallISR;    { Install the ISR for DSP interrupts }
procedure xUninstallISR;  { Uninstall the ISR and restore original vector }
procedure xFreeSound;

{ PC SPEAKER PROCEDURES }
procedure xPlayNote(note: TNote; octave: integer; duration: word);
procedure xUpdateSound;
procedure xPlayPause(time : word);

{//////////////////////////////////////////////////////////}

implementation

(***********************************************************)

procedure xReadSoundFile(const filename : string);
var
    file_size: word;
    data: array;
begin
    { TODO: Read sound data before playback }
    if not xFileExists(filename) then
        writeln('Error reading the specified sound file');
        Exit;
    end;

    xLoadFile(filename, data, FileSize(filename));
end;

{ TODO: multiple allocations for sound data }
procedure xPlaySine(frequency: word; duration: integer);
var
    time_const: byte;
    physical_addr: longint;
    addr_low, addr_high, page: byte;
    count_low, count_high: byte;
    i: integer;  { Loop variable for filling the buffer }
begin
    xCreateBuffer(sound_buff_ptr);
    { Step 1: Fill the buffer with a test sound (e.g., a simple 440 Hz sine wave) }
    for i := 0 to duration do
        mem[seg(sound_buff_ptr^): ofs(sound_buff_ptr^) + i] := Round(127 * Sin(2 * Pi * frequency * i / 8000)) + 128;

    { Calculate physical DMA address of the buffer }
    physical_addr := LongInt(seg(sound_buff_ptr^)) shl 4 + ofs(sound_buff_ptr^);
    addr_low := Lo(physical_addr);
    addr_high := Hi(physical_addr);
    page := physical_addr shr 16;

    { Step 2: Program DMA controller for 8-bit single-cycle playback (mem to peripheral) }
    { TODO: Sprawdzic w dokumentacji czy potrzebne }
    Port[DMA_MASK_PORT] := DMA_CHANNEL or 4;          { Mask channel (bit 2=1) }
    Port[DMA_CLEAR_PTR_PORT] := 0;                    { Clear flip-flop }
    Port[DMA_START_ADDR_PORT] := addr_low;            { Set start address low byte }
    Port[DMA_START_ADDR_PORT] := addr_high;           { Set start address high byte }
    Port[DMA_PAGE_PORT] := page;                      { Set page }
    count_low := Lo(duration); count_high := Hi(duration);    { Count = length-1 }
    Port[DMA_COUNT_PORT] := count_low;
    Port[DMA_COUNT_PORT] := count_high;
    Port[DMA_MODE_PORT] := $48 + DMA_CHANNEL;         { Mode: single-cycle, increment, mem-to-IO (playback) }
    Port[DMA_MASK_PORT] := DMA_CHANNEL;               { Unmask channel }

    { Step 3: Set DSP time constant (~8000 Hz sampling rate) }
    time_const := 256 - (1000000 div 8000);           { = 131 or $83 }
    xDSPWrite($40);
    xDSPWrite(time_const);

    { Step 4: Program DSP for 8-bit single-cycle DMA output (command $14) }
    xDSPWrite($14);                                   { Start 8-bit DMA output }
    xDSPWrite(Lo(duration));                          { Length low  }
    xDSPWrite(Hi(duration));                          { Length high }

    { The DSP will now request DMA, transfer 4000 bytes, complete the block, and fire an 8-bit interrupt }
    xFreeBuffer(sound_buff_ptr);
end;

(***********************************************************)

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

(***********************************************************)

procedure xSpeakerOn; assembler;
asm
    in al, 61h
    or al, 03h
    out 61h, al
end;

(***********************************************************)

procedure xSpeakerOff; assembler;
asm
    in al, 61h
    and al, 0FCh
    out 61h, al
end;

(***********************************************************)

procedure xPlayNote(note: TNote; octave: integer; duration: word);
var
    frequency: real;
    octave_shift: integer;
begin
    if duration = 0 then
    begin
        isPlaying := false;
        xSpeakerOff;
        Exit;
    end;

    octave_shift := octave - 4;
    frequency := NOTE_FREQUENCIES[note] * Exp(octave_shift * Ln(2));
    currentFreq := Round(frequency);

    xSetCounter(currentFreq);
    xSpeakerOn;
    remainingTicks := duration;
    isPlaying := true;
end;

(***********************************************************)

procedure xUpdateSound;
begin
    if not isPlaying then Exit;
    Dec(remainingTicks);
    if remainingTicks = 0 then
    begin
        xSpeakerOff;
        isPlaying := false;
    end;
end;

(***********************************************************)

procedure xPlayPause(time : word);
begin
    xSpeakerOff;
    xWait(time);
end;

(***********************************************************)

procedure xWaitForBit7(port_num : byte; rvalue : word);
var
  i: longint;
begin
  i := 0;
  while (i < 100000) and ((port[port_num] and $80) = rvalue) do Inc(i);
  if i = 100000 then writeln('Timeout waiting for bit 7 on port $', port_num);
end;

(***********************************************************)

procedure xWaitForBit7UntilSet(port_num : word);
begin
    xWaitForBit7(port_num, 128);
end;

(***********************************************************)

procedure xWaitForBit7UntilUnset(port_num : word);
begin
    xWaitForBit7(port_num, 0);
end;

(***********************************************************)

procedure xDSPWrite(data : word);
begin
    xWaitForBit7UntilSet(DSP_WRITE);
    port[DSP_WRITE] := data;
end;

(***********************************************************)

function xDSPRead : word;
begin
  xWaitForBit7UntilUnset(DSP_READ_STATUS_8);  { Poll status port $22E until bit7=1 (data ready) }
  xDSPRead := port[DSP_READ];
end;

(***********************************************************)

procedure xSB16Init;
var
  i: integer;  { For timeout loop }
begin
  port[DSP_RESET] := 1;

  { Wait at least 3 microseconds; use a small assembly loop for precision, as delay() is in ms }
  asm
    mov cx, 10  { Adjust as needed for ~3us on your CPU speed; this is approximate }
  @loop:
    nop
    loop @loop
  end;

  port[DSP_RESET] := 0;

  { Poll for data ready (bit 7 == 1 on $22E), with a timeout to avoid infinite loop }
  i := 0;
  while (i < 1000) and ((port[DSP_READ_STATUS_8] and $80) = 0) do  { Wait until bit 7 == 1 }
  begin
    Inc(i);  { Timeout after ~1000 iterations; adjust based on system speed }
  end;

  if (port[DSP_READ_STATUS_8] and $80 = 0) then
  begin
    writeln('Timeout waiting for DSP ready after reset.');
  end;

  if (port[DSP_READ] <> $AA) then
  begin
    writeln('Sound Blaster not detected or IO error occurred.');
  end
  else
  begin
    writeln('Sound Blaster detected. Continuing...');
  end;
end;

(***********************************************************)

procedure SoundISR; interrupt;
var
    status: byte;
    dummy: byte;
    chunk: word;
    remaining_samples: word;
begin
    writeln('interrupt fired');
    repeat
        port[DSP_MIXER_PORT] := $82;          { Select mixer register 82h }
        status := port[DSP_MIXER_DATA_PORT];  { Read interrupt status }

        if (status and 1) <> 0 then
        begin
            dummy := port[DSP_READ_STATUS_8]; { Acknowledge 8-bit DMA/SB-MIDI }
            EightBitDMAInterrupt := true;
        end;

        if (status and 2) <> 0 then
        begin
            dummy := port[DSP_READ_STATUS_16]; { Acknowledge 16-bit DMA }
            SixteenBitDMAInterrupt := true;
        end;

        if (status and 4) <> 0 then
        begin
            dummy := port[$330];              { Acknowledge MPU-401 at 330h }
            MPU401Interrupt := true;
        end;
    until status = 0;                         { Loop until all interrupts cleared }

    if remaining_samples <= 0 then
    begin
        goto irq_exit;
    end;

    { TODO: Read actual sound data, get rid of generating test samples for sine tune }
    if remaining_samples > MAX_BUFFER_SIZE then chunk := MAX_BUFFER_SIZE
    else chunk := remaining_samples;

    { Generate samples for sine tune, this should be replaced with actual sound data from file }
    { TODO: Make use of XFILES.PAS }
    for i := 0 to chunk-1 do
        mem[seg(sound_buff_ptr^):ofs(sound_buff_ptr^) + i] :=
            Round(127 * Sin(2*Pi*dma_frequency*(i)/8000)) + 128;

    physical_addr := LongInt(seg(sound_buff_ptr^)) shl 4 + ofs(sound_buff_ptr^);
    addr_low := Lo(physical_addr);
    addr_high := Hi(physical_addr);
    page := physical_addr shr 16;

    remaining_samples := remaining_samples - chunk;

    irq_exit:

    port[$20] := $20;                         { Send EOI to master PIC }
end;

(***********************************************************)

procedure xInstallISR;
begin
    GetIntVec($0F, OldIntVec);    { Save original vector for IRQ 7 }
    SetIntVec($0F, @SoundISR);    { Set ISR for interrupt vector 0Fh }
    EightBitDMAInterrupt := false;
    SixteenBitDMAInterrupt := false;
    MPU401Interrupt := false;
end;

(***********************************************************)

procedure xUninstallISR;
begin
    SetIntVec($0F, OldIntVec);    { Restore original interrupt vector }
end;

(***********************************************************)

procedure xSoundInit;
begin
    xSB16Init;
    xInstallISR;
end;

(***********************************************************)

procedure xFreeSound;
begin
    xUninstallISR;
end;

(***********************************************************)

end.