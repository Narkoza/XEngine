program xPackage;

uses crt;

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

    TFileInfoArray = array[0..99] of TFileInfo;

var
    buffer: array[0..1023] of byte;

procedure StringToCharArray(s : string; var arr : TCharArray);
var
    i : integer;
begin
    for i := 0 TO 63 do
        if i < Length(s) then
            arr[i] := s[i+1]
        else
            arr[i] := #0;
end;

function CharArrayToString(arr : TCharArray) : string;
var
    i : integer;
    s : string;
begin
    s := '';
    i := 0;
    while (i < 64) and (arr[i] <> #0) do
    begin
        s := s + arr[i];
        Inc(i);
    end;
    CharArrayToString := s;
end;

procedure Pack;
var
    packTitle       : string;
    h               : THeader;
    pliki           : TFileInfoArray;
    archive         : file;
    myFile          : file;
    i               : integer;
    s               : string;
    numFiles        : integer;
    defaultOffset   : longint;
    size            : longint;
    bytesRead       : word;
    totalBytes      : longint;
begin
    clrscr;

    h.controlNumber := 0329;
    write('Podaj nazwe archiwum z rozszerzeniem: ');
    readln(packTitle);
    write('Podaj liczbe plikow: ');
    readln(numFiles);
    h.files := numFiles;

    for i := 0 to numFiles - 1 do
    begin
        write('Podaj nazwe pliku nr.', i+1, ': ');
        readln(s);
        StringToCharArray(s, pliki[i].title);
    end;

    assign(archive, packTitle);
    rewrite(archive, 1);
    blockwrite(archive, h, SizeOf(THeader));
    defaultOffset := SizeOf(THeader) + numFiles * SizeOf(TFileInfo);

    for i := 0 to numFiles - 1 do
    begin
        assign(myFile, CharArrayToString(pliki[i].title));
        reset(myFile, 1);
        size := FileSize(myFile);
        close(myFile);
        pliki[i].size := size;
        pliki[i].offset := defaultOffset;
        defaultOffset := defaultOffset + size;
    end;

    for i := 0 to numFiles - 1 do
        BlockWrite(archive, pliki[i], SizeOf(TFileInfo));

    for i := 0 TO numFiles - 1 do
    begin
        assign(myFile, CharArrayToString(pliki[i].title));
        reset(myFile, 1);
        totalBytes := 0;

        while totalBytes < pliki[i].size do
        begin
            if pliki[i].size - totalBytes > 1024 then bytesRead := 1024 else bytesRead := pliki[i].size - totalBytes;
            blockread(myFile, buffer, bytesRead);
            blockwrite(archive, buffer, bytesRead);
            totalBytes := totalBytes + bytesRead;
        end;

        close(myFile);
    end;

    close(archive);
    writeln;
    writeln('Liczba plikow: ', h.files, ':');
    writeln;

    for i := 0 to h.files - 1 do
        writeln('Plik ', i+1, ': ', CharArrayToString(pliki[i].title));

    writeln;
    writeln('Gotowe!');
    readkey;
end;

procedure Unpack;
var
    packTitle           : string;
    h                   : THeader;
    pliki               : TFileInfoArray;
    archive             : file;
    ofile               : file;
    i, j                : integer;
    outName             : string;
    totalBytes          : longint;
    bytesRead           : word;
begin
    clrscr;

    write('Podaj nazwe archiwum z rozszerzeniem: ');
    readln(packTitle);
    assign(archive, packTitle);
    reset(archive, 1);
    blockread(archive, h, SizeOf(THeader));

    if h.controlNumber <> 0329 then
    begin
        writeln('Nieprawidlowa suma kontrolna pliku!');
        readkey;
        exit;
    end;

    for i := 0 to h.files - 1 do
        blockread(archive, pliki[i], SizeOf(TFileInfo));

    for j := 0 to h.files - 1 do
    begin
        seek(archive, pliki[j].offset);
        outName := CharArrayToString(pliki[j].title);
        assign(ofile, outName);
        rewrite(ofile, 1);
        totalBytes := 0;

        while totalBytes < pliki[j].size do
        begin
            if pliki[j].size - totalBytes > 1024 then bytesRead := 1024 else bytesRead := pliki[j].size - totalBytes;
            BlockRead(archive, buffer, bytesRead);
            BlockWrite(ofile, buffer, bytesRead);
            totalBytes := totalBytes + bytesRead;
        end;

        close(ofile);
    end;

    close(archive);
    writeln('Gotowe!');
    readkey;
end;

procedure ListContents;
var
    packTitle       : string;
    h               : THeader;
    pliki           : TFileInfoArray;
    archive         : file;
    i               : integer;
begin
    clrscr;

    write('Podaj nazwe archiwum z rozszerzeniem: ');
    readln(packTitle);
    writeln;
    assign(archive, packTitle);
    reset(archive, 1);
    blockread(archive, h, SizeOf(THeader));

    if h.controlNumber <> 0329 then
    begin
        writeln('Nieprawidlowa suma kontrolna pliku!');
        readkey;
        exit;
    end;

    writeln('Zawartosc archiwum: ', packTitle);
    writeln;
    writeln('Liczba plikow: ', h.files);

    for i := 0 to h.files - 1 do
    begin
        blockread(archive, pliki[i], SizeOf(TFileInfo));
        writeln('Plik ', i+1, ': ', CharArrayToString(pliki[i].title), ' (', pliki[i].size, ' bajtow)');
    end;

    close(archive);
    writeln;
    writeln('Gotowe!');
    readkey;
end;

procedure Menu;
var
    key : char;
begin
    repeat
        clrscr;
        writeln('**************************************************');
        writeln('**                                              **');
        writeln('**   XPACKAGE coded by Adam Kozinski (C) 2025   **');
        writeln('**                                              **');
        writeln('**************************************************');
        writeln;
        writeln('WYBIERZ OPCJE: ');
        writeln;
        writeln('[1] Utworz archiwum');
        writeln('[2] Wypakuj archiwum');
        writeln('[3] Wyswietl zawartosc archiwum');
        writeln('[q] Wyjscie');
        writeln;
        write('Wybor: ');
        key := ReadKey;
        writeln;
        case key of
            '1': Pack;
            '2': Unpack;
            '3': ListContents;
            'q': Halt;
        end;
    until key = 'q';
end;

begin
    Menu;
end.