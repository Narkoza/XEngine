program fonttest;

uses crt, xvga256, xfont;

var
   buffer : pointer;

begin
   xSetVGAMode;
   xCreateBuffer(buffer);
   xClearScreen(buffer, 0);
   xLoadFont('font.bmp');

   xText(buffer, 0,0, '.0123456789', 2);
   xText(buffer, 0,10, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 2);
   xText(buffer, 0,20, 'abcdefghijklmnopqrstuvwxyz',2);
   xText(buffer, 0,30, '-+,/*:=_',2);
   xText(buffer, 0,40, '!@#$%^&(){}[];''"<>?\|`~',2);

   xWaitForVertRetrace;
   xCopyBuffer(buffer, ptr(VGA_SEGMENT, 0));
   readkey;
   xFreeBuffer(buffer);
end.