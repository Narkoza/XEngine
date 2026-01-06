program Joydemo;

uses crt, xjoy, xmouse;

type JoyConfig = record
                     UseJoy : Boolean;
                     JoyDat : TJoystick; { Typ TJoystick z modulu xJoy }
                 end;

var
   Config : JoyConfig;

procedure CalibrateJoystick;
begin
   Delay(100);
   writeln('Rotate joystick and press button...');
   Delay(100);

   repeat
      xJoyCalibrate;
      Write(#13, 'X = ', Byte(JOY_RIGHT) - Byte(JOY_LEFT): 2,
          '  Y = ', Byte(JOY_DOWN) - Byte(JOY_UP): 2);
   until JOY_BUTTON_1 or JOY_BUTTON_2 or KeyPressed;
   writeln;

   if Keypressed then
   begin
      JOY_ENABLED := FALSE;
      xJoyUpdate;
   end;

   Config.UseJoy := JOY_ENABLED;
   Config.JoyDat := Joy; { Przypisujemy zmienna Joy typu TJoystick z modulu xJoy }

   writeln;
   writeln('Config saved!');
   readln;
end;

BEGIN
   clrscr;

   { Sprawdzaj czy mysz jest zainstalowana }
   if not (xMouseInit) then
   begin
        writeln('ERROR: Mouse driver not found!');
        writeln('Please load a DOS mouse driver.');
        readln;
        halt;
   end;

   xJoyInit;          { Wlacz joystick }
   xJoyReset;         { Zresetuj joystick }
   CalibrateJoystick; { Kalibruj joystick }

   while (True) do
   begin
      xMouseUpdate;     { Sprawdzaj status myszy }
      xJoyUpdate;       { Sprawdzaj status joysticka }

      if(JOY_BUTTON_1) then
         writeln('Button 1 pressed!');

      if(JOY_BUTTON_2) then
         writeln('Button 2 pressed!');

      if(JOY_LEFT) then
         writeln('X_Left!');

      if(JOY_RIGHT) then
         writeln('X_Right!');
      
      if(JOY_UP) then
         writeln('Y_Up!');

      if(JOY_DOWN) then
         writeln('Y_Down!');

      if(MOUSE_RIGHT) then
         break;

   end;

   clrscr;
   readln;
END.