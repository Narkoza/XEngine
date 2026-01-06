unit xMem;

{$G+}  { Zezwol na instrukcje 286 }

(**************************************************************)
(** //                XENGINE Memory Unit                 // **)
(** //  (C) 2025 Coded by Adam Kozinski & Dominik Galoch  // **)
(** //////////////////////////////////////////////////////// **)
(**************************************************************)

interface

uses crt;

const
    MAX_BUFFER_SIZE = 64000;

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

procedure xCreateBuffer(var buffer_ptr : pointer);                                    { Zaalokuj pamiec dla drugiego bufora }
procedure xFreeBuffer(var buffer_ptr : pointer);                                           { Zwolnij pamiec drugiego bufora }
procedure xCopyBuffer(source, target : pointer);                                           { Kopiuj bufor ze zrodla do celu }

{//////////////////////////////////////////////////////////}

implementation

(***********************************************************)

procedure xCreateBuffer(var buffer_ptr : pointer);
var
    _free_mem : longint;
begin
    { Sprawdzamy czy system posiada wystarczajaco duzo wolnej pamieci }
    _free_mem := maxavail;
    if(_free_mem < MAX_BUFFER_SIZE) then exit;

    getmem(buffer_ptr, MAX_BUFFER_SIZE);
end;

(***********************************************************)

procedure xFreeBuffer(var buffer_ptr : pointer);
begin
    freemem(buffer_ptr, MAX_BUFFER_SIZE);
end;

(***********************************************************)

procedure xCopyBuffer(source, target : pointer);
begin
    asm
        push ds
        lds si, source
        les di, target
        mov cx, 32000
        cld
        rep movsw
        pop ds
    end;
end;

(***********************************************************)

end.
