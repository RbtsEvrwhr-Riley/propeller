{{┌──────────────────────────────────────────┐
  │ IL3820 ePaper display Demo               │
  │ Author: Chris Gadd                       │
  │ Copyright (c) 2020 Chris Gadd            │
  │ See end of file for terms of use.        │
  └──────────────────────────────────────────┘
  Demonstrates use of the IL3820 ePaper spin and pasm drivers

}}
CON
  _clkmode = xtal1 + pll16x                                                   
  _xinfreq = 5_000_000

  MOSI = 16     ' Data in
  CLK  = 17     ' Clock
  CS   = 18     ' Chip select - active low
  DC   = 19     ' Data=High/Command=Low 
  RST  = 20     ' Reset when low
  BUSY = 21     ' High while busy

OBJ
   disp : "IL3820 ePaper Spin"
   _disp : "IL3820 ePaper PASM"
  
PUB demo | i

   disp.init(CS,MOSI,CLK,DC,BUSY,RST)                   ' Spin-based driver
'  disp.start(CS,MOSI,CLK,DC,BUSY,RST)                  ' PASM-based driver

  disp.clearBitmap
  disp.setColor(disp#BLACK)
  disp.move(3,0)
  disp.str(string("123456789012345678"))
  disp.setColor(disp#WHITE)
  disp.move(2,0)
  disp.str(string("ABCDEFGHIJKLMNOPQR"))
  disp.setColor(disp#BLACK)
  disp.move(1,0)
  disp.str(string("!@#$%^&*()!@#$%^&*"))
  disp.setColor(disp#WHITE)
  disp.move(0,0)
  disp.str(string("abcdefghijklmnopqr"))
  disp.updateDisplay
  disp.sleep

  waitcnt(clkfreq * 5 + cnt)
  disp.clearBitmap
  disp.resetDisplay
  disp.setColor(disp#BLACK)
  i := 0
  repeat
    disp.move(3,0)
    disp.dec(i++)
    disp.updateDisplay
    