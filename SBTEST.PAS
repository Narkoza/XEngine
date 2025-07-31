program SBTest;
uses xSound, crt;

var
    buf: array[0..3999] of byte;  { Buffer for 4000 samples (500ms at 8000 Hz) }
    physical_addr: longint;
    addr_low, addr_high, page: byte;
    count_low, count_high: byte;
    i: integer;  { Loop variable for filling the buffer }

procedure triggerdsp;
var
  time_const: byte;
begin
    { Step 1: Fill the buffer with a test sound (e.g., a simple 440 Hz sine wave) }
    for i := 0 to 3999 do
        buf[i] := Round(127 * Sin(2 * Pi * 440 * i / 8000)) + 128;  { 8-bit unsigned PCM: sine wave at 440 Hz }

    { Calculate physical DMA address of the buffer }
    physical_addr := LongInt(Seg(buf)) shl 4 + Ofs(buf);
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
    count_low := Lo(3999); count_high := Hi(3999);    { Count = length-1 = 3999 for 4000-byte transfer }
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
    xDSPWrite(Lo(3999));                              { Length low (length-1=3999) }
    xDSPWrite(Hi(3999));                              { Length high }

    { The DSP will now request DMA, transfer 4000 bytes, complete the block, and fire an 8-bit interrupt }
end;

begin
    xSB16Init;
    xInstallISR;

    triggerdsp;

    writeln('after triggerdsp...');

    xUninstallISR;

    writeln('after xUninstallISR...');
end.
