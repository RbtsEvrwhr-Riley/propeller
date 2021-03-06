''------------------------------------------------------------------------------------------------
'' Commodore 64 Two Color VGA Display Demo
''
'' Copyright (c) 2018 Mike Christle
'' See end of file for terms of use.
''
'' History:
'' 1.0.0 - 10/10/2018 - Original release.
'' 1.1.0 - 10/31/2018 - Add CChar routine to better control character colors.
'' 1.2.0 - 11/02/2018 - Add blinking cursor.
'' 1.3.0 - 11/12/2018 - Add LineTo routine to draw a series of lines.
''------------------------------------------------------------------------------------------------

CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

OBJ

  C64 : "C64_4C_VGA.spin"
  pst : "Parallax Serial Terminal"

PUB Main | I, J, C

  pst.Start(115200)

  'Set the pin_group number for your board
  C64.Start(2)

  'Backgound and foreground colors
  C64.Color(0, C64#DK_BLUE)
  C64.Color(1, C64#LT_TEAL)
  C64.Color(2, C64#LT_ORANGE)
  C64.Color(3, C64#RED)

  'Character set from 32 to 255
  C := 32
  repeat J from 0 to 13
    C64.Pos(1, J)
    repeat I from 0 to 15
      C64.Char(C)
      C += 1

  'Test String
  C64.Pos(6, 14)
  C64.Str(string("DANGER"), 3, 2)

  '4 pixels in a row
  C64.Pixel(1, 140, 4)
  C64.Pixel(1, 142, 4)
  C64.Pixel(2, 144, 4)
  C64.Pixel(3, 146, 4)

  'A pixel in each corner of the screen
  C64.Pixel(1, 0, 0)
  C64.Pixel(1, 0, C64#HEIGHT - 1)
  C64.Pixel(1, C64#WIDTH - 1, 0)
  C64.Pixel(1, C64#WIDTH - 1, C64#HEIGHT - 1)

  'Line Pattern
  C64.Line(1, 140, 30, 158, 30)
  C64.LineTo(1, 158, 48)
  C64.LineTo(1, 140, 48)
  C64.LineTo(1, 140, 30)
  C64.LineTo(2, 149, 20)
  C64.LineTo(2, 158, 30)
  C64.LineTo(2, 149, 40)
  C64.LineTo(2, 140, 30)

  'Turn on cursor
  C64.Cursor(TRUE)

  repeat

    'Output any characters from the serial port.
    if pst.RxCount > 0
      I := pst.CharIn
      C64.Char(I)

    'Toggle the foreground color and a pixel every 32 frames.
    I := C64.FrameCount
    J := I & $3F
    if J == $00
      C += 1
      C64.Pixel(C, 140, 4)
      C64.Color(3, C64#DK_RED)
      repeat while C64.FrameCount == I

    if J == $20
      C64.Color(3, C64#LT_RED)
      repeat while C64.FrameCount == I

{{
┌──────────────────────────────────────────────────────────────────────────┐
│                       TERMS OF USE: MIT License                          │                                                            
├──────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a   │
│copy of this software and associated documentation files (the "Software"),│
│to deal in the Software without restriction, including without limitation │
│the rights to use, copy, modify, merge, publish, distribute, sublicense,  │
│and/or sell copies of the Software, and to permit persons to whom the     │
│Software is furnished to do so, subject to the following conditions:      │                                                           │
│                                                                          │                                                  │
│The above copyright notice and this permission notice shall be included in│
│all copies or substantial portions of the Software.                       │
│                                                                          │                                                  │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR│
│IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  │
│FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   │
│THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER│
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   │
│FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       │
│DEALINGS IN THE SOFTWARE.                                                 │
└──────────────────────────────────────────────────────────────────────────┘
}}