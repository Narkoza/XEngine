program kbtest;

uses crt, xkeybrd;

var
    key : byte;

BEGIN
    clrscr;
    xEnableKeyboard;
    {xSetKeyboard($1f, $01);}

    while(key <> KEY_ESC) do
    begin
        xKeyHit(key);
        if(key <> 0) then writeln(key);
    end;

    xDisableKeyboard;
END.