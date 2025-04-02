unit xFiles;

(**************************************************************)
(** //              XENGINE Files Unit                    // **)
(** //  (C) 2025 Coded by Adam Kozinski & Dominik Galoch  // **)
(** //////////////////////////////////////////////////////// **)
(**************************************************************)

interface

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

function xFileExists(filename : string) : boolean; { Sprawdz czy plik istnieje }

{//////////////////////////////////////////////////////////}

implementation

(***********************************************************)

function xFileExists(filename : string) : boolean;
var
    fd : file;
begin
    {$I-}
        assign(fd, filename);
        reset(fd);
        close(fd);
    {$I+}

    xFileExists := IOResult = 0;
end;

(***********************************************************)

end.
