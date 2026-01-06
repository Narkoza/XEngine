unit xSound;

(*******************************************************************)
(** //                   XENGINE Sound Unit                    // **)
(** //  (C) 2025-2026 Coded by Adam Kozinski & Dominik Galoch  // **)
(** ///////////////////////////////////////////////////////////// **)
(*******************************************************************)

interface

uses dos, crt, xtimer, xfiles;

type
    TByteArray = array[0..32767] of Byte;
    PByteArray = ^TByteArray;

    TNote = (C, Cis, D, Dis, E, F, Fis, G, Gis, A, Ais, B); { NUTY PC SPEAKERA }

    TWavFmt = record
        AudioFormat   : Word;       { 1 = PCM }
        NumChannels   : Word;       { 1 = Mono }
        SampleRate    : Longint;    { Czestotliwosc probkowania, np. 11025 }
        ByteRate      : Longint;    { SampleRate * NumChannels * BitsPerSample / 8 }
        BlockAlign    : Word;       { NumChannels * BitsPerSample / 8 }
        BitsPerSample : Word;       { 8 bitow }
    end;

    TWavData = record
        data          : Pointer;
        size          : LongInt;
        sample_rate   : Longint;
        tc            : Byte;
    end;

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

function HexStr(W: Word; Digits: Byte): string;
procedure xLoadSound(var wav: TWavData; const file_name: string);                   { Wczytaj dzwiek }
procedure xLoadSoundPkg(package_name, internal_name: string; var wav: TWavData);    { Wczytaj dzwiek z paczki }
procedure xPlaySound(const wav: TWavData; new_sample_rate: Longint);                { Graj dzwiek }
procedure xPlaySine(frequency: word; duration: integer);                            { Graj fale dzwiekowa }
procedure xSetMasterVolume(v: Byte);                                                { Ustaw glosnosc glowna }
procedure xSBInit;                                                                  { Wlacz Sound Blaster }
procedure xSBDeinit;                                                                { Wylacz Sound Blaster }
procedure xSBStop;                                                                  { Zatrzymaj Sound Blaster }
function xSBDetect: Boolean;                                                        { Wykryj Sound Blaster }
{ PROCEDURY PC SPEAKERA }
procedure xPlayNote(note: TNote; octave: integer; duration: word);                  { Graj nute z PC Spekaera }
procedure xUpdateSound;                                                             { Aktualizuj dzwiek z PC Speakera }
procedure xPlayPause(time : word);                                                  { Graj pauze }

{//////////////////////////////////////////////////////////}

var
    sb_base             : Word;
    sb_irq              : Byte;
    sb_dma              : Byte;

implementation

const
    DMA_BLOCK_LENGTH            = $7FFF;
    SB_BLOCK_LENGTH             = $3FFF;

    SB_RESET                    = $6;
    SB_READ_DATA                = $A;
    SB_READ_DATA_STATUS         = $E;
    SB_WRITE_DATA               = $C;

    SB_PAUSE_PLAYBACK           = $D0;
    SB_ENABLE_SPEAKER           = $D1;
    SB_DISABLE_SPEAKER          = $D3;
    SB_SET_PLAYBACK_FREQUENCY   = $40;
    SB_SINGLE_CYCLE_PLAYBACK    = $14;
    SB_START_AUTOINIT_PLAYBACK  = $1C;
    SB_SET_BLOCK_SIZE           = $48;
    SB_STOP_AUTOINIT_PLAYBACK   = $DA;

    MASK_REGISTER               = $0A;
    MODE_REGISTER               = $0B;
    MSB_LSB_FLIP_FLOP           = $0C;
    DMA_CHANNEL_0               = $87;
    DMA_CHANNEL_1               = $83;
    DMA_CHANNEL_3               = $82;

    { CZESTOTLIWOSCI NUT PC SPEAKERA }
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
    old_irq             : Pointer;
    r_buffer            : Integer;
    current_data        : Pointer;
    current_position    : LongInt;
    playing             : Boolean;
    to_be_played        : LongInt;
    to_be_read          : LongInt;
    dma_buffer          : PByteArray;
    page                : Word;
    offset              : Word;
    sample_rate         : Longint;
    tc                  : Byte;
    MasterVolume        : Integer;

    { ZMIENNE PC SPEAKERA }
    isPlaying: boolean;
    remainingTicks: word;
    currentFreq: word;

procedure read_buffer(buffer: Integer); forward;
procedure single_cycle_playback; forward;

(***********************************************************)

function UpperCase(S: string): string;
var
    i : Integer;
begin
    for i := 1 to Length(S) do
        S[i] := UpCase(S[i]);
    UpperCase := S;
end;

(***********************************************************)

function HexStr(W: Word; Digits: Byte): string;
const
    HexChars: array[0..15] of Char = '0123456789ABCDEF';
var
    S : string;
    I : Byte;
begin
    S := '';
    for I := Digits downto 1 do
    begin
        S := HexChars[W and $F] + S;
        W := W shr 4;
    end;
    HexStr := S;
end;

(***********************************************************)

function reset_dsp(PortAddr: Word): Boolean;
begin
    Port[PortAddr + SB_RESET] := 1;
    Delay(10);
    Port[PortAddr + SB_RESET] := 0;
    Delay(10);
    if ((Port[PortAddr + SB_READ_DATA_STATUS] and $80 = $80) and
        (Port[PortAddr + SB_READ_DATA] = $AA)) then
    begin
        sb_base := PortAddr;
        reset_dsp := True;
    end
    else
        reset_dsp := False;
end;

(***********************************************************)

procedure write_dsp(command: Byte);
begin
    while (Port[sb_base + SB_WRITE_DATA] and $80 = $80) do ;
    Port[sb_base + SB_WRITE_DATA] := command;
end;

function xSBDetect: Boolean;
var
    temp    : Byte;
    BLASTER : string;
    i       : Integer;
begin
    sb_base := 0;

    { Mozliwe wartosci: 210, 220, 230, 240, 250, 260, 280 }
    for temp := 1 to 8 do
    begin
        if temp <> 7 then
        begin
            if reset_dsp($200 + (temp shl 4)) then
            Break;
        end;
    end;
    if sb_base = 0 then
    begin
        xSBDetect := False;
        Exit;
    end;

    BLASTER := GetEnv('BLASTER');
    sb_dma := 0;
    i := Pos('D', UpperCase(BLASTER));
    if i > 0 then
        sb_dma := Ord(BLASTER[i + 1]) - Ord('0');

    i := Pos('I', UpperCase(BLASTER));
    if i > 0 then
    begin
        sb_irq := Ord(BLASTER[i + 1]) - Ord('0');
        if (i + 2 <= Length(BLASTER)) and (BLASTER[i + 2] <> ' ') then
            sb_irq := sb_irq * 10 + (Ord(BLASTER[i + 2]) - Ord('0'));
    end;

    xSBDetect := sb_base <> 0;
end;

(***********************************************************)

procedure sb_irq_handler; interrupt;
var
    dummy : Byte;
begin
    dummy := Port[sb_base + SB_READ_DATA_STATUS];
    Port[$20] := $20;
    if sb_irq in [2, 10, 11] then
        Port[$A0] := $20;
    if playing then
    begin
        to_be_played := to_be_played - 16384;
        if to_be_played > 0 then
        begin
            read_buffer(r_buffer);
            if to_be_played <= 16384 then
            begin
                r_buffer := r_buffer xor 1;
                single_cycle_playback;
            end
            else if to_be_played <= 32768 then
                write_dsp(SB_STOP_AUTOINIT_PLAYBACK);
        end
        else
            playing := False;
    end;
    r_buffer := r_buffer xor 1;
end;

(***********************************************************)

procedure init_irq;
var
    irq_vec : Byte;
begin
    { Zapisz stary wektor IRQ }
    if sb_irq in [2, 10, 11] then
    begin
        if sb_irq = 2 then irq_vec := $71
        else if sb_irq = 10 then irq_vec := $72
        else irq_vec := $73;
        GetIntVec(irq_vec, old_irq);
    end
    else
        GetIntVec(sb_irq + 8, old_irq);

    { Ustaw wlasny wektor IRQ }
    if sb_irq in [2, 10, 11] then
        SetIntVec(irq_vec, @sb_irq_handler)
    else
        SetIntVec(sb_irq + 8, @sb_irq_handler);

    { Wlacz IRQ za pomoca PIC }
    if sb_irq in [2, 10, 11] then
    begin
        if sb_irq = 2 then Port[$A1] := Port[$A1] and 253
        else if sb_irq = 10 then Port[$A1] := Port[$A1] and 251
        else Port[$A1] := Port[$A1] and 247;
        Port[$21] := Port[$21] and 251;
    end
    else
        Port[$21] := Port[$21] and not (1 shl sb_irq);
end;

(***********************************************************)

procedure deinit_irq;
var
    irq_vec : Byte;
begin
    { Przywroc stary wektor IRQ }
    if sb_irq in [2, 10, 11] then
    begin
        if sb_irq = 2 then irq_vec := $71
        else if sb_irq = 10 then irq_vec := $72
        else irq_vec := $73;
        SetIntVec(irq_vec, old_irq);
    end
    else
        SetIntVec(sb_irq + 8, old_irq);

    { Wylacz IRQ za pomoca PIC }
    if sb_irq in [2, 10, 11] then
    begin
        if sb_irq = 2 then Port[$A1] := Port[$A1] or 2
        else if sb_irq = 10 then Port[$A1] := Port[$A1] or 4
        else Port[$A1] := Port[$A1] or 8;
        Port[$21] := Port[$21] or 4;
    end
    else
        Port[$21] := Port[$21] or (1 shl sb_irq);
end;

(***********************************************************)

procedure assign_dma_buffer;
var
    temp_buf        : PByteArray;
    linear_address  : LongInt;
    page1, page2    : Word;
begin
    GetMem(temp_buf, 32768);
    linear_address := LongInt(Seg(temp_buf^[0])) shl 4 + Ofs(temp_buf^[0]);
    page1 := linear_address shr 16;
    page2 := (linear_address + 32767) shr 16;
    if page1 <> page2 then
    begin
        GetMem(dma_buffer, 32768);
        FreeMem(temp_buf, 32768);
    end
    else
        dma_buffer := temp_buf;
    linear_address := LongInt(Seg(dma_buffer^[0])) shl 4 + Ofs(dma_buffer^[0]);
    page := linear_address shr 16;
    offset := linear_address and $FFFF;
end;

(***********************************************************)

procedure xSBInit;
begin
    init_irq;
    assign_dma_buffer;
    write_dsp(SB_ENABLE_SPEAKER);
end;

(***********************************************************)

procedure xSBDeinit;
begin
    write_dsp(SB_DISABLE_SPEAKER);
    FreeMem(dma_buffer, 32768);
    deinit_irq;
end;

(***********************************************************)

procedure single_cycle_playback;
var
    dma_addr      : Word;
    dma_page_port : Word;
begin
    playing := True;
    { Programowanie kontrolera DMA }
    Port[MASK_REGISTER] := 4 or sb_dma;
    Port[MSB_LSB_FLIP_FLOP] := 0;
    Port[MODE_REGISTER] := $48 or sb_dma;
    dma_addr := sb_dma shl 1;
    Port[dma_addr] := Lo(offset);
    Port[dma_addr] := Hi(offset);
    case sb_dma of
        0: dma_page_port := DMA_CHANNEL_0;
        1: dma_page_port := DMA_CHANNEL_1;
        3: dma_page_port := DMA_CHANNEL_3;
    end;
    Port[dma_page_port] := page;
    Port[dma_addr + 1] := Lo(to_be_played);
    Port[dma_addr + 1] := Hi(to_be_played);
    Port[MASK_REGISTER] := sb_dma;
    write_dsp(SB_SINGLE_CYCLE_PLAYBACK);
    write_dsp(Lo(to_be_played));
    write_dsp(Hi(to_be_played));
    to_be_played := 0;
end;

(***********************************************************)

procedure xSBStop;
begin
    write_dsp(SB_PAUSE_PLAYBACK);
    playing := False;
end;

(***********************************************************)

procedure ApplyVolume(buf_off: Integer);
var
    i       : Integer;
    sample  : Integer;
begin
    for i := 0 to 16383 do
    begin
        sample := dma_buffer^[buf_off + i] - 128;
        sample := (sample * MasterVolume) div 255;
        dma_buffer^[buf_off + i] := Byte(sample + 128);
    end;
end;

(***********************************************************)

procedure xSetMasterVolume(v: Byte);
begin
    MasterVolume := v;
end;

(***********************************************************)

procedure read_buffer(buffer: Integer);
var
    buf_off : Integer;
    num_to_read : LongInt;
begin
    buf_off := buffer shl 14;
    if to_be_read <= 0 then
        Exit;
    num_to_read := 16384;
    if to_be_read < num_to_read then
        num_to_read := to_be_read;
    Move(Pointer(LongInt(current_data) + current_position)^, dma_buffer^[buf_off], num_to_read);
    if num_to_read < 16384 then
        FillChar(dma_buffer^[buf_off + num_to_read], 16384 - num_to_read, 128);
    current_position := current_position + num_to_read;
    to_be_read := to_be_read - num_to_read;
    ApplyVolume(buf_off);
end;

(***********************************************************)

procedure auto_init_playback;
var
    dma_addr: Word;
    dma_page_port: Word;
begin
    { Programowanie kontrolera DMA }
    Port[MASK_REGISTER] := 4 or sb_dma;
    Port[MSB_LSB_FLIP_FLOP] := 0;
    Port[MODE_REGISTER] := $58 or sb_dma;
    dma_addr := sb_dma shl 1;
    Port[dma_addr] := Lo(offset);
    Port[dma_addr] := Hi(offset);
    case sb_dma of
        0: dma_page_port := DMA_CHANNEL_0;
        1: dma_page_port := DMA_CHANNEL_1;
        3: dma_page_port := DMA_CHANNEL_3;
    end;
    Port[dma_page_port] := page;
    Port[dma_addr + 1] := Lo(DMA_BLOCK_LENGTH);
    Port[dma_addr + 1] := Hi(DMA_BLOCK_LENGTH);
    Port[MASK_REGISTER] := sb_dma;
    write_dsp(SB_SET_BLOCK_SIZE);
    write_dsp(Lo(SB_BLOCK_LENGTH));
    write_dsp(Hi(SB_BLOCK_LENGTH));
    write_dsp(SB_START_AUTOINIT_PLAYBACK);
end;

(***********************************************************)

procedure xLoadSound(var wav: TWavData; const file_name: string);
var
    temp_file   : File;
    chunk_id    : string[4];
    chunk_size  : LongInt;
    fmt_chunk   : TWavFmt;
    found_fmt   : Boolean;
    found_data  : Boolean;
    numRead     : Word;
begin
    found_fmt := False;
    found_data := False;
    Assign(temp_file, file_name);
    {$I-}
        Reset(temp_file, 1);
    {$I+}
    if IOResult <> 0 then
    begin
        WriteLn('Error: file not found ', file_name);
        Exit;
    end;

    BlockRead(temp_file, chunk_id[1], 4, numRead);
    chunk_id[0] := #4;
    if chunk_id <> 'RIFF' then
    begin
        WriteLn('Not a RIFF file');
        Close(temp_file);
        Exit;
    end;
    BlockRead(temp_file, chunk_size, 4, numRead);
    BlockRead(temp_file, chunk_id[1], 4, numRead);
    chunk_id[0] := #4;
    if chunk_id <> 'WAVE' then
    begin
        WriteLn('Not a WAVE file');
        Close(temp_file);
        Exit;
    end;

    while not (found_data and found_fmt) do
    begin
        BlockRead(temp_file, chunk_id[1], 4, numRead);
        if numRead <> 4 then
        begin
            WriteLn('Invalid WAV file');
            Close(temp_file);
            Exit;
        end;
        chunk_id[0] := #4;
        BlockRead(temp_file, chunk_size, 4, numRead);
        if chunk_id = 'fmt ' then
        begin
            if chunk_size <> 16 then
            begin
                WriteLn('Unsupported fmt chunk size');
                Close(temp_file);
                Exit;
            end;
            BlockRead(temp_file, fmt_chunk, SizeOf(fmt_chunk), numRead);
            with fmt_chunk do
            begin
                if AudioFormat <> 1 then
                begin
                    WriteLn('Only PCM format supported');
                    Close(temp_file);
                    Exit;
                end;
                if NumChannels <> 1 then
                begin
                    WriteLn('Only mono supported');
                    Close(temp_file);
                    Exit;
                end;
                if BitsPerSample <> 8 then
                begin
                    WriteLn('Only 8-bit samples supported');
                    Close(temp_file);
                    Exit;
                end;
                wav.sample_rate := SampleRate;
                found_fmt := True;
            end;
        end
        else if chunk_id = 'data' then
        begin
            found_data := True;
            wav.size := chunk_size;
            GetMem(wav.data, wav.size);
            BlockRead(temp_file, wav.data^, wav.size, numRead);
        end
        else
            Seek(temp_file, FilePos(temp_file) + chunk_size);
    end;

    if not found_fmt then
    begin
        WriteLn('No fmt chunk in WAV');
        Close(temp_file);
        Exit;
    end;

    if not found_data then
    begin
        WriteLn('No data chunk in WAV');
        Close(temp_file);
        Exit;
    end;

    wav.tc := 256 - (1000000 div wav.sample_rate);
    Close(temp_file);
end;

(***********************************************************)

procedure xLoadSoundPkg(package_name, internal_name: string; var wav: TWavData);
var
    fd          : file;
    success     : boolean;
    file_size   : longint;
    chunk_id    : string[4];
    chunk_size  : LongInt;
    fmt_chunk   : TWavFmt;
    found_fmt   : Boolean;
    found_data  : Boolean;
    numRead     : Word;
begin
    found_fmt := False;
    found_data := False;
    xOpenPakFile(package_name, internal_name, fd, file_size, success);
    if not success then exit;

    BlockRead(fd, chunk_id[1], 4, numRead);
    chunk_id[0] := #4;
    if chunk_id <> 'RIFF' then
    begin
        close(fd);
        exit;
    end;
    BlockRead(fd, chunk_size, 4, numRead);
    BlockRead(fd, chunk_id[1], 4, numRead);
    chunk_id[0] := #4;
    if chunk_id <> 'WAVE' then
    begin
        close(fd);
        exit;
    end;

    while not (found_data and found_fmt) do
    begin
        BlockRead(fd, chunk_id[1], 4, numRead);
        if numRead <> 4 then
        begin
            close(fd);
            exit;
        end;
        chunk_id[0] := #4;
        BlockRead(fd, chunk_size, 4, numRead);
        if chunk_id = 'fmt ' then
        begin
            if chunk_size <> 16 then
            begin
                close(fd);
                exit;
            end;
            BlockRead(fd, fmt_chunk, SizeOf(fmt_chunk), numRead);
            with fmt_chunk do
            begin
                if AudioFormat <> 1 then
                begin
                    close(fd);
                    exit;
                end;
                if NumChannels <> 1 then
                begin
                    close(fd);
                    exit;
                end;
                if BitsPerSample <> 8 then
                begin
                    close(fd);
                    exit;
                end;
                wav.sample_rate := SampleRate;
                found_fmt := True;
            end;
        end
        else if chunk_id = 'data' then
        begin
            found_data := True;
            wav.size := chunk_size;
            GetMem(wav.data, wav.size);
            BlockRead(fd, wav.data^, wav.size, numRead);
            if numRead <> wav.size then
            begin
                FreeMem(wav.data, wav.size);
                close(fd);
                exit;
            end;
        end
        else
            Seek(fd, FilePos(fd) + chunk_size);
    end;

    if not found_fmt then
    begin
        if found_data then FreeMem(wav.data, wav.size);
        close(fd);
        exit;
    end;

    if not found_data then
    begin
        close(fd);
        exit;
    end;

    wav.tc := 256 - (1000000 div wav.sample_rate);
    close(fd);
end;

(***********************************************************)

procedure xPlaySound(const wav: TWavData; new_sample_rate: Longint);
var
    effective_rate: Longint;
    effective_tc: Byte;
begin
    if dma_buffer = nil then
        Exit;
    r_buffer := 0;
    FillChar(dma_buffer^, 32768, 128);
    to_be_read := wav.size;
    to_be_played := wav.size;
    current_data := wav.data;
    current_position := 0;

    if new_sample_rate > 0 then
        effective_rate := new_sample_rate
    else
        effective_rate := wav.sample_rate;
        
    effective_tc := 256 - (1000000 div effective_rate);

    write_dsp(SB_SET_PLAYBACK_FREQUENCY);
    write_dsp(effective_tc);
    write_dsp(SB_ENABLE_SPEAKER);
    read_buffer(0);
    read_buffer(1);
    if to_be_read > 0 then
        auto_init_playback
    else
        single_cycle_playback;

    playing := True;
end;

(***********************************************************)

procedure xPlaySine(frequency: word; duration: integer);
var
    sine_wav: TWavData;
    i: integer;
    sample_rate: longint;
begin
    sample_rate := 8000;  { Domyslna czestotliwosc probkowania }
    sine_wav.size := duration;
    sine_wav.sample_rate := sample_rate;
    sine_wav.tc := 256 - (1000000 div sample_rate);
    GetMem(sine_wav.data, sine_wav.size);
    for i := 0 to duration - 1 do
        PByteArray(sine_wav.data)^[i] := Round(127 * Sin(2 * Pi * frequency * i / sample_rate)) + 128;
    xPlaySound(sine_wav, 0);
    FreeMem(sine_wav.data, sine_wav.size);
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

begin
    xSetMasterVolume(255);
    playing := False;
end.