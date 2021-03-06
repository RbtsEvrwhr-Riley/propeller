{
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ MAX451 driver                       │ PG             | (C) 2009            | 22 Nov 2009   |
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│                                                                                            │
│ A driver for the MAX452 16 bit SPI DAC                                                     │
|                                                                                            |   
| See end of file for terms of use                                                           |
└────────────────────────────────────────────────────────────────────────────────────────────┘
 SCHEMATIC
                      ┌────┐      
               Out  │      │ VDD    
               AGND │MAX541│ DGND
               REF  │      │ DIN
               !CS  │      │ SCLK
                      └──────┘      

}

VAR
  long din, sclk, csl, csr

PUB init(_din, _sclk, _csl, _csr)
  din := _din
  sclk := _sclk
  csl := _csl
  csr := _csr

  outa[csl]~~
  outa[csr]~~
  outa[sclk]~
  outa[din]~

  dira[din]~~
  dira[sclk]~~
  dira[csl]~~
  dira[csr]~~

PRI out(value, pin)
  { Assert CS to let chip know we're about to send }
  !outa[pin]

  { Shift out the value, MSB first, with clock }
  repeat 16
    { Output data }
    outa[din] := value & $8000 <> 0
    value <<= 1
      
    { Clock }
    outa[sclk]~~
    outa[sclk]~ 
    
  { Drop CS to finish operation }
  !outa[pin]


PUB stereo(left, right)
  out(left, csl)
  out(right, csr)

DAT
{{
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     TERMS OF USE: MIT License                                       │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and    │
│associated documentation files (the "Software"), to deal in the Software without restriction,        │
│including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,│
│and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,│
│subject to the following conditions:                                                                 │
│                                                                                                     │                        │
│The above copyright notice and this permission notice shall be included in all copies or substantial │
│portions of the Software.                                                                            │
│                                                                                                     │                        │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT│
│LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION│
│WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}