program SBTest;

uses
  crt, xSound;

var
  wav, wav2 : TWavData;

begin
  ClrScr;

  { Wykrywanie Sound Blaster }
  if not xSBDetect then
    begin
        WriteLn('Sound Blaster not found!');
        Halt(1);
    end
    else
        WriteLn('Sound Blaster found at A', HexStr(sb_base, 3), ' I', sb_irq, ' D', sb_dma);

  { Inicjalizacja Sound Blaster }
  xSBInit;

  { Ustawienie glosnosci (opcjonalne, domyslnie pelna) }
  xSetMasterVolume(255);

  { Ladowanie pliku WAV (zakladajac, ze plik "test.wav" istnieje) }
  xLoadSound(wav, 'test.wav');
  xLoadSound(wav2, 'franko4.wav');

  { Odtwarzanie dzwieku pojedynczego (bez zmiany czestotliwosci probkowania) }
  Writeln('Odtwarzanie dzwieku...');
  xPlaySound(wav2, 5000);

  { Czekanie na nacisniecie klawisza (aby uslyszec dzwiek) }
  Writeln('Nacisnij dowolny klawisz, aby kontynuowac...');
  ReadKey;

  { Odtwarzanie tego samego dzwieku z automatyczna inicjalizacja i nowa czestotliwoscia (opcjonalne) }
  xPlaySound(wav, 22050);  { Zmiana na 22 kHz, jesli chcesz }

  { Czekanie na nacisniecie klawisza (aby uslyszec dzwiek) }
  Writeln('Nacisnij dowolny klawisz, aby kontynuowac...');
  ReadKey;

  xPlaySine(440, 5000); { Graj fale o czestotliwosci 440Hz }

  { Czekanie na nacisniecie klawisza }
  Writeln('Nacisnij dowolny klawisz, aby zakonczyc...');
  ReadKey;

  { Deinicjalizacja Sound Blaster }
  xSBDeinit;

  { Czyszczenie pamieci po dzwiekach }
  FreeMem(wav.data, wav.size);
  FreeMem(wav2.data, wav2.size);

  { Odtwarzanie nuty na glosniku PC (przyklad bez SB) }
  while not KeyPressed do
  begin
    xPlayNote(C, 4, 1000);  { Odtwarzaj przez 1000 tickow (ok. 1 sekunda) }
    xUpdateSound;  { Aktualizuj stan }
    Delay(1000);  { Zakladajac, ze tick to ok. 1ms dla przyblizenia 1 sekundy }
    xPlayPause(500);  { Pauza na 500 tickow (ok. 0.5 sekundy) }
  end;
  ReadKey;  { Zuzyj nacisniety klawisz }

  Writeln('Koniec programu.');
end.