{{
┌───────────────────────────────────────┐
│ Wintek WD-C2401P Parallel LCD Driver  │
├───────────────────────────────────────┴───────────┐
│  Width      : 24 Characters                       │
│  Height     :  1 Line                             │
│  Interface  :  8 Bit                              │
│  Controller :  HD66717-based                      │
├───────────────────────────────────────────────────┤
│  By      : davel@dsp-services.com                 │
│  Date    : 2010-10-22                             │
│  Version : 1.0                                    │
│  original: http://obex.parallax.com/objects/106/  │
│          : Simon Ampleman                         │
│          : sa@infodev.ca                          │
└───────────────────────────────────────────────────┘

Read the full documentation in LCD-wintek_wd-c2401p-complete
This is the equivalent of Simon's 8 bit object, I've tried
to implement a complete control set in
LCD-wintek_wd-c2401p-complete
If you want to use the custom character capability, you've
got to use the "complete" version.
}}      
        
        
        
CON

  ' Pin assignment
  RS = 16                   
  RW = 17                    
  E  = 18

  DB0 = 15
  DB7 = 8

OBJ

  DELAY : "Timing"
   
PUB START  

  DIRA[DB7..DB0] := %11111111   ' Set everything to output              
  DIRA[RS] := 1
  DIRA[RW] := 1
  DIRA[E] := 1

  INIT 

' Initialize the display controller
' INIT
PRI INIT

  DELAY.pause1ms(15)

  OUTA[DB7..DB0] := %00000000                              
  OUTA[RS] := 0
  OUTA[RW] := 0
  OUTA[E]  := 0
  
  INST (%00011100) ' Turn on the lcd driver power
  INST (%00010100) ' Turn on the character display                                           
  INST (%00101000) ' Set two display lines - even though there is only one                                            
  INST (%01001111) ' Set to darkest contrast                                                     
  INST (%00001100) ' Flash the cursor                                                     
  MOVE(1)
  CLEAR             '

' Send an instruction
' INST (8 bits)
PRI INST (BITS)            
  BUSY
  OUTA[RW] := 0                              
  OUTA[RS] := 0                              
  OUTA[E]  := 1
  OUTA[DB7..DB0] := BITS
  OUTA[E]  := 0                              

' Send data
' DATA (8 bits)
PRI DATA (BITS)
  BUSY
  OUTA[RW] := 0                              
  OUTA[RS] := 1                              
  OUTA[E]  := 1
  OUTA[DB7..DB0] := BITS
  OUTA[E]  := 0  

' Busy - ask the display if it's busy
' BUSY
PRI BUSY | IS_BUSY
    DIRA[DB7..DB0] := %00000000
    OUTA[RW] := 1                              
    OUTA[RS] := 0                              
    REPEAT
      OUTA[E]  := 1
      IS_BUSY := INA[DB7]     
      OUTA[E]  := 0
    WHILE (IS_BUSY == 1)
    DIRA[DB7..DB0] := %11111111

' Clear the display, Return Cursor Home
' CLEAR
PUB CLEAR
  INST (%0000_0001)                                                                               

' Move the cursor to a cell position on the display
' MOVE (position = 1-24)     
PUB MOVE (X) | ADR
    if (X > 12)
        ADR := 16       ' "2nd line" shift by 0x10 
        X := X - 12     ' and set X position accordingly
    else
        ADR := 0
    ADR += (X-1) + 224  ' command base of 11100000
    INST (ADR)

' Display strings
' STR (string)
PUB STR (STRINGPTR)
  REPEAT STRSIZE(STRINGPTR)
    DATA(BYTE[STRINGPTR++])

' Display integer numbers
' INT (integer)                              
PUB INT (VALUE) | TEMP
  IF (VALUE < 0)
    -VALUE
    DATA("-")

  TEMP := 1_000_000_000

  REPEAT 10
    IF (VALUE => TEMP)
      DATA(VALUE / TEMP + "0")
      VALUE //= TEMP
      RESULT~~
    ELSEIF (RESULT OR TEMP == 1)
      DATA("0")
    TEMP /= 10

' Display hexadecimal numbers, with digit places to display
' HEX (number, digits)
PUB HEX (VALUE, DIGITS)

  VALUE <<= (8 - DIGITS) << 2
  REPEAT DIGITS
    DATA(LOOKUPZ((VALUE <-= 4) & $F : "0".."9", "A".."F"))

' Display binary numbers, with digit places to display
' BIN (number, digits)
PUB BIN (VALUE, DIGITS)

  VALUE <<= 32 - DIGITS
  REPEAT DIGITS
    DATA((VALUE <-= 1) & 1 + "0")



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