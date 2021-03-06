{{
┌───────────────────────────────────────────┐
│ RFID RFID Read/Write Object Wrapper       │
│ Author: TinkersALot                       │                     
│ Adapted from Joe Grand's BS2 code.        │                     
│ See end of file for terms of use.         │                      
└───────────────────────────────────────────┘

Each RFID card function is tested by entering a specific key on the PST as follows:

Z = test serial number read of legacy card read
S = read new style card serial number
C = try to logon to card (follow the prompts to enter 4 DIGITS password)
D = read all card data (this one seems a bit flakey to me still)
W = write data to card -- not implemented yet in terminal command
P = change the card password ( follow the prompts to enter 4 DIGITS for old and new password ) (needs a bit more testing)
R = Reset the card
U = Unlock the card
L = Lock the card 

}}

CON

  _clkmode      = xtal1 + pll16x                        ' use crystal x 16
  _xinfreq      = 5_000_000

RFID_TX              = 9    ' Connects to RFID R/W Module SIN
RFID_RX              = 10   ' Connects to RFID R/W Module SOUT

                                                                                 
obj

 Host  : "FullDuplexSerial"
 RFID  : "RFID.Reader.Writer.Driver"


var

byte TestBuffer[ 12 ]
byte TestDataBuffer[ 32 * 4 ]
byte OldPwdBuffer[ 4 ]
byte NewPwdBuffer[ 4 ]
byte HostDataBuffer[ 10 ]

PUB TEST_THIS | ErrCheck, CmdByte, LoopCounter, IndexCounter, Offset
{{
  Test this driver 
}}
  ' start the host interface ( connected to PST )
  ' 
  ErrCheck := Host.Start( 29, 28, 0, 19200 )
  if 0 == ErrCheck
    Host.str( string( "Cog Start Error", 13 ) )

  else
    ' since host interface started, the next thing to do is to
    ' call the driver start method to start its I/O interface
    '
    ErrCheck := RFID.Start( RFID_RX, RFID_TX ) 
    if 0 == ErrCheck
      Host.str( string( "Cog Start Error", 13 ) )


  ' if everything worked above, then enter terminal I/O loop
  '
  if ErrCheck <> 0

    Host.str( string( "Ready", 13 ) )
  
    repeat

      CmdByte := Host.Rx

      if CmdByte == $5A   ' Z = Legacy read
        Host.str( string( "Reading Legacy tag's unique serial number...", 13 ) )
        Result := RFID.TryGetLegacyCardNumber( @TestBuffer, 5 ) 
        if Result <> 0
          repeat LoopCounter from 0 to 10
            Host.hex( TestBuffer[ LoopCounter ], 2 )
          Host.str( string( 13 ) )
          Host.str( string( 13 ) )
        else
          Host.str( string( "Failed to read legacy unique serial number...", 13 ) )


      if CmdByte == $53   ' S erial number
        Host.str( string( "Reading tag's unique serial number...", 13 ) )
        Result := RFID.TryGetCardSerialNumber( @TestBuffer, 5 ) 
        if Result <> 0
          repeat LoopCounter from 0 to 4
            Host.hex( TestBuffer[ LoopCounter ], 2 )
          Host.str( string( 13 ) )
          Host.str( string( 13 ) )
        else
          Host.str( string( "Failed to read unique serial number...", 13 ) )


      if CmdByte == $43   ' C ard login
        Host.str( string( "Trying to logon to card...", 13 ) )
        Host.str( string( "Enter 4 digit password", 13 ) )
        OldPwdBuffer[ 0 ] := Host.rx - $30
        OldPwdBuffer[ 1 ] := Host.rx - $30
        OldPwdBuffer[ 2 ] := Host.rx - $30
        OldPwdBuffer[ 3 ] := Host.rx - $30
         Result := RFID.TryCardLogin( @OldPwdBuffer, 5 )
        if Result <> 0
          Host.str( string( "Card Logon Succeeded...", 13 ) )
        else
          Host.str( string( "Card Logon Failed...", 13 ) )
        
      
      if CmdByte == $44   ' D ata Read  
        Host.str( string( "Trying to read all card data...", 13 ) )
        bytefill( @TestDataBuffer, 0, 128 )
        Result := RFID.TryToReadCardData( @TestDataBuffer, 0, 32, 5 )
        if Result <> 0

          Host.str( string( "Card Data Read Succeeded...", 13 ) )
          Host.str( string( "Card Data Dump Follows...", 13 ) )
          Offset := 0


          repeat LoopCounter from 1 to 32
              if LoopCounter < 10 
                Host.str( string( " " ) )
              Host.dec( LoopCounter )
              Host.str( string( "   " ) )
              repeat IndexCounter from 0 to 3
                Host.hex( TestDataBuffer[ Offset ], 2 )
                Offset++

            if LoopCounter > 2 and LoopCounter < 32
               Host.str( string( "   [* writeable]" ) )
                  
            Host.str( string( 13 ) )

          Host.str( string( 13, 13, "End Card Data Dump ", 13 ) )
        

      if CmdByte == $57   ' W rite data
        Host.str( string( "Trying to write data to card...", 13 ) )
        Host.str( string( "Enter address ( 3 to 31 )", 13 ) )

        ErrCheck := GetHostDecimal( $0A )
        if ErrCheck < 3 or ErrCheck > $1F
          Host.str( string( "Invalid address ( range is: 3 to 31 )", 13 ) )
        else

          Host.str( string( "Will Write To Address: " ) )
          Host.dec( ErrCheck )
          Host.str( string( 13 ) )

          Host.str( string( "Enter 4 bytes of data ( each byte separated by carriage return)", 13 ) )

          OldPwdBuffer[ 0 ] := 0
          OldPwdBuffer[ 1 ] := 0
          OldPwdBuffer[ 2 ] := 0
          OldPwdBuffer[ 3 ] := 0

          Result := -1
          repeat until Result <> -1
            Host.str( string( "Trying To Read Byte 1", 13 ) )
            Result := GetHostHex( $0A )
            if Result <> -1
              OldPwdBuffer[ 0 ] := Result

          Host.str( string( "Byte 1 is: " ) )
          Host.hex( OldPwdBuffer[ 0 ], 2 )
          Host.str( string( 13 ) )

          Result := -1
          repeat until Result <> -1
            Host.str( string( "Trying To Read Byte 2", 13 ) )
            Result := GetHostHex( $0A )
            if Result <> -1
              OldPwdBuffer[ 1 ] := Result

          Host.str( string( "Byte 2 is: " ) )
          Host.hex( OldPwdBuffer[ 1 ], 2 )
          Host.str( string( 13 ) )

          Result := -1
          repeat until Result <> -1
            Host.str( string( "Trying To Read Byte 3", 13 ) )
            Result := GetHostHex( $0A )
            if Result <> -1
              OldPwdBuffer[ 2 ] := Result

          Host.str( string( "Byte 3 is: " ) )
          Host.hex( OldPwdBuffer[ 2 ], 2 )
          Host.str( string( 13 ) )

          Result := -1
          repeat until Result <> -1
            Host.str( string( "Trying To Read Byte 4", 13 ) )
            Result := GetHostHex( $0A )
            if Result <> -1
              OldPwdBuffer[ 3 ] := Result

          Host.str( string( "Byte 4 is: " ) )
          Host.hex( OldPwdBuffer[ 3 ], 2 )
          Host.str( string( 13 ) )

          Result := RFID.TryToWriteDataToCard( ErrCheck, @OldPwdBuffer, 5 )
          if Result <> 0
            Host.str( string( "Card Data Write Succeeded...", 13 ) )
          else
            Host.str( string( "Card Data Write Failed...", 13 ) )
            

      if CmdByte == $50   ' P assword set
        Host.str( string( "Trying to logon to card...", 13 ) )
        Host.str( string( "Enter current 4 digit password", 13 ) )
        OldPwdBuffer[ 0 ] := Host.rx - $30
        OldPwdBuffer[ 1 ] := Host.rx - $30
        OldPwdBuffer[ 2 ] := Host.rx - $30
        OldPwdBuffer[ 3 ] := Host.rx - $30
        Host.str( string( "Enter new 4 digit password", 13 ) )
        NewPwdBuffer[ 0 ] := Host.rx - $30
        NewPwdBuffer[ 1 ] := Host.rx - $30
        NewPwdBuffer[ 2 ] := Host.rx - $30
        NewPwdBuffer[ 3 ] := Host.rx - $30        
        Result := RFID.TrySetCardPassword( @OldPwdBuffer, @NewPwdBuffer, 5 )
        if Result <> 0
          Host.str( string( "Card Password Change Succeeded...", 13 ) )
        else
          Host.str( string( "Card Password Change Failed...", 13 ) )


      if CmdByte == $52    ' R eset card
        Host.str( string( "Trying to reset card...", 13 ) )
        Result := RFID.TryCardReset( 5 )
        if Result <> 0
          Host.str( string( "Card Reset Succeeded...", 13 ) )
        else
          Host.str( string( "Card Reset Failed...", 13 ) )


      if CmdByte == $55    ' U nlock card
        Host.str( string( "Trying to unlock card...", 13 ) )
        Result := RFID.TryCardUnlock( 5 )
        if Result <> 0
          Host.str( string( "Card unlock Succeeded...", 13 ) )
        else
          Host.str( string( "Card unlock Failed...", 13 ) )


      if CmdByte == $4C    ' L ock card
        Host.str( string( "Trying to lock card...", 13 ) )
        Result := RFID.TryCardLock( 5 )
        if Result <> 0
          Host.str( string( "Card lock Succeeded...", 13 ) )
        else
          Host.str( string( "Card lock Failed...", 13 ) )


      
PUB GetHostDecimal( Delimiter ) : Value | place, ptr, x
{{
   Accepts and returns serial decimal values, such as "1234" as a number.
   String must end in a carriage return (ASCII 13)
   x:= Serial.rxDec     ' accept string of digits for value
}}   
    place := 1                                           
    ptr   := 0
    value := 0
                                                
    HostDataBuffer[ ptr ] := Host.rx       
    ptr++
    
    repeat while ( HostDataBuffer[ ptr - 1 ] <> 13 ) and ( HostDataBuffer[ ptr - 1 ] <> Delimiter )                     
       HostDataBuffer[ ptr ] := Host.rx                             
       ptr++
       
    if ptr > 2 
      repeat x from ( ptr - 2 ) to 1                            
        if ( HostDataBuffer[ x ] => ( "0" ) ) and ( HostDataBuffer[ x ] =< ( "9" ) )
          value := value + ( ( HostDataBuffer[ x ] - "0" ) * place )       
          place := place * 10
                                        
    if ( HostDataBuffer[ 0 ] => ( "0" ) ) and ( HostDataBuffer[ 0 ] =< ( "9" ) ) 
      value := value + ( HostDataBuffer[ 0 ] - 48 ) * place
    elseif HostDataBuffer[ 0 ] == "-"                                  
      value := value * -1
    elseif HostDataBuffer[0] == "+"                               
      value := value 



PUB GetHostHex( Delimiter ) : Value | place, ptr, x, temp
{{
   Accepts and returns serial hexadecimal values, such as "A2F4" as a number.
   String must end in a carriage return (ASCII 13)
   x := Serial.rxHex     ' accept string of digits for value
}}   
    place := 1                                            
    ptr   := 0
    value :=0                                               
    temp  := Host.rx
            
    if temp == -1
       return -1
       
    HostDataBuffer[ ptr ] := Temp
    ptr++
    
    repeat while ( HostDataBuffer[ ptr - 1 ] <> 13 ) and ( HostDataBuffer[ ptr - 1 ] <> Delimiter )                      
      HostDataBuffer[ ptr ] := Host.rx                               
      if HostDataBuffer[ ptr ] == 255
        return -1
      ptr++           
    if ptr > 1 
      repeat x from ( ptr - 2 ) to 0                             
        if ( HostDataBuffer[ x ] => ( "0" ) ) and ( HostDataBuffer[ x ] =< ( "9" ) )
          value := value + ( ( HostDataBuffer[ x ]-"0" ) * place )         
        if (HostDataBuffer[ x ] => ( "a" ) ) and ( HostDataBuffer[ x ] =< ( "f" ) )
          value := value + ( ( HostDataBuffer[ x ] - "a" + 10 ) * place ) 
        if ( HostDataBuffer[ x ] => ( "A" ) ) and ( HostDataBuffer[ x ] =< ( "F" ) )
          value := value + ( ( HostDataBuffer[ x ]-"A" + 10 ) * place )         
        place := place * 16                                 


      

DAT
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