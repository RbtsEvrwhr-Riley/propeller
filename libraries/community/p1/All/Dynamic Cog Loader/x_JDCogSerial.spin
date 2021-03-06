{{
JDCogSerial.spin :
┌────────────────────────────────────┐
│   Copyright (c) 2009 Carl Jacobs   │
│ (See end of file for terms of use) │
└────────────────────────────────────┘
}}


OBJ
  ee  : "x_Loader"
  cfg : "x_Config"

VAR
  long cog                             'cog flag/id

  long rx1_buf                         '5 longs
  long tx1_buf
  long rx1_mask
  long tx1_mask
  long baud1_ticks

PUB Start(rxpin, txpin, baudrate) : addr
{{
  ┌─────────────────────────────────────────────────────────────────────┐
  │Purpose:                                                             │
  │  Start a single port serial driver - uses a single cog.             │
  ├─────────────────────────────────────────────────────────────────────┤           
  │Inputs:                                                              │
  │  rxpin and txpin are passed in as pin masks. The transmitter        │
  │    may be disabled by passing in a mask of 0. The receiver may be   │
  │    disabled by simply ignoring it.                                  │
  │  baudrate etc Is passed in as the desired baudrate. The transmit    │
  │    / receive pair operate at the same baudrate.                     │
  ├─────────────────────────────────────────────────────────────────────┤           
  │Output:                                                              │
  │  Returns the address of the shared memory space if a cog was        │
  │  successfully started, or 0 if no cog available.                    │
  └─────────────────────────────────────────────────────────────────────┘
}}
  Stop
  rx1_buf     := -1                    'Set receiver to idle
  tx1_buf     := -1                    'Set transmitter to idle
  rx1_mask    := rxpin                 'Set receive pin
  tx1_mask    := txpin                 'Set transmit pin
  baud1_ticks := CLKFREQ / baudrate    'Set baudrate
  cog := ee.LoadCog(cfg#JDCogSerial, @rx1_buf) + 1  'Start the cog
  if cog
    addr := @rx1_buf

PUB Stop
{{ Stop serial driver - frees the cog that was used }}
  if cog
    cogstop(cog~ - 1)

PUB rxflush
{ Flush receive buffer }
  repeat until rxcheck < 0

PUB rxcheck : rxbyte
{ Check if byte received (never waits)
  returns < 0 if no byte received, $00..$FF if byte }
  if (rxbyte := rx1_buf) => 0
    rx1_buf := -1

PUB rxtime(ms) : rxbyte | t
{ Wait ms milliseconds for a byte to be received
  returns -1 if no byte received, $00..$FF if byte }
  t := cnt
  repeat until (rxbyte := rxcheck) => 0 or (cnt - t) / (clkfreq / 1000) > ms

PUB rx : rxbyte
{ Receive byte (may wait for byte)
  returns $00..$FF }
  repeat while (rxbyte := rx1_buf) < 0
  rx1_buf := -1

PUB tx(txbyte)
{ Send byte (may wait for room in buffer) }
  repeat while tx1_buf => 0
  tx1_buf := txbyte

PUB str(stringptr)
{ Send a string }
  repeat strsize(stringptr)
    tx(byte[stringptr++])

PUB dec(value) | i
{{
  Print a decimal number
}}
  if value < 0
    -value
    tx("-")

  i := 1_000_000_000

  repeat 10
    if value => i
      tx(value / i + "0")
      value //= i
      result~~
    elseif result or i == 1
      tx("0")
    i /= 10

PUB CrLf
{{
  Send a carriage return linefeed combination.
}}
  tx(13)
  tx(10)
  

{{
 ───────────────────────────────────────────────────────────────────────────
                Terms of use: MIT License                                   
 ─────────────────────────────────────────────────────────────────────────── 
   Permission is hereby granted, free of charge, to any person obtaining a  
  copy of this software and associated documentation files (the "Software"),
  to deal in the Software without restriction, including without limitation 
  the rights to use, copy, modify, merge, publish, distribute, sublicense,  
    and/or sell copies of the Software, and to permit persons to whom the   
    Software is furnished to do so, subject to the following conditions:    
                                                                            
   The above copyright notice and this permission notice shall be included  
           in all copies or substantial portions of the Software.           
                                                                            
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER   
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER     
                       DEALINGS IN THE SOFTWARE.                            
 ─────────────────────────────────────────────────────────────────────────── 
}}                        