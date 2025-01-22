unit xEngine;

interface

{// N A G L O W K I  P R O C E D U R  I  F U N K C J I //}
{////////////////////////////////////////////////////////}

procedure xSetVGAMode; { Ustaw tryb VGA 320x200x256 }
procedure xSetTxtMode; { Ustaw tryb tekstowy }

implementation

{--------------}

procedure xSetVGAMode;
begin
    asm
        mov AX, 13h
        int 10h      
    end;
end;


procedure xSetTxtMode;
begin
    asm
        mov AX, 0003h
        int 10h
    end;
end;

{--------------}

end.

