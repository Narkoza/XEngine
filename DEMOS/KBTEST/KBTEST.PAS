program kbtest;

uses crt, xkeybrd, xtimer;

var
    scan_code : byte;

BEGIN
    clrscr;
    xKeyboardInit;

    while not key[KEY_ESC] do
    begin
        for scan_code := 1 to 127 do
        begin
            if key[scan_code] then
            begin
                writeln('Klawisz wcisniety: ', scan_code);
                xWait(100);
            end;
        end;
    end;

    xRestoreTimer;
    xDisableKeyboard;
END.