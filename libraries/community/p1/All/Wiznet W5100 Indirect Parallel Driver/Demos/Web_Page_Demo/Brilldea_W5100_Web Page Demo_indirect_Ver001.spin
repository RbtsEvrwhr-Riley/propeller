''**************************************
''
''  Brilldea W5100 Web Page Demo indirect Ver. 00.1
''
''  Timothy D. Swieter, P.E.
''  Brilldea - purveyor of prototyping goods
''  www.brilldea.com
''
''  Copyright (c) 2010 Timothy D. Swieter, P.E.
''  See end of file for terms of use and MIT License
''
''  Updated: June 26, 2010
''
''Description:
''
''      This is a demo of serving a web page using the W5100 IC and a Indirect Driver program in the Propeller. 
''
''Reference:
''
''To do:
''
''Revision Notes:
'' 0.1 Start of design
''
''**************************************
CON               'Constants to be located here
'***************************************                       
  '***************************************
  ' Firmware Version
  '***************************************
  FWmajor       = 0
  FWminor       = 1

DAT
  TxtFWdate   byte "June 26, 2010",0
  
CON

  '***************************************
  ' Processor Settings
  '***************************************
  _clkmode = xtal1 + pll16x     'Use the PLL to multiple the external clock by 16
  _xinfreq = 5_000_000          'An external clock of 5MHz. is used (80MHz. operation)

  '***************************************
  ' System Definitions     
  '***************************************

  _OUTPUT       = 1             'Sets pin to output in DIRA register
  _INPUT        = 0             'Sets pin to input in DIRA register  
  _HIGH         = 1             'High=ON=1=3.3V DC
  _ON           = 1
  _LOW          = 0             'Low=OFF=0=0V DC
  _OFF          = 0
  _ENABLE       = 1             'Enable (turn on) function/mode
  _DISABLE      = 0             'Disable (turn off) function/mode

{
  '***************************************
  ' I/O Definitions of PropNET Module
  '***************************************

  '~~~~Propeller Based I/O~~~~
  'W5100 Module Interface
  _WIZ_data0    = 0             'SPI Mode = MISO, Indirect Mode = data bit 0.
  _WIZ_miso     = 0
  _WIZ_data1    = 1             'SPI Mode = MOSI, Indirect Mode = data bit 1.
  _WIZ_mosi     = 1
  _WIZ_data2    = 2             'SPI Mode unused, Indirect Mode = data bit 2 dependent on solder jumper on board.
  _WIZ_data3    = 3             'SPI Mode = SCLK, Indirect Mode = data bit 3.
  _WIZ_sclk     = 3
  _WIZ_data4    = 4             'SPI Mode unused, Indirect Mode = data bit 4 dependent on solder jumper on board.
  _WIZ_data5    = 5             'SPI Mode unused, Indirect Mode = data bit 5 dependent on solder jumper on board.
  _WIZ_data6    = 6             'SPI Mode unused, Indirect Mode = data bit 6 dependent on solder jumper on board.
  _WIZ_data7    = 7             'SPI Mode unused, Indirect Mode = data bit 7 dependent on solder jumper on board.
  _WIZ_addr0    = 8             'SPI Mode unused, Indirect Mode = address bit 0 dependent on solder jumper on board.
  _WIZ_addr1    = 9             'SPI Mode unused, Indirect Mode = address bit 1 dependent on solder jumper on board.
  _WIZ_wr       = 10            'SPI Mode unused, Indirect Mode = /write dependent on solder jumper on board.
  _WIZ_rd       = 11            'SPI Mode unused, Indirect Mode = /read dependent on solder jumper on board.
  _WIZ_cs       = 12            'SPI Mode unused, Indirect Mode = /chip select dependent on solder jumper on board.
  _WIZ_int      = 13            'W5100 /interrupt dependent on solder jumper on board.  Shared with _OW.
  _WIZ_rst      = 14            'W5100 chip reset.
  _WIZ_scs      = 15            'SPI Mode SPI Slave Select, Indirect Mode unused dependent on solder jumper on board.

  'I2C Interface
  _I2C_scl      = 28            'Output for the I2C serial clock
  _I2C_sda      = 29            'Input/output for the I2C serial data  

  'Serial/Programming Interface (via Prop Plug Header)
  _SERIAL_tx    = 30            'Output for sending misc. serial communications via a Prop Plug
  _SERIAL_rx    = 31            'Input for receiving misc. serial communications via a Prop Plug
}
  '***************************************
  ' I/O Definitions of Spinneret Web Server Module
  '***************************************

  '~~~~Propeller Based I/O~~~~
  'W5100 Module Interface
  _WIZ_data0    = 0             'SPI Mode = MISO, Indirect Mode = data bit 0.
  _WIZ_miso     = 0
  _WIZ_data1    = 1             'SPI Mode = MOSI, Indirect Mode = data bit 1.
  _WIZ_mosi     = 1
  _WIZ_data2    = 2             'SPI Mode SPI Slave Select, Indirect Mode = data bit 2
  _WIZ_scs      = 2             
  _WIZ_data3    = 3             'SPI Mode = SCLK, Indirect Mode = data bit 3.
  _WIZ_sclk     = 3
  _WIZ_data4    = 4             'SPI Mode unused, Indirect Mode = data bit 4 
  _WIZ_data5    = 5             'SPI Mode unused, Indirect Mode = data bit 5 
  _WIZ_data6    = 6             'SPI Mode unused, Indirect Mode = data bit 6 
  _WIZ_data7    = 7             'SPI Mode unused, Indirect Mode = data bit 7 
  _WIZ_addr0    = 8             'SPI Mode unused, Indirect Mode = address bit 0 
  _WIZ_addr1    = 9             'SPI Mode unused, Indirect Mode = address bit 1 
  _WIZ_wr       = 10            'SPI Mode unused, Indirect Mode = /write 
  _WIZ_rd       = 11            'SPI Mode unused, Indirect Mode = /read 
  _WIZ_cs       = 12            'SPI Mode unused, Indirect Mode = /chip select 
  _WIZ_int      = 13            'W5100 /interrupt
  _WIZ_rst      = 14            'W5100 chip reset
  _WIZ_sen      = 15            'W5100 low = indirect mode, high = SPI mode, floating will = high.

  _DAT0         = 16
  _DAT1         = 17
  _DAT2         = 18
  _DAT3         = 19
  _CMD          = 20
  _SD_CLK       = 21
  
  _SIO          = 22            

  _LED          = 26            'UI - combo LED and buttuon
  
  _AUX0         = 24            'MOBO Interface
  _AUX1         = 25
  _AUX2         = 26
  _AUX3         = 27

  'I2C Interface
  _I2C_scl      = 28            'Output for the I2C serial clock
  _I2C_sda      = 29            'Input/output for the I2C serial data  

  'Serial/Programming Interface (via Prop Plug Header)
  _SERIAL_tx    = 30            'Output for sending misc. serial communications via a Prop Plug
  _SERIAL_rx    = 31            'Input for receiving misc. serial communications via a Prop Plug

  '***************************************
  ' I2C Definitions
  '***************************************
  _EEPROM0_address = $A0        'Slave address of EEPROM

  '***************************************
  ' Debugging Definitions
  '***************************************
  
  '***************************************
  ' Misc Definitions
  '***************************************
  
  _bytebuffersize = 2048

'**************************************
VAR               'Variables to be located here
'***************************************

  'Configuration variables for the W5100
  byte  MAC[6]                  '6 element array contianing MAC or source hardware address ex. "02:00:00:01:23:45"
  byte  Gateway[4]              '4 element array containing gateway address ex. "192.168.0.1"
  byte  Subnet[4]               '4 element array contianing subnet mask ex. "255.255.255.0"
  byte  IP[4]                   '4 element array containing IP address ex. "192.168.0.13"

  'verify variables for the W5100
  byte  vMAC[6]                 '6 element array contianing MAC or source hardware address ex. "02:00:00:01:23:45"
  byte  vGateway[4]             '4 element array containing gateway address ex. "192.168.0.1"
  byte  vSubnet[4]              '4 element array contianing subnet mask ex. "255.255.255.0"
  byte  vIP[4]                  '4 element array containing IP address ex. "192.168.0.13"

  long  localSocket             '1 element for the socket number

  'Variables to info for where to return the data to
  byte  destIP[4]               '4 element array containing IP address ex. "192.168.0.16"
  long  destSocket              '1 element for the socket number

  'Misc variables
  byte  data[_bytebuffersize]
  long  stack[50]

  long  PageCount  
  
'***************************************
OBJ               'Object declaration to be located here
'***************************************

  'Choose which driver to use by commenting/uncommenting the driver.  Only one can be chosen.
  ETHERNET      : "Brilldea_W5100_Indirect_Driver_Ver006.spin"

  'The serial terminal to use  
  PST           : "Parallax Serial Terminal.spin"       'A terminal object created by Parallax, used for debugging

  'Utility
  STR           :"STREngine.spin"                       'A string processing utility

'***************************************
PUB main | temp0, temp1, temp2
'***************************************
''  First routine to be executed in the program
''  because it is first PUB in the file

  PauseMSec(2_000)              'A small delay to allow time to switch to the terminal application after loading the device

  '**************************************
  ' Start the processes in their cogs
  '**************************************

  'Start the terminal application
  'The terminal operates at 115,200 BAUD on the USB/COM Port the Prop Plug is attached to
  PST.Start(115_200)

  'Start the W5100 driver
  ETHERNET.StartINDIRECT(_WIZ_data0, _WIZ_addr0, _WIZ_addr1, _WIZ_cs, _WIZ_rd, _WIZ_wr,  _WIZ_rst, _WIZ_sen)

  '**************************************
  ' Initialize the variables
  '**************************************

  'The following variables can be adjusted by the demo user to fit in their particular network application.
  'Note the MAC ID is a locally administered address.   See Wikipedia MAC_Address 
  
  'MAC ID to be assigned to W5100
  MAC[0] := $02
  MAC[1] := $00
  MAC[2] := $00
  MAC[3] := $01
  MAC[4] := $23
  MAC[5] := $45

  'Subnet address to be assigned to W5100
  Subnet[0] := 255
  Subnet[1] := 255
  Subnet[2] := 255
  Subnet[3] := 0

  'IP address to be assigned to W5100
  IP[0] := 192
  IP[1] := 168
  IP[2] := 10
  IP[3] := 75

  'Gateway address of the system network
  Gateway[0] := 192
  Gateway[1] := 168
  Gateway[2] := 10
  Gateway[3] := 1

  'Local socket
  localSocket := 80 

  'Destination IP address - can be left zeros, the TCO demo echoes to computer that sent the packet
  destIP[0] := 0
  destIP[1] := 0
  destIP[2] := 0
  destIP[3] := 0

  destSocket := 80  
  
  '**************************************
  ' Begin
  '**************************************

  'Clear the terminal screen
  PST.Home
  PST.Clear
   
  'Draw the title bar
  PST.Str(string("    Prop/W5100 Web Page Serving Test ", PST#NL, PST#NL))

  'Set the W5100 addresses
  PST.Str(string("Initialize all addresses...  ", PST#NL))  
  SetVerifyMAC(@MAC[0])
  SetVerifyGateway(@Gateway[0])
  SetVerifySubnet(@Subnet[0])
  SetVerifyIP(@IP[0])

  'Addresses should now be set and displayed in the terminal window.
  'Next initialize Socket 0 for being the TCP server

  PST.Str(string("Initialize socket 0, port "))
  PST.dec(localSocket)
  PST.Str(string(PST#NL))

  'Testing Socket 0's status register and display information
  PST.Str(string("Socket 0 Status Register: "))
  ETHERNET.readIND(ETHERNET#_S0_SR, @temp0, 1)

  case temp0
    ETHERNET#_SOCK_CLOSED : PST.Str(string("$00 - socket closed", PST#NL, PST#NL))
    ETHERNET#_SOCK_INIT   : PST.Str(string("$13 - socket initalized", PST#NL, PST#NL))
    ETHERNET#_SOCK_LISTEN : PST.Str(string("$14 - socket listening", PST#NL, PST#NL))
    ETHERNET#_SOCK_ESTAB  : PST.Str(string("$17 - socket established", PST#NL, PST#NL))    
    ETHERNET#_SOCK_UDP    : PST.Str(string("$22 - socket UDP open", PST#NL, PST#NL))

  'Try opening a socket using a ASM method
  PST.Str(string("Attempting to open TCP on socket 0, port "))
  PST.dec(localSocket)
  PST.Str(string("...", PST#NL))
  
  ETHERNET.SocketOpen(0, ETHERNET#_TCPPROTO, localSocket, destSocket, @destIP[0])

  'Wait a moment for the socket to get established
  PauseMSec(500)

  'Testing Socket 0's status register and display information
  PST.Str(string("Socket 0 Status Register: "))
  ETHERNET.readIND(ETHERNET#_S0_SR, @temp0, 1)

  case temp0
    ETHERNET#_SOCK_CLOSED : PST.Str(string("$00 - socket closed", PST#NL, PST#NL))
    ETHERNET#_SOCK_INIT   : PST.Str(string("$13 - socket initalized/opened", PST#NL, PST#NL))
    ETHERNET#_SOCK_LISTEN : PST.Str(string("$14 - socket listening", PST#NL, PST#NL))
    ETHERNET#_SOCK_ESTAB  : PST.Str(string("$17 - socket established", PST#NL, PST#NL))    
    ETHERNET#_SOCK_UDP    : PST.Str(string("$22 - socket UDP open", PST#NL, PST#NL))

  'Try setting up a listen on the TCP socket
  PST.Str(string("Setting TCP on socket 0, port "))
  PST.dec(localSocket)
  PST.Str(string(" to listening", PST#NL))

  ETHERNET.SocketTCPlisten(0)

  'Wait a moment for the socket to listen
  PauseMSec(500)

  'Testing Socket 0's status register and display information
  PST.Str(string("Socket 0 Status Register: "))
  ETHERNET.readIND(ETHERNET#_S0_SR, @temp0, 1)

  case temp0
    ETHERNET#_SOCK_CLOSED : PST.Str(string("$00 - socket closed", PST#NL, PST#NL))
    ETHERNET#_SOCK_INIT   : PST.Str(string("$13 - socket initalized", PST#NL, PST#NL))
    ETHERNET#_SOCK_LISTEN : PST.Str(string("$14 - socket listening", PST#NL, PST#NL))
    ETHERNET#_SOCK_ESTAB  : PST.Str(string("$17 - socket established", PST#NL, PST#NL))    
    ETHERNET#_SOCK_UDP    : PST.Str(string("$22 - socket UDP open", PST#NL, PST#NL))

  PageCount := 0

  'Infinite loop of the server
  repeat

    'Waiting for a client to connect
    PST.Str(string("Waiting for a client to connect....", PST#NL))

    'Testing Socket 0's status register and looking for a client to connect to our server
    repeat while !ETHERNET.SocketTCPestablished(0)

    'Connection established
    PST.Str(string("connection established..."))

    'Initialize the buffers and bring the data over
    bytefill(@data, 0, _bytebuffersize)    
    ETHERNET.rxTCP(0, @data)

    if data[0] == "G"
       
      PageCount++

      PST.Str(string("serving page "))
      PST.dec(PageCount)
      PST.Str(string(PST#NL))
       
      'Send the web page - hardcoded here
      'status lin
      StringSend(0, string("HTTP/1.1 200 OK"))
      StringSend(0, string(PST#NL, PST#LF))
       
      'optional header
      StringSend(0, string("Server: Parallax Spinneret Web Server/demo 1"))
      StringSend(0, string("Connection: close"))
      StringSend(0, string("Content-Type: text/html"))
      StringSend(0, string(PST#NL, PST#LF))
       
      'blank line
      StringSend(0, string(PST#NL, PST#LF))
       
      'File
      StringSend(0, string("<HTML>", PST#NL))
      StringSend(0, string("<HEAD>", PST#NL))
      StringSend(0, string("<TITLE>"))
      StringSend(0, string("Spinneret"))
      StringSend(0, string("</TITLE>", PST#NL))
      StringSend(0, string("</HEAD>", PST#NL))
      StringSend(0, string("<BODY>", PST#NL))
      StringSend(0, string("<H1>"))
      StringSend(0, string("Helloooooo World!!"))
      StringSend(0, string("</H1>", PST#NL))
      StringSend(0, string("<HR>", PST#NL))
      StringSend(0, string("<P>"))  
      StringSend(0, string("A test document from a Parallax Spinneret Web Server"))
      StringSend(0, string("</P>", PST#NL))
      StringSend(0, string("<P>"))  
      StringSend(0, string("This page has been served "))
      StringSend(0, string("<b>"))
      StringSend(0, STR.numberToDecimal(PageCount, 5))
      StringSend(0, string("</b>"))
      StringSend(0, string(" times since powering on of the module"))
      StringSend(0, string("</P>", PST#NL))
      StringSend(0, string("</BODY>", PST#NL))
      StringSend(0, string("</HTML>", PST#NL))
      StringSend(0, string(PST#NL, PST#LF))
       
    PauseMSec(5)

    'End the connection
    ETHERNET.SocketTCPdisconnect(0)

    PauseMSec(10)

    'Connection terminated
    ETHERNET.SocketClose(0)
    PST.Str(string("Connection complete", PST#NL, PST#NL))

    'Once the connection is closed, need to open socket again
    OpenSocketAgain
    
  return 'end of main
  
'***************************************
PRI SetVerifyMAC(_firstOctet)
'***************************************

  'Set the MAC ID and display it in the terminal
  ETHERNET.WriteMACaddress(true, _firstOctet)

  
  PST.Str(string("  Set MAC ID........"))
  PST.hex(byte[_firstOctet + 0], 2)
  PST.Str(string(":"))
  PST.hex(byte[_firstOctet + 1], 2)
  PST.Str(string(":"))
  PST.hex(byte[_firstOctet + 2], 2)
  PST.Str(string(":"))
  PST.hex(byte[_firstOctet + 3], 2)
  PST.Str(string(":"))
  PST.hex(byte[_firstOctet + 4], 2)
  PST.Str(string(":"))
  PST.hex(byte[_firstOctet + 5], 2)
  PST.Str(string(PST#NL))

  'Wait a moment
  PauseMSec(500)
 
  ETHERNET.ReadMACAddress(@vMAC[0])
  
  PST.Str(string("  Verified MAC ID..."))
  PST.hex(vMAC[0], 2)
  PST.Str(string(":"))
  PST.hex(vMAC[1], 2)
  PST.Str(string(":"))
  PST.hex(vMAC[2], 2)
  PST.Str(string(":"))
  PST.hex(vMAC[3], 2)
  PST.Str(string(":"))
  PST.hex(vMAC[4], 2)
  PST.Str(string(":"))
  PST.hex(vMAC[5], 2)
  PST.Str(string(PST#NL))
  PST.Str(string(PST#NL))

  return 'end of SetVerifyMAC

'***************************************
PRI SetVerifyGateway(_firstOctet)
'***************************************

  'Set the Gatway address and display it in the terminal
  ETHERNET.WriteGatewayAddress(true, _firstOctet)

  PST.Str(string("  Set Gateway....."))
  PST.dec(byte[_firstOctet + 0])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 1])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 2])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 3])
  PST.Str(string(PST#NL))

  'Wait a moment
  PauseMSec(500)

  ETHERNET.ReadGatewayAddress(@vGATEWAY[0])
  
  PST.Str(string("  Verified Gateway.."))
  PST.dec(vGATEWAY[0])
  PST.Str(string("."))
  PST.dec(vGATEWAY[1])
  PST.Str(string("."))
  PST.dec(vGATEWAY[2])
  PST.Str(string("."))
  PST.dec(vGATEWAY[3])
  PST.Str(string(PST#NL))
  PST.Str(string(PST#NL))

  return 'end of SetVerifyGateway

'***************************************
PRI SetVerifySubnet(_firstOctet)
'***************************************

  'Set the Subnet address and display it in the terminal
  ETHERNET.WriteSubnetMask(true, _firstOctet)

  PST.Str(string("  Set Subnet......"))
  PST.dec(byte[_firstOctet + 0])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 1])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 2])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 3])
  PST.Str(string(PST#NL))

  'Wait a moment
  PauseMSec(500)

  ETHERNET.ReadSubnetMask(@vSUBNET[0])
  
  PST.Str(string("  Verified Subnet..."))
  PST.dec(vSUBNET[0])
  PST.Str(string("."))
  PST.dec(vSUBNET[1])
  PST.Str(string("."))
  PST.dec(vSUBNET[2])
  PST.Str(string("."))
  PST.dec(vSUBNET[3])
  PST.Str(string(PST#NL))
  PST.Str(string(PST#NL))

  return 'end of SetVerifySubnet

'***************************************
PRI SetVerifyIP(_firstOctet)
'***************************************

  'Set the IP address and display it in the terminal
  ETHERNET.WriteIPAddress(true, _firstOctet)

  PST.Str(string("  Set IP.........."))
  PST.dec(byte[_firstOctet + 0])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 1])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 2])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 3])
  PST.Str(string(PST#NL))

  'Wait a moment
  PauseMSec(500)

  ETHERNET.ReadIPAddress(@vIP[0])
  
  PST.Str(string("  Verified IP......."))
  PST.dec(vIP[0])
  PST.Str(string("."))
  PST.dec(vIP[1])
  PST.Str(string("."))
  PST.dec(vIP[2])
  PST.Str(string("."))
  PST.dec(vIP[3])
  PST.Str(string(PST#NL))
  PST.Str(string(PST#NL))

  return 'end of SetVerifyIP

'***************************************
PRI StringSend(_socket, _dataPtr)
'***************************************

  ETHERNET.txTCP(0, _dataPtr, strsize(_dataPtr))

  return 'end of StringSend

'***************************************
PRI OpenSocketAgain
'***************************************

  ETHERNET.SocketOpen(0, ETHERNET#_TCPPROTO, localSocket, destSocket, @destIP[0])
  ETHERNET.SocketTCPlisten(0)

  return 'end of OpenSocketAgain
  
'***************************************
PRI PauseMSec(Duration)
'***************************************
''  Pause execution for specified milliseconds.
''  This routine is based on the set clock frequency.
''  
''  params:  Duration = number of milliseconds to delay                                                                                               
''  return:  none
  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)

  return  'end of PauseMSec

'***************************************
DAT
'***************************************         

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