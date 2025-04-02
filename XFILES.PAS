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
function xFileRead(filename : string) : integer; { Odczytaj zawartosc pliku }

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

function xFileRead(filename : string) : integer;
var
    buffer : array of byte;
    binary_file: file of byte;
    file_size, i: integer
begin
    AssignFile(binary_file, filename);
    Reset(binary_file);
    if EOF(binary_file) then
    begin
        Result := 0;
        Exit;
    end;

    file_size := FileSize(binary_file);
    SetLength(buffer, file_size);

    for i := 0 to file_size - 1 do
    begin
        Read(binary_file, buffer[i]);
    end;

    CloseFile(binFile);
    Result := FileSize;
end;

end.
