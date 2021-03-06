{{      
┌──────────────────────────────────────────┐
│ AllSun EM520B IR Thermometer Demo v1.0   │
│ Author: Pat Daderko (DogP)               │               
│ Copyright (c) 2010                       │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

This demonstrates reading object temperatures with an AllSun (http://www.e-sun.cn/) EM520B infrared thermometer.
This has been tested with one rebranded as CEN-TECH #96451 (8:1 distance to spot, plus laser), from Harbor Freight.
There are several models similar to the EM520B, with slightly different specs which may also work, though it's
completely untested as I don't have access to any of them.

This communicates using 5V TTL RS232.  There are 4 pins accessible by removing the battery cover, and the battery
orientation label above the battery.  The pins are on a 2mm header, though I opened the case and soldered a
standard 0.1" header to the 2mm header for easier testing. 

The pins are labeled:
INIT: Unsure, some initialization pin, likely for factory testing (screen momentarily displays Conn when grounded)
RX: Receive
GND: Ground      
TX: Transmit

Since the RS232 pins on the thermometer are 5V, you must add a series resistor on the TX pin (4.7k or so).  This
demo connects it to pin 3.  Ground must be connected to Vss.  The other two pins can be left unconnected.   

To take readings, press the trigger on the thermometer.  This demo constantly listens for new data on the RS232 Rx
pin and displays the object temperature to the debug RS232 port.  I haven't been able to find any good documentation
on this device, so I don't know of any commands to send to it.  I also only reverse engineered the message enough to
know the start of the message, the object temperature, and the checksum.  There are quite a few bytes of data that
aren't decoded in these messages. 
}}

CON
    _clkmode = xtal1 + pll16x                           
    _xinfreq = 5_000_000

OBJ
Ser      :       "FullDuplexSerial"                      ''Used for debug
ThermSer :       "FullDuplexSerial"                      ''Used for communicating to IR Thermometer 

CON
MASTER=0
SLAVE=1

VAR
byte msg[23]

PUB AllSun_Demo|i,checksum,Temp

''Serial communication Setup
    Ser.start(31, 30, 0, 9600)  '' Initialize serial communication to the PC through the USB connector
                                '' To view Serial data on the PC use the Parallax Serial Terminal (PST) program.

    ThermSer.start(3, 4, 0, 9600)    '' Initialize serial communication to the Thermometer (only Rx used)

    repeat 
      repeat while ThermSer.rx <> $33 ''find start of message
      if ThermSer.rx == $15
        checksum:=0 ''initialize checksum
        repeat i from 0 to 22 ''read rest of message bytes
          msg[i]:=ThermSer.rx
          checksum+=msg[i] ''add byte to checksum

        if (checksum+$33+$15-msg[22])&$ff==msg[22] 'checksum passed
          Ser.str(string("Object Temp:"))
          Temp := (msg[15]<<8)|msg[14] ''object temp is bytes 16 and 17 (-2 because $33, $15 not saved) and in little endian
          Ser.dec((Temp/10)-30) ''output whole degrees (in C)
          Ser.tx(".")
          Ser.dec(Temp//10) ''output fraction degrees (in C)
          Ser.str(string("°C"))
          Ser.tx(13)
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