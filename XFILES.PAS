unit xFiles;

(*******************************************************************)
(** //                   XENGINE Files Unit                    // **)
(** //  (C) 2025-2026 Coded by Adam Kozinski & Dominik Galoch  // **)
(** ///////////////////////////////////////////////////////////// **)
(*******************************************************************)

interface

type
    TCharArray = array[0..63] of char;

    THeader = record
                controlNumber   : integer;
                files           : integer;
            end;

    TFileInfo = record
                    title       : TCharArray;
                    size        : longint;
                    offset      : longint;
                end;

{//  N A G L O W K I  P R O C E D U R  I  F U N K C J I  //}
{//////////////////////////////////////////////////////////}

function xFileExists(filename : string) : boolean;                        { Sprawdz czy plik istnieje }
procedure xSaveFile(const filename : string; var data; size : word);      { Zapisz plik binarny }
procedure xLoadFile(const filename : string; var data; size : word);      { Wczytaj plik binarny }
procedure xOpenPakFile(const package_name, internal_name : string;        { Otworz plik z paczki }
    var fd : file; var file_size : longint; var success : boolean);

{//////////////////////////////////////////////////////////}

implementation

(***********************************************************)

function CharArrayToString(const arr : TCharArray) : string;
var
    i : integer;
    s : string;
begin
    s := '';
    i := 0;
    while (i <= 63) and (arr[i] <> #0) do
    begin
        s := s + arr[i];
        Inc(i);
    end;
    CharArrayToString := s;
end;

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

procedure xSaveFile(const filename : string; var data; size : word);
var
    fd : file;
begin
    assign(fd, filename);
    rewrite(fd, 1);
    blockWrite(fd, data, size);
    close(fd);
end;

(***********************************************************)

procedure xLoadFile(const filename : string; var data; size : word);
var
    fd: file;
begin
    assign(fd, filename);
    reset(fd, 1);
    blockread(fd, data, size);
    close(fd);
end;

(***********************************************************)

procedure xOpenPakFile(const package_name, internal_name : string; 
                            var fd : file; var file_size : longint; var success : boolean);
var
    h               : THeader;
    pliki           : array[0..99] of TFileInfo;
    i               : integer;
    found           : boolean;
begin
    success := false;
    file_size := 0;
    assign(fd, package_name);
    {$I-}
    reset(fd, 1);
    {$I+}
    if IOResult <> 0 then exit;
    blockread(fd, h, sizeof(h));
    if h.controlNumber <> 329 then
    begin
        close(fd);
        exit;
    end;
    if h.files > 100 then
    begin
        close(fd);
        exit;
    end;
    for i := 0 to h.files - 1 do
        blockread(fd, pliki[i], sizeof(pliki[i]));
    found := false;
    for i := 0 to h.files - 1 do
    begin
        if CharArrayToString(pliki[i].title) = internal_name then
        begin
            found := true;
            file_size := pliki[i].size;
            seek(fd, pliki[i].offset);
            success := true;
            break;
        end;
    end;
    if not found then
        close(fd);
end;

(***********************************************************)

end.
