unit xFiles;

(**************************************************************)
(** //              XENGINE Files Unit                    // **)
(** //  (C) 2025 Coded by Adam Kozinski & Dominik Galoch  // **)
(** //////////////////////////////////////////////////////// **)
(**************************************************************)

interface

const
    BLOCK_SIZE = 2048

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

function xFileExists(filename : string) : boolean;     { Sprawdz czy plik istnieje }
function xFileRead(filename : string) : integer;       { Odczytaj zawartosc pliku }
function xFileWrite(filename : string, data : string); { Zapisz dane do pliku }

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
    binary_file: file;
    buffer : array[0..BLOCK_SIZE] of byte;;
    file_size, i: integer
begin
    assign(binary_file, filename);
    reset(binary_file, 1);

    if EOF(binary_file) then
    begin
        Result := 0;
        Exit;
    end;

    file_size := FileSize(binary_file);
    blockread(binary_file, buffer, BLOCK_SIZE);

    { for i := 0 to file_size - 1 do
    begin
        Read(binary_file, buffer[i]);
    end; }

    close(binary_file);
    Result := file_size;
end;

function xFileWrite(filename : string, data : string);
var
    binary_file: file;
begin
    assign(binary_file, filename);
    reset(binary_file)
    writeln(data)
    close(Lst) ;
end.

end.
