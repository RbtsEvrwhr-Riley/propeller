{{
┌───────────────────────────┐
│ µOLED-128-GMD1 Object     │
├───────────────────────────┴──────────────────┐
│  Width      : 128 Pixels                     │
│  Height     : 128 Pixels                     │
└──────────────────────────────────────────────┘
┌──────────────────────────────────────────┐
│ Copyright (c) 2007 Steve McManus         │               
│     See end of file for terms of use.    │               
└──────────────────────────────────────────┘

Hardware used : 4D Systems  µOLED-128-GMD1                 

Schematics
                         P8X32A
                       ┌────┬────┐              uOLED-128_GDM1
                       ┤0      31├            ┌────────────────┐
                       ┤1      30├            │                │
                       ┤2      29├            │                │           
                       ┤3      28├            │     SCREEN     │
                       ┤4      27├            │      SIDE      │   1 - Vcc +3.3V (+3.3 - +5V)
                   Res ┤5      26├            │                │   2 - TX (P7)    
                   Tx  ┤6      25├            │                │   3 - RX (P6)   
                   Rx  ┤7      24├            │ 5 4 3 2 1      │   4 - GND    
                       ┤VSS   VDD├            └─┬─┬─┬─┬─┬──────┘   5 - Reset-active low (P5) 
                       ┤BOEn   XO├              │  │ │ │                
                       ┤RESn   XI├                ┌─┤     
                       ┤VDD   VSS├                │
                       ┤8      23├                │
                       ┤9      22├            10K   Pullup to avoid noise triggering the autobaud detection 
                       ┤10     21├                │ 
                       ┤11     20├               Vcc/Vdd
                       ┤12     19├ 
                       ┤13     18├ 
                       ┤14     17├ 
                       ┤15     16├ 
                       └─────────┘ 


Information :

NOTE: The transistor switch used in Simon Ampleman's code for an earlier model uOLED from 4D systems has been removed
from the circuit above because the GDM1 modules wait 5 seconds before displaying the splash screen.
If an auto-baud ("U") is received during that time, no splash screen is displayed. 

24 bit to 16 bit color conversion was retained from Simon Ampleman's code, but streamlined into a single expression
 
The real RGB value is encoded with two bytes :

RRRRRGGG GGGBBBBB

However, In the methods I coded, I used a standard 0 to 255 maximum value for each color and then each channel is
approximated to that value. I thought it would be easier for everyone that way.

The demo which accompanies this Object exercises the complete command set for the uOLED-128-GMD1 which includes the
General, Device Specific and Extended commands. The demo is modular in nature and allows the user to customize
the content and order of the demonstrated commands by simply "comment out" unwanted components or reordering
the components to suit their needs.

                                   
Methods :

>>> General Command Set <<<

INIT              - Initialize the OLED at 128000 bauds, must be called before using any other methods
WAITACK           - Wait for acknowledge byte from the RX pin, used after all methods
ADD_BITMAP        - Builds a user-defined bitmapped character(0-31) and RGB value
BACKGROUND        - Set and Paint the background color to RGB value
BUTTON            - Draw a button at X1,Y1 (upper-left corner) with RGB values (button and text), a text string for the button and flag for pushed or not
CIRCLE            - Draw a circle at X,Y (0-128) with radius in pixel, RGB value
BLOCK_COPY        - Copy a block of pixels at X1,Y1 for width and height to X2,Y2
DISPLAY_BITMAP    - Displays a user-defined bitmapped character (0-31) at X,Y and RGB value
ERASE             - Erase the screen
FONT_SIZE         - Set the font size between 0 = 5x7, 1 = 8x8 and 2 = 8x12
TRIANGLE          - Draws a triangle defined by three X,Y vertices defined counter-clockwise
POLYGON_3         - Draws a polygon of 3 vertices, RGB in wire frame only
POLYGON_4         - Draws a polygon of 4 vertices, RGB in wire frame only
POLYGON_5         - Draws a polygon of 5 vertices, RGB in wire frame only
POLYGON_6         - Draws a polygon of 6 vertices, RGB in wire frame only
' The uOLED-128-GDM1 supports POLYGONs with up to 7 verticies, but the  unmodified FullDuplesSerial object limits
' the parameter string to 16 bytes. The command for 7 vertices requires 18 bytes.
IMAGE             - Display an image at X,Y (X = 0-127  Y = 0-127) of width and height in 1 byte per color or 2 byte per color
LINE              - Draw a line from X1,Y1 to X2,Y2 (X = 0-127  Y = 0-127) with RGB value
OPAQUE            - Sets text to be drawn opaque (entire text cell overwrites background)
TRANSPARENT       - Sets text to be drawn transparent (background shows behind text)                     
PUT_PIXEL         - Put a pixel to location X,Y (X = 0-127  Y = 0-127) with RGB value
SOLID             - Sets drawing mode for rectangle, circle, etc. to color-filled
WIRE              - Sets drawing mode for rectangle, circle, etc. to wire frame (not color-filled)
READ_PIXEL        - Read a pixel color value from location X,Y and returnes the color (msb, lsb)
RECTANGLE         - Draw a rectangle from X1,Y1 to X2,Y2 (X = 0-127  Y = 0-127)) with RGB value
UTEXT             - Displays an unformatted strin of characters at X,Y in FONT, Width and Height scaling and RGB value
FTEXT             - Display a string of formatted character at column X, row Y, with font size and RGB value
FCHAR             - Put a "formatted" character at column X, row Y with RGB value
UCHAR             - Put an "unformatted" character at X,Y with RGB value and horizontal and vertical scales values
DISPLAY           - Set the display of the OLED to ON or OFF - * NOT THE SAME AS POWER * "Sleep mode"
CONTRAST          - Set the contrast of the OLED from 0 to 15 (15 default)
FADE_OUT          - Fade out the display by reducing the contrast in a loop
POWER             - Set the power of the OLED to ON or OFF   - * NOT THE SAME AS DISPLAY *
SHUTDOWN          - Shutdown the OLED properly, MUST be called to protect the OLED electronic at the end
DEVICE_INFO       - Displays information about the currently connected display

>>> Display Specific Command Set <<<

OLED_REGISTER     - Permits access to the writable display controller registers
SCROLL_ENABLE     - Enable scrolling of display
SCROLL_CONTROL    - Controlls SPEED of scrolling

>>> Extended Command Set <<<

INIT_uSD          - Initializes the on-board uSD(transflash) card. Must be used if card is hot-plugged
READ_SECTOR       - Read a sector (512 bytes) from the uSD card
WRITE_SECTOR      - Write a sector (512 bytes) to the uSD card
READ_BYTE         - Read a single byte from the uSD card
WRITE_BYTE        - Write a single byte to the uSD card
SET_ADDR          - Sets the address pointer for read/write of uSD card. Pointer is automatically incremented by byte read/write
SCREEN_2_uSD      - Copies an area of the screen to the uSD card from X,Y,Width,Height
DISPLAY_FROM_uSD  - Displays a bitmap image stored on the uSD card at X.Y,Width,Height, color mode
DISPLAY_OBJECT    - Runs an Object (command) stored on the uSD card - see documentation for a list of commands that can be run from the uSD card 
RUN_PROGRAM       - Runs a series of commands stored on the uSD card
RUN_DELAY         - Provides a 1-65,534 mSec delay for RUN_PROGRAM commands stored on the uSD card
SET_COUNTER       - A 1 byte counter that can be used with DEC_COUNTER and JUMP_NOTZERO commands to define loops in RUN_PROGRAM command stored on the uSD card
DEC_COUNTER       - Decrements the loop counter
JUMP_NOTZERO      - Jumps to an address if loop counter is not zero
JUMP_ADDR         - Jumps to a specific address in a series of RUN_PROGRAM commands stored on the uSD card
EXIT              - Exits the series of RUN_PROGRAM commands stored on the uSD card. Can be sent via serial port to cause execution of RUN_PROGRAM commands to halt
 

}}

CON
  
  ACK     = $06                                         ' Acknowledge byte
  NAK     = $15                                         ' Invalid command byte

  RE      = 5                                           ' Reset, Active LOW
  TX      = 6                                           ' Transmit pin
  RX      = 7                                           ' Receive pin

VAR

  byte Dev_Info[5]
  
OBJ
  SERIAL  : "FullDuplexSerial"
  DELAY   : "Clock"

PUB INIT
  SERIAL.start (RX,TX,%0000,256000)

  DELAY.PauseMSec(200)
  ' Initialize OLED
  SERIAL.rxflush
  DELAY.PauseMSec(20)
  SERIAL.tx ("U")
  WAITACK
  DELAY.PauseMSec(20)
  ERASE

PRI WAITACK | temp
  'DELAY.PauseMSec(10)
  REPEAT
    temp := SERIAL.rxtime(500)
    if (temp == ACK)
      quit
    else
      SERIAL.rxflush

PUB AUTO_BAUD
  SERIAL.tx ("U")
  WAITACK
  
PUB RESET
  DIRA[RE] := 1                 
  OUTA[RE] := 0                 'Device Reset
  DELAY.PauseMSec(500)
  OUTA[RE] := 1
  DELAY.PauseMSec(1000)
  
PUB ADD_BITMAP (Chr,Data1,Data2,Data3,Data4,Data5,Data6,Data7,Data8)            ' "A"
  ' Chr#  : 0 to 31
  ' Data1 - Data8 (8 hex bytes for 8x8 char cell)
  SERIAL.tx ("A")
  SERIAL.tx  (Data1)
  SERIAL.tx  (Data2)
  SERIAL.tx  (Data3)
  SERIAL.tx  (Data4)
  SERIAL.tx  (Data5)
  SERIAL.tx  (Data6)
  SERIAL.tx  (Data7)
  SERIAL.tx  (Data8)
  WAITACK

PUB BACKGROUND (R,G,B)                                                          ' "B"                                                   '
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255

  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  
  'G := (G >> 2) << 5
  'B := G + B >> 3
  'R := B + (R >> 3) << 11
  SERIAL.tx ("B")
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK
  
PUB BUTTON (STATE,X1,Y1,BtnR,BtnG,BtnB,FONT,TxtR,TxtG,TxtB,WIDTH,HEIGHT,STR)    ' "b"
  '    X1 : 0 to 127
  '    Y1 : 0 to 127
  '  BtnR : 0 to 255     Buttom color
  '  BtnG : 0 to 255
  '  BtnB : 0 to 255
  '  FONT : 0 = 5x7, 1 = 8x8, 2 = 8x12 font
  '  TxtR : 0 to 255     Text color color
  '  TxtG : 0 to 255
  '  TxtB : 0 to 255  
  ' WIDTH : Scaling factor for text size
  ' HEIGHT: Scaling factor for text size
  '   STR : Character string for button text 
  ' STATE : 0 = DOWN (pressed), 1 = UP (not pressed)
  'NOTE: OPAQUE/TRANSPARENT setting effects text apearance on Button

  BtnR := BtnR >> 3 << 11 | (BtnG >> 2 << 5) | (BtnB >> 3)
  TxtR := TxtR >> 3 << 11 | (TxtG >> 2 << 5) | (TxtB >> 3)
    
  SERIAL.tx ("b")    
  SERIAL.tx (STATE)
  SERIAL.tx (X1)
  SERIAL.tx (Y1)
  SERIAL.tx (BtnR.byte[1])
  SERIAL.tx (BtnR.byte[0])
  SERIAL.tx (FONT)
  SERIAL.tx (TxtR.byte[1])
  SERIAL.tx (TxtR.byte[0])
  SERIAL.tx (WIDTH)
  SERIAL.tx (HEIGHT)
  REPEAT strsize(STR)
    SERIAL.tx (byte[STR++])
  SERIAL.tx (0)
  WAITACK 

PUB CIRCLE (X,Y, RADIUS, R, G, B)                                               ' "C"
  '     X : 0 to 127
  '     Y : 0 to 127
  ' RADIUS: 0 to < X or Xmax - X and < Y or Ymax - Y, whichever is less
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255

  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  SERIAL.tx ("C")    
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (RADIUS)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0]) 
  WAITACK

PUB BLOCK_COPY (Xs,Ys, Xd,Yd, WIDTH,HEIGHT)                                     ' "c"
  '    Xs : 0 to 127 (X,Y upper-left corner of source block)
  '    Ys : 0 to 127
  '    Xd : 0 to 127 (X,Y upper-left corner of destination block)
  '    Yd : 0 to 127
  ' WIDTH : 0 to 127 (Width of source block)
  'HEIGHT : 0 to 127 (Height of source block)
  
  SERIAL.tx ("c")    
  SERIAL.tx (Xs)
  SERIAL.tx (Ys)
  SERIAL.tx (Xd)
  SERIAL.tx (Yd)
  SERIAL.tx (WIDTH)
  SERIAL.tx (HEIGHT)
  WAITACK

PUB DISPLAY_BITMAP (Chr, X, Y, R, G, B)                                         ' "D"
  '   Chr : 0 to 31 (User-defined bitmapped character - see ADDBITMAP cmd)      
  '     X : 0 to 127
  '     Y : 0 to 127
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255

  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  SERIAL.tx ("D")
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])      
  WAITACK
  
PUB ERASE                                                                       ' "E"
  SERIAL.tx ("E")
  WAITACK

PUB FONT_SIZE (MODE)                                                            ' "F"
  ' MODE = 0 : 5x7  font
  ' MODE = 1 : 8x8  font
  ' MODE = 2 : 8x12 font
    
  SERIAL.tx ("F")    
  SERIAL.tx (MODE)    
  WAITACK

PUB TRIANGLE (X1, Y1, X2, Y2, X3, Y3, R, G, B)                                  ' "G"
  '    X1 : 0 to 127 
  '    Y1 : 0 to 127  
  '    X2 : 0 to 127
  '    Y2 : 0 to 127
  '    X3 : 0 to 127
  '    Y3 : 0 to 127
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  ' Three vertices of a triangle (must be defined in a counter-clockwise manner,  
  ' i.e. X2 < X1, X3 > X2, Y2 > Y1, Y3 > Y1)
  ' Solid or Wire Frame drawing is controlled by the Pen setting (see SOLID and WIRE below)
  
  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  SERIAL.tx ("G")    
  SERIAL.tx (X1)
  SERIAL.tx (Y1)
  SERIAL.tx (X2)
  SERIAL.tx (Y2)
  SERIAL.tx (X3)
  SERIAL.tx (Y3)  
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK  

PUB POLYGON_3 (X1,Y1, X2,Y2, X3,Y3, R,G,B)                                      ' "g"
  'VERTICES : Number of vertices of the polygon
  '      X1 : 0 to 159   
  '      Y1 : 0 to 127   
  '      Xn : 0 to 159
  '      Yn : 0 to 127
  '    Red : 0 to 255
  '  Green : 0 to 255
  '   Blue : 0 to 255
  ' Currently, only a wire frame polygon is supported.
  
  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  SERIAL.tx ("g")
  SERIAL.tx (3)    
  SERIAL.tx (X1)
  SERIAL.tx (Y1)
  SERIAL.tx (X2)
  SERIAL.tx (Y2)
  SERIAL.tx (X3)
  SERIAL.tx (Y3)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK  

PUB POLYGON_4 (X1,Y1, X2,Y2, X3,Y3, X4,Y4, R,G,B)                               ' "g"
  'VERTICES : Number of vertices of the polygon
  '      X1 : 0 to 159   
  '      Y1 : 0 to 127   
  '      Xn : 0 to 159
  '      Yn : 0 to 127
  '    Red : 0 to 255
  '  Green : 0 to 255
  '   Blue : 0 to 255
  ' Currently, only a wire frame polygon is supported.
  
  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  SERIAL.tx ("g")
  SERIAL.tx (4)    
  SERIAL.tx (X1)
  SERIAL.tx (Y1)
  SERIAL.tx (X2)
  SERIAL.tx (Y2)
  SERIAL.tx (X3)
  SERIAL.tx (Y3)
  SERIAL.tx (X4)
  SERIAL.tx (Y4)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK  

PUB POLYGON_5 (X1,Y1, X2,Y2, X3,Y3, X4,Y4, X5,Y5, R,G,B)                        ' "g"
  'VERTICES : Number of vertices of the polygon
  '      X1 : 0 to 159   
  '      Y1 : 0 to 127   
  '      Xn : 0 to 159
  '      Yn : 0 to 127
  '    Red : 0 to 255
  '  Green : 0 to 255
  '   Blue : 0 to 255
  ' Currently, only a wire frame polygon is supported.
  
  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  SERIAL.tx ("g")
  SERIAL.tx (5)    
  SERIAL.tx (X1)
  SERIAL.tx (Y1)
  SERIAL.tx (X2)
  SERIAL.tx (Y2)
  SERIAL.tx (X3)
  SERIAL.tx (Y3)
  SERIAL.tx (X4)
  SERIAL.tx (Y4)
  SERIAL.tx (X5)
  SERIAL.tx (Y5)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK  

PUB POLYGON_6 (X1,Y1, X2,Y2, X3,Y3, X4,Y4, X5,Y5, X6,Y6, R,G,B)                 ' "g"
  'VERTICES : Number of vertices of the polygon
  '      X1 : 0 to 159   
  '      Y1 : 0 to 127   
  '      Xn : 0 to 159
  '      Yn : 0 to 127
  '    Red : 0 to 255
  '  Green : 0 to 255
  '   Blue : 0 to 255
  ' Currently, only a wire frame polygon is supported.
  
  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  SERIAL.tx ("g")
  SERIAL.tx (6)    
  SERIAL.tx (X1)
  SERIAL.tx (Y1)
  SERIAL.tx (X2)
  SERIAL.tx (Y2)
  SERIAL.tx (X3)
  SERIAL.tx (Y3)
  SERIAL.tx (X4)
  SERIAL.tx (Y4)
  SERIAL.tx (X5)
  SERIAL.tx (Y5)
  SERIAL.tx (X6)
  SERIAL.tx (Y6)  
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK  

PUB IMAGE (X, Y, WIDTH, HEIGHT, COLOUR_MODE, PIXEL) | CCNT                      ' "T"
  ' COLOUR_MODE : 8 -> 256 colour mode, 1 byte per pixel
  '              16 -> 65K colour mode, 2 bytes per pixel
  SERIAL.tx ("I")
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (WIDTH)
  SERIAL.tx (HEIGHT)
  SERIAL.tx (COLOUR_MODE)
  CCNT := 0
  REPEAT WIDTH * HEIGHT * (COLOUR_MODE / 8)
    SERIAL.tx (BYTE[CCNT++ +PIXEL])
  SERIAL.tx (0)
  WAITACK  

PUB LINE (X1, Y1, X2, Y2, R, G, B)                                              ' "L"
  '    X1 : 0 to 127
  '    Y1 : 0 to 127
  '    X2 : 0 to 127
  '    Y2 : 0 to 127
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  
  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  SERIAL.tx ("L")    
  SERIAL.tx (X1)
  SERIAL.tx (Y1)
  SERIAL.tx (X2)
  SERIAL.tx (Y2)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK

PUB OPAQUE                                                                      ' "O"
  ' Sets text mode to opaque

  SERIAL.tx ("O")
  SERIAL.tx (1)
  WAITACK

PUB TRANSPARENT                                                                 ' "O"
  ' Sets text mode to transparent

  SERIAL.tx ("O")
  SERIAL.tx (0)
  WAITACK
          
PUB PUT_PIXEL (X,Y,R,G,B)                                                       ' "P"
  '     X : 0 to 127
  '     Y : 0 to 127
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255

  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  SERIAL.tx ("P")
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK    

PUB SOLID                                                                       ' "p"
  ' Sets Solid or Filled drawing mode (Pen size = 0)

  SERIAL.tx ("p")
  SERIAL.tx (0)
  WAITACK

PUB WIRE                                                                        ' "p"
  ' Sets Wire Frame drawing mode (Pen size = 1)

  SERIAL.tx ("p")
  SERIAL.tx (1)
  WAITACK
  
PUB READ_PIXEL (X,Y) : RGB                                                      ' "R"
  '     X : 0 to 127
  '     Y : 0 to 127
  SERIAL.tx ("R")
  SERIAL.tx (X)
  SERIAL.tx (Y)
  WAITACK
  RGB.byte[1] := SERIAL.rx
  RGB.byte[0] := SERIAL.rx

PUB RECTANGLE (X1, Y1, X2, Y2, R, G, B)                                         ' "r"
  '    X1 : 0 to 127
  '    Y1 : 0 to 127
  '    X2 : 0 to 127
  '    Y2 : 0 to 127
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  ' Solid or Wire Frame drawing is controlled by the Pen setting (see SOLID and WIRE above)
    
  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  SERIAL.tx ("r")    
  SERIAL.tx (X1)
  SERIAL.tx (Y1)
  SERIAL.tx (X2)
  SERIAL.tx (Y2)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK  

PUB UTEXT (X,Y, FONT, R,G,B, WIDTH, HEIGHT, STR,TYPE)                           ' "S"
  '     X : 0 to 127
  '     Y : 0 to 127
  '  FONT : 0 = 5x7, 1 = 8x8, 2 = 8x12
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  ' WIDTH : Scaling factor - X times normal character width
  'HEIGHT : Scaling factor - X times normal character height
  '   STR : Null-terminated string
  '  TYPE : 0 = Text, 1 = Number (Numeric variable)
  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  SERIAL.tx ("S")
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (FONT)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  SERIAL.tx (WIDTH)
  SERIAL.tx (HEIGHT)
  IF NOT TYPE
    REPEAT strsize(STR)
      SERIAL.tx (byte[STR++])
  ELSE
    SERIAL.dec(STR)
  SERIAL.tx (0)
  WAITACK 
  
PUB FTEXT (COL,ROW, FONT, R,G,B, STR, TYPE)                                     ' "s"
  '   COL : 0-20 in 5x7,   0-15 in 8x8 and 8x12
  '   ROW : 0-15 in 5x7 and 8x8, 0-9 in 8x12
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  '  FONT : 0 = 5x7, 1 = 8x8, 2 = 8x12
  '  TEXT : Null-terminated string
  '  TYPE : 0 = Text, 1 = Number (Numeric word variable)
  
  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  SERIAL.tx ("s")
  SERIAL.tx (COL)
  SERIAL.tx (ROW)
  SERIAL.tx (FONT)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  If NOT TYPE
    REPEAT strsize(STR)
      SERIAL.tx (byte[STR++])
  ELSE
    SERIAL.dec(STR)
  SERIAL.tx (0)
  WAITACK 

PUB FCHAR (CHAR, COL, ROW, R, G, B)                                             ' "T"
  '   COL : 0-20 in 5x7,   0-15 in 8x8 and 8x12
  '   ROW : 0-15 in 5x7 and 8x8, 0-9 in 8x12
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  '  CHAR : character to output
  
  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  SERIAL.tx ("T")
  SERIAL.tx (CHAR)
  SERIAL.tx (COL)
  SERIAL.tx (ROW)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK 

PUB UCHAR (CHAR, X, Y, R, G, B, WIDTH, HEIGHT)                                  ' "t"
  '     X : 0-127
  '     Y : 0-127
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  '  CHAR : character to output
  ' WIDTH : Scaling factor - X times normal character width
  'HEIGHT : Scaling factor - X times normal character height
  
  R := R >> 3 << 11 | (G >> 2 << 5) | (B >> 3)
  SERIAL.tx ("t")
  SERIAL.tx (CHAR)
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  SERIAL.tx (WIDTH)
  SERIAL.tx (HEIGHT)
  WAITACK 
  
PUB DISPLAY (mode)                                                              ' "Y"
  ' Mode : 0 - OFF
  '        1 - ON
  ' NOTE: This command turns off all pixels (minimum power), but does not power off the unit. see POWER cmd.
  SERIAL.tx ("Y")
  SERIAL.tx (1)
  SERIAL.tx (mode)      

PUB CONTRAST (value)                                                            ' "Y"
  ' value : 0 to 15
  SERIAL.tx ("Y")
  SERIAL.tx (2)
  SERIAL.tx (value)
  WAITACK

PUB FADE_OUT (tdelay) | Temp
    REPEAT Temp from 15 to 0
      CONTRAST(Temp)
      DELAY.PauseMSec(400)
         
PUB POWER (mode)                                                                ' "Y"
  ' Mode : 0 - Power Down
  '        1 - Power Up
  SERIAL.tx ("Y")
  SERIAL.tx (3)
  SERIAL.tx (mode)
  WAITACK
  
PUB SHUTDOWN
  POWER(0)

PUB DEVICE_INFO(OUTPUT,TYPE, HW,SW, X,Y) | count                                 ' "V"
  'OUTPUT: 0 = Serial port only   1 = Serial port and device screen
  ' Displays and/or returns the following device information:
  ' Device type: OLED, LCD, VGA
  ' Hardware Rev.
  ' Software Rev.
  ' Horizontal resolution (in pixels)
  ' Vertical resolution (in pixels)
  
  SERIAL.tx ("V")
  SERIAL.tx (OUTPUT)

   REPEAT count from 0 to 4
    Dev_Info.byte[count] := SERIAL.rx

  WORD[TYPE] := Dev_Info.byte[0]
  WORD[HW] := Dev_Info.byte[1]
  WORD[SW] := Dev_Info.byte[2]
  WORD[X] := Dev_Info.byte[3]
  WORD[Y] := Dev_Info.byte[4]

PUB OLED_REGISTER (REGDATA,MODE)                                                ' "$", "W"
  ' REGDATA : Register number of Data (depending on MODE)
  '    MODE : 0 = REGDATA is OLED internal register address, 1 = REGDATA is data for selected register                                                    ' "$", "W"
  'see datasheet at www.4dsystems.com.au/micro-OLED/OLED-128/data/SSD1339.pdf for register details
  SERIAL.tx ("$")
  SERIAL.tx ("W")
  SERIAL.tx (REGDATA)
  SERIAL.tx (MODE)
  WAITACK

PUB SCROLL_ENABLE (MODE)                                                        ' "$", "S"
  ' Mode : 0 = Disable
  '        1 = Enable
  
  SERIAL.tx ("$")
  SERIAL.tx ("S")
  SERIAL.tx (0)     'Register
  SERIAL.tx (MODE)
  WAITACK

PUB SCROLL_SPEED (SPEED)                                                        ' "$", "S"
  'SPEED: 1 = Fast, 2 = Normal, 3 = Slow
  
  SERIAL.tx ("$")
  SERIAL.tx ("S")
  SERIAL.tx (2)     'Register
  SERIAL.tx (SPEED)
  WAITACK

PUB DIM_SCREEN_AREA (X,Y, WIDTH,HEIGHT)                                         ' "$", "D"
  ' Dims a portion of the screen defined by X,Y : Upper-left corner, Width and Height of area in pixels
  SERIAL.tx ("$")
  SERIAL.tx ("D")
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (WIDTH)
  SERIAL.tx (HEIGHT)
  WAITACK

PUB INIT_uSD                                                                    ' "@", "i"
  'Initializes the uSD card(only required if uSD card is inserted after PowerUp or Reset)
  SERIAL.tx ("@")
  SERIAL.tx ("i")
  WAITACK
           
PUB READ_SECTOR(S_ADDR, SECTOR_DATA) | Temp                                     ' "@", "R"
  'Reads a 512 byte sector from the uSD card. Returns ACK($06) upom completion
  'S_ADDR is the address of a LOND defined in the calling prog containing the Sector Address
  'SECTOR_DATA is the address of a 512 byte buffer defined in the calling program.
  'Returns ACK($06) upon completion   
  SERIAL.tx ("@")
  SERIAL.tx ("R")
    Temp := 0
  REPEAT Temp from 2 to 0
    SERIAL.tx(BYTE[S_ADDR][Temp])

  Temp := 0
  REPEAT 512
    BYTE[SECTOR_DATA][Temp++] := SERIAL.rx

  WAITACK
        
PUB WRITE_SECTOR(S_ADDR, SECTOR_DATA) | Temp                                    ' "@", "W"
  'Writes a 512 byte sector of data to the uSD card.
  'S_ADDR is the address of a LOND defined in the calling prog containing the Sector Address
  'SECTOR_DATA is the address of a 512 byte buffer defined in the calling program.    
  'Blocks less that 512 bytes musy be padded with $00 or $ff (it can be any character.value)       
  'Returns ACK($06) upon completion
  SERIAL.tx ("@")
  SERIAL.tx ("W")
  Temp := 0
  REPEAT Temp from 2 to 0
    SERIAL.tx(BYTE[S_ADDR][Temp])
  
  Temp := 0
  REPEAT 512
    SERIAL.tx(BYTE[SECTOR_DATA][Temp ++])

  WAITACK
PUB READ_BYTE : RESULT                                                          ' "@", "r"
  'Reads one byte from the uSD card at address set by the SET_ADDR command
  'The Memory Address pointer is automatically incremented to the next address location
  SERIAL.tx("@")
  SERIAL.tx("r")
  RESULT := SERIAL.rx 
  
PUB WRITE_BYTE(DATA)                                                            ' "@", "w"
  'Writes one byte of data to the uSD card at address set by the SET_ADDR command
  'The Memory Address pointer is automatically incremented to the next address location

  SERIAL.tx("@")
  SERIAL.tx("w")
  SERIAL.tx(DATA)

  WAITACK
        
PUB SET_ADDR(M_ADDR) | Temp                                                     ' "@", "A"
  'M_ADDR is the address of a LONG defined in the calling prog containing the 4 byte memory card address
  'Sets the initial card Memory Address Pointer for READ_BYTE and WRITE_BYTE operations

  SERIAL.tx ("@")
  SERIAL.tx ("A")
    
  REPEAT Temp from 3 to 0
    SERIAL.tx(BYTE[M_ADDR][Temp])
    
  WAITACK
           
PUB SCREEN_2_uSD(X,Y, WIDTH,HEIGHT, S_ADDR) | Temp                              ' "@", "C"
  '      X : 0 to 127
  '      Y : 0 to 127
  '  WIDTH : 0 to 127
  ' HEIGHT : 0 to 127
  ' S_ADDR : See READ_SECTOR above
  SERIAL.tx ("@")
  SERIAL.tx ("C")
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (WIDTH)
  SERIAL.tx (HEIGHT)
   
  REPEAT Temp from 2 to 0
    SERIAL.tx(BYTE[S_ADDR][Temp])

  WAITACK
     
PUB DISPLAY_FROM_uSD(X,Y, WIDTH,HEIGHT, MODE, S_ADDR) | Temp                    ' "@", "I"
  '      X : 0 to 127
  '      Y : 0 to 127
  '  WIDTH : 0 to 127
  ' HEIGHT : 0 to 127
  '   MODE : Color Mode - 8 = 256 color, 16 = 65K colors
  ' S_ADDR : See READ_SECTOR above

  SERIAL.tx ("@")
  SERIAL.tx ("I")
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (WIDTH)
  SERIAL.tx (HEIGHT)
  SERIAL.tx (MODE) 
  REPEAT Temp from 2 to 0
    SERIAL.tx(BYTE[S_ADDR][Temp])

  WAITACK
  
PUB DISPLAY_OBJECT(M_ADDR) | Temp                                               ' "@", "O"
  'Runs a single Object (Icon or Command) stored on the uSD card
  'The 32 bit address of the Object (Icon, Command) on the uSD card must be known to use this command
  SERIAL.tx ("@")
  SERIAL.tx ("O")
    
  REPEAT Temp from 3 to 0
    SERIAL.tx(M_ADDR.byte[Temp])
  WAITACK
      
PUB RUN_PROGRAM(M_ADDR) | Temp                                                  ' "@", "P"
  'Runs a Program (series of Objects (Icons, Commands)) stored on the uSD card
  'The 32 bit address of the first Object (Icon, Command) on the uSD card must be known to use this command

  SERIAL.tx ("@")
  SERIAL.tx ("P")
    
  REPEAT Temp from 3 to 0
    SERIAL.tx(M_ADDR.byte[Temp])
  WAITACK
        
PUB EXIT                                                                        ' "$0C"
  'This command terminates a Program sunninf on the uSD card (see RUN_PROGRAM above)
  'It may be stored on the uSD card as a command or sent via the serial interface to halt execution
  'of a Program executing from the uSD card.

  SERIAL.tx ($0C)

  WAITACK

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
                