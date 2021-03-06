{{
┌────────────────────────────┬──────────────────┬────────────────────────┐
│ H48C_Sync_Driver.spin v1.0 │ Author:I.Kövesdi │ Release: 14 March 2009 │
├────────────────────────────┴──────────────────┴────────────────────────┤
│                    Copyright (c) 2009 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  This is a driver object for the H48C 3-axis accelerometer modules. It │
│ can start a Dwell Clock signal and several H48Cs can be synchronized to│
│ the Dwell Clock Line. This driver requires one additional COG for its  │
│ PASM code for each sensors, because synchronous readouts are running   │
│ realy parallel.                                                        │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  Synchronization is solved using the CounterA internal timer of COG0.  │
│ The frequency of the timer's square wave on a pin can be set up between│
│ 1-200 Hz. All H48Cs listen to this line with the WAITPEQ command to    │
│ start data aquisition simultaneously.                                  │ 
│  3-axis Direct acceleration readouts are obtained using shifted        │
│            Ax, Ay, Az,         Az, Ax, Ay,        Ay, Az, Ax           │
│ consecutive sequence of 9 single readings and the summed Ai values are │
│ returned. In this way the averaged time points in the continuous flow  │
│ of time are the same for each acceleration component. One such 3-axis  │
│ measurement (18 ADC readings) takes about 200 usec.                    │   
│  Beside of the 3-axis Synchronous or Direct readouts single axis Single│
│ Shot acceleration readings can be done and Vref values can be obtained,│
│ too.                                                                   │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  The H48C_Sync_Driver can be used in 6DOF IMU projects where four H48C │
│ Tri-axis accelerometers are arranged in space to provide a cheap but   │
│ precise close equivalent of high dollar 6DOF IMU sensors. See attached │
│ PDF file for the mathematical details.                                 │
│  Offset and scale errors of the sensors should be compensated by       │
│ calibration. The temperature of the sensors should be kept constant    │
│ during calibration and during application.                             │
│  On a single axis of the H48C module the maximum useful sample rate is │
│ about 200 Hz because of the low-pass analog filter circuitry on the    │
│ analog output of the accelerometer IC.                                 │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘


Orientation of axes

    Z   Y  
    ^  /  /   °/  
    │ /  /    /
    │/    o   White reference mark on 6-Pin module (Pin #1)
     ────> X     

     
}}
CON

#1, _INIT, _READ_ACC, _READ_AX, _READ_AY, _READ_AZ, _READ_VR       '1-6
#7, _DWELL_ON, _DWELL_OFF                                          '7-8
'These are the enumerated PASM command No.s (_INIT=1, _READ_ACC=2,etc..)
'They should be in harmony with the Cmd_Table of the PASM program in the
'DAT section of this object

_NCO_MODE  =  %00100 << 26


VAR

LONG cog, command, par1, par2, par3, par4

                                         
PUB StartCOG(cS_Pin, dIO_Pin, cLK_Pin, dWL_Pin, addrCogID_) : okay 
'-------------------------------------------------------------------------
'------------------------------┌──────────┐-------------------------------
'------------------------------│ StartCOG │-------------------------------
'------------------------------└──────────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: -Starts a COG to run H48C_SPI_Driver's PASM code
''             -Passes Pin assignments to PASM code in COG memory
''             -Returns false if no COG available or the H48C does not
''              send back correct Vref
'' Parameters: -Prop pin to  CS pin  of H48C3 SPI
''             -Prop pin to DIO pin  of H48C3 SPI
''             -Prop pin to CLK pin  of H48C3 SPI
''             -HUB/Address of cog ID
''    Results: -okay
''             -cog 
''+Reads/Uses: /_INIT
''    +Writes: cog, command, par1, par2, par3, par4
''      Calls: stopCOG
'-------------------------------------------------------------------------  
StopCOG                                'Stop previous copy of this driver,
                                       'if any

command := 0
cog := COGNEW(@H48C, @command)        'Try to start a COG with a running
                                       'PASM program that waits for a
                                       'nonzero "command"
LONG[addrCogID_] :=  cog++                                       

IF cog  '-------------------->Then a COG has been succcessfully started
  par1 := cS_Pin             'CALL _INIT procedure in COG to setup
  par2 := dIO_Pin            'SPI lines, CS line and Dwell CLK line
  par3 := cLK_Pin
  par4 := dWL_Pin
  command := _INIT
  REPEAT WHILE command

  'dClk := FALSE

  'After this H48C should be able to measure and communicate.
  'Check Vref readout, that should be about 2^11 (midscale of the 12 bit
  'ADC)  
  IF (par1>1800) AND (par1<2200)
      okay := TRUE
  ELSE
    okay := FALSE              'Incorrect Vref reading
ELSE                           
  okay := FALSE                'COG not started 

RETURN okay  
'-------------------------------------------------------------------------


PUB StopCOG                                          
'-------------------------------------------------------------------------
'-------------------------------┌─────────┐-------------------------------
'-------------------------------│ StopCOG │-------------------------------
'-------------------------------└─────────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Stops H48C_SPI_Driver PASM code by freeing a COG in which 
''             it is running
'' Parameters: cog
''    Results: None 
''+Reads/Uses: None
''    +Writes: command
''      Calls: None
'-------------------------------------------------------------------------
command~                               'Clear "command" register
                                       'Here you can initiate a "shut off"
                                       'PASM routine if necessary 
IF cog
  COGSTOP(cog~ - 1)                    'Stop COG      
'-------------------------------------------------------------------------


PUB Dwell_Clock_On(pin, freq) : oKay | f, ctr_a, frq_a 
'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ Dwell_Clock_On │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Starts dwell clock signal for the accelerometer modules 
'' Parameters: -Pin of Dwell Clock
''             -Frequency (between and including 1 and 200 Hz) 
''    Results: None
''    Effects: Oscillator in COG0 starts with a square wave on Pin with the
''             preset Frequency  
''+Reads/Uses: /_NCO_MODE
''    +Writes: CTRA, FRQA of Counter A in COG0
''      Calls: None
''       Note: -Accelerometer readouts will be synchronized to this square
''             wave generated by COG0
''             -Any of the H48C drivers can start/stop this oscillator
''             -Actual Dwell Mode data collection begins after the
''             Dwell_Mode_On procedure has been called.
'-------------------------------------------------------------------------
'Check 1-200 Hz frequency range
CASE freq
  1..200:
    RESULT := TRUE
  OTHER:
    RETURN FALSE
    
    
ctr_a := _NCO_MODE                 'Set Counter A's Controll Register's
                                   'CTRMODE field (30..26) to the NCO mode
                                   '(%00100)
                                   
ctr_a |= pin                       'Bitwise OR. Set PINA field (0..5) of
                                   'Counter A's Controll Register to Pin
                                   'This completes CTRA of Counter A
                                   
CTRA := ctr_a                      'set CTRA                                       
          
'Compute FRQA multiplier of CLKFREQ. FRQA will be added to PHSA at every
'clock tick. Frequency on PINA = (FRQA * CLKFREQ) / 2^32

f := freq
REPEAT 32
  IF f => CLKFREQ
    f -= CLKFREQ
    frq_a++           
  f <<= 1                          
  frq_a <<= 1
  
frq_a++                            'Correction for 2-200 Hz
IF freq == 1                       
  frq_a++                          'Plus correction for 1Hz

FRQA := frq_a                      'Set FRQA               
DIRA[pin]~~                        'Make Dwell Clock pin as output
'-------------------------------------------------------------------------


PUB Dwell_Clock_Off(pin)
'-------------------------------------------------------------------------
'---------------------------┌─────────────────┐---------------------------
'---------------------------│ Dwell_Clock_Off │---------------------------
'---------------------------└─────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: -Stops dwell mode data collection (if it was activated)
''             -Stops dwell time clock signal for the accelerometer moduls  
'' Parameters: Dwell Clock pin
''    Results: None
''+Reads/Uses: None
''    +Writes: None
''      Calls: Dwell_Mode_Off 
'-------------------------------------------------------------------------
Dwell_Mode_Off                     'Stop dwell mode data collection

CTRA~                              'Clear CTRA
FRQA~                              'Clear FRQA                 
DIRA[pin]~                         'Make Dwell Clock pin input
'-------------------------------------------------------------------------


PUB Dwell_Mode_On
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ Dwell_Mode_On │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Activates dwell clock synchronized data collection 
'' Parameters: None
''    Results: None
''    Effects: None
''+Reads/Uses: dwellClock/_DWELL_ON
''    +Writes: command
''      Calls: None
'-------------------------------------------------------------------------
command := _DWELL_ON
REPEAT WHILE command                 'Wait for command to be processed
'-------------------------------------------------------------------------


PUB Dwell_Mode_Off
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ Dwell_Mode_Off │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Deactivates dwell clock synchronized data collection 
'' Parameters: None
''    Results: None
''    Effects: None
''+Reads/Uses: /_DWELL_OFF
''    +Writes: command
''      Calls: None
'-------------------------------------------------------------------------
command := _DWELL_OFF
REPEAT WHILE command                 'Wait for command to be processed
'-------------------------------------------------------------------------


PUB Read_Acceleration(aX_, aY_, aZ_, t_)
'-------------------------------------------------------------------------
'------------------------┌─────────────────────┐--------------------------
'------------------------│  Read_Acceleration  │--------------------------
'------------------------└─────────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Reads Same Time Point Averaged acceleration data for all
''             the 3 axis 
'' Parameters: -aX_, aY_, aZ_ (HUB addresses)
''             -t_ (HUB address)
''    Results: aXBar, aYBar, aZBar, t (in HUB at those addresses)
''+Reads/Uses: /_READ_ACC, command, par1, par2, par3, par4
''    +Writes: /command, par1, par2, par3, par4
''      Calls: #Read_Acc(in COG)
'-------------------------------------------------------------------------
command := _READ_ACC
REPEAT WHILE command                 'Wait for command to be processed

'After _READ_ACC command had been processed then the PASM routine of this
'Driver object wrote the measured acceleration components and the average 
'time instant of the measurements into par1, par2, par3 and par4 of HUB
'Now copy these registers into registers at HUB addresses aX_, aY_, aZ_,
'and t_ provided by the calling SPIN code.

LONG[aX_] := par1          'Copy par1(=aXBar) into the LONG at [aX_]
LONG[aY_] := par2          'Copy par2(=aYBar) into the LONG at [aY_]
LONG[aZ_] := par3          'Copy par3(=aZBar) into the LONG at [aZ_]
LONG[t_]  := par4          'Copy par4(=time) into the long at [t_]
'-------------------------------------------------------------------------

  
PUB Read_Single_Shot_A_X(aX_)
'-------------------------------------------------------------------------
'-------------------------------┌──────────┐------------------------------
'-------------------------------│ Read_A_X │------------------------------
'-------------------------------└──────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Reads Single Shot acceleration data for the X axis
'' Parameters: aX_ (HUB address)
''    Results: aXBar(HUB/LONG[aX_])
''+Reads/Uses: /command, _READ_AX, par1
''    +Writes: command, par1
''      Calls: #Read_Ax(in COG)
'-------------------------------------------------------------------------
command := _READ_AX
REPEAT WHILE command       'Wait for command to be processed
  
'_READ_AX command has been processed
LONG[aX_] := par1          'Now return measured Ax value 
'-------------------------------------------------------------------------


PUB Read_Single_Shot_A_Y(aY_)
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ Read_A_Y │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Reads Single Shot acceleration data for the Y axis
'' Parameters: aY_ (HUB address)
''    Results: aYBar(in HUB/LONG[aY_])
''+Reads/Uses: /command, _READ_AY, par1
''    +Writes: command, par1
''      Calls: #Read_Ay(in COG)
'-------------------------------------------------------------------------
command := _READ_AY
REPEAT WHILE command                 'Wait for command to be processed
  
'_READ_AY command has been processed
LONG[aY_] := par1                    'Now return measured Ay value                                             
'-------------------------------------------------------------------------


PUB Read_Single_Shot_A_Z(aZ_)
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ Read_A_Z │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Reads Single Shot acceleration data for the Z axis
'' Parameters: aZ_ (HUB address)
''    Results: aZBar(in HUB/LONG[aZ_])
''+Reads/Uses: /command, _READ_AZ, par1
''    +Writes: command,par1
''      Calls: #Read_Az (in COG)
'-------------------------------------------------------------------------
command := _READ_AZ
REPEAT WHILE command                 'Wait for command to be processed
  
'_READ_AZ command has been processed
LONG[aZ_] := par1                    'Now RETURN measured Az value    
'-------------------------------------------------------------------------


PUB Read_Single_Shot_V_Ref(vR_)
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ Read_V_Ref │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Reads Vref Count from H48C
'' Parameters: vR_ (HUB address)
''    Results: vRef(in HUB/LONG[vR_])
''+Reads/Uses: /command, _READ_VR, par1
''    +Writes: command, par1
''      Calls: #Read_Vr (in COG)
'-------------------------------------------------------------------------
command := _READ_VR
REPEAT WHILE command                 'Wait for command to be processed
  
'READ_VR command has been processed
LONG[vR_] := par1                    'Now return measured Vref value  
'-------------------------------------------------------------------------


PUB Dwell_Acceleration(aX_, aY_, aZ_, t_)
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│  Read_Acc  │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Reads acceleration data and time of measurement in Dwell
''             data collection mode                                            
'' Parameters: -aX_, aY_, aZ_ (HUB addresses)
''             -t_ (HUB address)                              
''    Results: aXBar, aYBar, aZBar, t (in HUB at those addresses)                                                  
''+Reads/Uses: None                                             
''    +Writes: None                                 
''      Calls: None
''       Note: Data acquisition is synchronized to the Dwell Clock                 
'-------------------------------------------------------------------------
LONG[aX_] := par1          'Copy par1(=aXBar) into the LONG at [aX_]
LONG[aY_] := par2          'Copy par2(=aYBar) into the LONG at [aY_]
LONG[aZ_] := par3          'Copy par3(=aZBar) into the LONG at [aZ_]
LONG[t_]  := par4          'Copy par4(=time) into the LONG at [t_]
'-------------------------------------------------------------------------



DAT 'DAT section for PASM program in COG
'-------------------------------------------------------------------------
'-------------DAT section for PASM program and COG registers--------------
'-------------------------------------------------------------------------

DAT 'Start of PASM code 
H48C     ORG             0               'Start of PASM program

Get_Command
RDLONG   r1,             PAR WZ          'Read "command" register from HUB
IF_Z     JMP             #Get_Command    'Wait for a nonzero "command"

SHL      r1,             #1              'Multiply command No. with 2
ADD      r1,             #Cmd_Table-2    'Add it to the value of
                                         '#Cmd_Table-2
'Note that command numbers are 1, 2, 3, etc..., but the entry routines
'are the 0th, 2rd, 4th, etc... entries in the Cmd_Table (counted in 32
'bit registers)

JMP      r1                    'Jump to selected command in Cmd_Table
                                     
Cmd_Table                      'Command dispatch table
CALL     #Init                 'Init    (command No.1)
JMP      #Done                 'Nothing more to do for Init
CALL     #Read_Accel           'Read_Acc(command No.2)
JMP      #Done                 'Nothing more to do for Read_Accel
CALL     #Read_Ax              'Read_Ax (command No.3)
JMP      #End_Read_Ax          'There is something to do for Read_Ax
CALL     #Read_Ay              'Read_Ax (command No.4)
JMP      #End_Read_Ay          'There is something to do for Read_Ay
CALL     #Read_Az              'Read_Ax (command No.5)
JMP      #End_Read_Az          'There is something to do for Read_Az
CALL     #Read_Vr              'Read_Vr (command No.6)
JMP      #End_Read_Vr          'There is something to do for Read_Vr
JMP      #Dwell_On             'Jump to Dwell_On (command No.7)
JMP      #Done                 'Nothing more to do for Dwell_On
CALL     #Dwell_Off            'Dwell_Off (command No.8)
JMP      #Done                 'Nothing more to do for Dwell_Off

'The next sections of End_... labels are for those PASM subroutines which
'are called from other PASM subroutines (e.g. from Read_Acc), as well. In
'that case they pass parameters and results simply within COG memory and
'they don't need these End_... stuff. But, when they are called from
'interpreted SPIN code of this H48C_Driver object, they need these
'"finishing" code to write back results into HUB.
 
End_Read_Ax
WRLONG   aX,             par1_Addr_  'Write single shot Ax value to "par1"
JMP      #Done                       'in HUB memory

End_Read_Ay
WRLONG   aY,             par1_Addr_  'Write single shot Ay value to "par1" 
JMP      #Done                       'in HUB memory
  
End_Read_Az
WRLONG   aY,             par1_Addr_  'Write single shot Az value to "par1"  
JMP      #Done                       'in HUB memory
  
End_Read_Vr
WRLONG   vRef,           par1_Addr_  'Write single shot Vref value to
                                     '"par1" in HUB memory 

'Command has been processed. Now send "Command Processed" status to the
'interpreted HUB memory SPIN code of this driver, than jump back to the
'entry point of this PASM code. There it will fetch the next command,
'if any.

Done
WRLONG   _Zero,          PAR       'Write 0 to HUB/command to signal a
                                   '"Command Processed" status for the
                                   'SPIN code                                       
JMP      #Get_Command              'Get next command
'-------------------------------------------------------------------------


DAT 'Init
'-------------------------------------------------------------------------
'-----------------------------------┌──────┐------------------------------
'-----------------------------------│ Init │------------------------------
'-----------------------------------└──────┘------------------------------
'-------------------------------------------------------------------------
'     Action: -Stores parameter addresses
'             -Initializes Pin Masks
'             -Initializes CS, CLK and DIO lines
'             -Reads Vref
'             -Trandsfers Vref value back to HUB/par1 
' Parameters: CS and SPI lines: HUB/cs, dio, clk
'    Results: COG/cs_Pin_Mask, dio_Pin_Mask, clk_Pin_Mask
'             COG/par1_Addr_, par2_Addr_, par3_Addr_, par4_Addr_
'             vRef count in HUB/par1     
'+Reads/Uses: /PAR          
'    +Writes: r1, r2
'      Calls: #Read_Vr
'       Note: Using the Vref value, the HUB/Code can make a check for a 
'             properly working sensor
'-------------------------------------------------------------------------
Init

MOV      r1,             par   'Get address of "command" in HUB memory
ADD      r1,             #4    'r1 now contains the HUB memory address
                               'of "par1" variable
                               '("par1" is next to "command")
MOV      par1_Addr_,     r1    'Store this address in COG memory
RDLONG   r2,             r1    'Load CS pin No. from HUB memory into r2 
MOV      cs_Pin_Mask,    #1    'Setup CS pin mask
SHL      cs_Pin_Mask,    r2

ADD      r1,             #4    'r1 now points to "par2" in HUB memory
MOV      par2_Addr_,     r1    'Store this address in COG memory
RDLONG   r2,             r1    'Load DIO pin No. from HUB memory into r2
MOV      dio_Pin_Mask,   #1    'Setup DIO pin mask 
SHL      dio_Pin_Mask,   r2

ADD      r1,             #4    'r1 now points to "par3" in HUB memory
MOV      par3_Addr_,     r1    'Store this address in COG memory
RDLONG   r2,             r1    'Load CLK pin No. from HUB memory into r2
MOV      clk_Pin_Mask,   #1    'Setup CLK pin mask
SHL      clk_Pin_Mask,   r2

ADD      r1,             #4    'r1 now points to "par4" in HUB memory
MOV      par4_Addr_,     r1    'Store this address in COG memory
RDLONG   r2,             r1    'Load Dwell CLK pin No. from HUB into r2 
MOV      dwl_Pin_Mask,   #1    'Setup Dwell CLK pin mask
SHL      dwl_Pin_Mask,   r2

'Prepare Prop hardware on H48C lines
OR       OUTA,           cs_Pin_Mask   'Pre-Set CS pin HIGH
OR       DIRA,           cs_Pin_Mask   'Set CS as OUTPUT (deselect H48C)
ANDN     OUTA,           clk_Pin_Mask  'Pre-Set Clock pin LOW
OR       DIRA,           clk_Pin_Mask  'Set Clock pin as OUTPUT
ANDN     DIRA,           dio_Pin_Mask  'Set DIO pin as an INPUT

'Do a Vref reading from H48C to verify wether it is present and it can
'communicate. Pass the readout via par1(in HUB) and let the SPIN code to
'check it (value should be about 2^11).
CALL     #Read_Vr
WRLONG   r1,             par1_Addr_     'Write result into HUB/par1

Init_Ret
RET          
'-------------------------------------------------------------------------


DAT 'Read_Accel
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ Read_Accel │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Read "Same average time measured" values of the 3 
'             acceleration components from H48C.
' Parameters: None
'    Results: aXBar, aYBar, aZBar, datum  (in HUB/par1, par2, par3, par4)
'+Reads/Uses: /aX, aY, aZ, datum,
'             /par1_Addr_, par2_Addr_, par3_Addr_, par4_Addr_
'    +Writes: aX, aY, aZ, datum
'      Calls: #Read_Ax, #Read_Ay, #Read_Az
'  Side Eff.: A simple moving average digital filter effect is obtained
'             on the returned aXBar, aYBar, aZBar values
'       Note: At 80_000_000 Hz the elapsed time during the 9 single axis
'             measurements is about 200 usec. Single axis measurements
'             follow each other in the sequence of
'                 Ax, Ay, Az,         Az, Ax, Ay,        Ay, Az, Ax
'             and each one takes about 22.2 usec.
'-------------------------------------------------------------------------
Read_Accel

MOV      time,           CNT           'Read current time 

CALL     #Read_Ax                      'Get Ax Count
MOV      aXBar,          aX            'Store it
CALL     #Read_Ay                      'Get Ay Count
MOV      aYBar,          aY            'Store it
CALL     #Read_Az                      'Get Az Count
MOV      aZBar,          aZ            'Store it

CALL     #Read_Az                      'Get Az Count
ADDS     aZBar,          aZ            'Sum it
CALL     #Read_Ax                      'Get Ax Count
ADDS     aXBar,          aX            'Sum it
CALL     #Read_Ay                      'Get Ay Count
ADDS     aYBar,          aY            'Sum it

CALL     #Read_Ay                      'Get Ay Count
ADDS     aYBar,          aY            'Sum it
CALL     #Read_Az                      'Get Az Count
ADDS     aZBar,          aZ            'Sum it
CALL     #Read_Ax                      'Get Ax Count
ADDS     aXBar,          aX            'Sum it

'Calculate average measurement time
ADD      time,           CNT           'Add start and end time points
SHR      time,           #1            'Divide by 2 to get midpoint

'Write acceleration values from COG into HUB/par1, par2, par3 
WRLONG   aXBar,          par1_Addr_    'Write aXBar into HUB/par1
WRLONG   aYBar,          par2_Addr_    'Write aYBar into HUB/par2
WRLONG   aZBar,          par3_Addr_    'Write aZBar into HUB/par2

WRLONG   time,           par4_Addr_    'Write average time count into
                                       'HUB/par4

Read_Accel_Ret
RET
'-------------------------------------------------------------------------


DAT 'Read_Ax
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ Read_Ax │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads Ax Count from H48C module 
' Parameters: None
'    Results: Single shot Ax Count in aX 
'+Reads/Uses: /r1, _Vref_Sel, vRef, _X_Sel
'    +Writes: r1, vRef
'      Calls: #Read_H48C
'-------------------------------------------------------------------------
Read_Ax

MOV      r1,             _Vref_Sel        
CALL     #Read_H48C                    'Get Vref value from ADC
MOV      vRef,           r1

MOV      r1,             _X_Sel        
CALL     #Read_H48C                    'Get (Ax+Vref) value from ADC
MOV      aX,             r1            'Copy to aX

SUBS     aX,             vRef          'Subsract Vref to obtain aX

Read_Ax_Ret
RET
'-------------------------------------------------------------------------


DAT 'Read_Ay
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ Read_Ay │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads Ay Count from H48C module 
' Parameters: None
'    Results: Single shot Ay Count in aY 
'+Reads/Uses: /r1, _Vref_Sel, vRef, _Y_Sel
'    +Writes: r1, vRef
'      Calls: #Read_H48C
'-------------------------------------------------------------------------
Read_Ay

MOV      r1,             _Vref_Sel        
CALL     #Read_H48C                    'Get Vref value from ADC
MOV      vRef,           r1

MOV      r1,             _Y_Sel        
CALL     #Read_H48C                    'Get (Ay+Vref) value from ADC
MOV      aY,             r1            'Copy to Ay
  
SUBS     aY,             vRef          'Subsract Vref to obtain aY

Read_Ay_Ret
RET
'-------------------------------------------------------------------------


DAT 'Read_Az
'-------------------------------------------------------------------------
'---------------------------------┌─────────┐-----------------------------
'---------------------------------│ Read_Az │-----------------------------
'---------------------------------└─────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Reads Az Count from H48C module 
' Parameters: None
'    Results: Single shot Az Count in aZ
'+Reads/Uses: /r1, _Vref_Sel, vRef, _Z_Sel
'    +Writes: r1, vRef
'      Calls: #Read_H48C
'-------------------------------------------------------------------------
Read_Az

MOV      r1,             _Vref_Sel        
CALL     #Read_H48C                    'Get Vref value from ADC
MOV      vRef,           r1

MOV      r1,             _Z_Sel        
CALL     #Read_H48C                    'Get (Az+Vref) value from ADC
MOV      aZ,             r1            'Copy to aZ

SUBS     aZ,             vRef          'Subsract Vref to obtain aZ

Read_Az_Ret
RET
'-------------------------------------------------------------------------


DAT 'Read_Vr
'-------------------------------------------------------------------------
'---------------------------------┌─────────┐-----------------------------
'---------------------------------│ Read_Vr │-----------------------------
'---------------------------------└─────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Reads Vref Count from H48C module            
' Parameters: None
'    Results: Vref Count in vRef               
'+Reads/Uses: r1, _Vref_Sel
'    +Writes: r1
'      Calls: #Read_H48C
'-------------------------------------------------------------------------
Read_Vr

MOV      r1,             _Vref_Sel        
CALL     #Read_H48C                    'Get Vref value in r1
MOV      vRef,           r1

Read_Vr_Ret
RET
'-------------------------------------------------------------------------


DAT 'Dwell_On
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ Dwell_On │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: -Starts Dwell Clock synchronized data collection
'             -Remains in this mode loop until _DWELL_OFF command arrives       
' Parameters: None
'    Results: None               
'+Reads/Uses: PAR/_Zero
'    +Writes: PAR, r1
'      Calls: #Read_Accel
'       Note: -Execution loop remains here. Only the _DWELL_OFF command is
'             listened to quit this data collection loop and to jump back
'             into the main loop
'             -The COG/#Read_Accel routine writes back the measured values
'             into HUB registers of this driver.
'-------------------------------------------------------------------------
Dwell_On

WRLONG   _Zero,          PAR             'Clear "command"

:Dwell_Loop
WAITPEQ  dwl_Pin_Mask,   dwl_Pin_Mask    'Wait for dwell clock line HIGH 

CALL     #Read_Accel                     'Read components of the accel and
                                         'write them into HUB/par1, par2,
                                         'par3 of this driver

'Check for _DWELL_OFF command
RDLONG   r1,             PAR             'Read "command" register 
CMP      r1,             #_DWELL_OFF WZ

IF_Z     JMP             #Done           '_DWELL_OFF command received, 
                                         'jump to #Done label into main
                                         'loop

WRLONG   _Zero,          PAR             'Clear "command" to let SPIN
                                         'program to continue if other
                                         'than _DWELL_OFF command was sent
                                         'by mistake                                        

WAITPNE  dwl_Pin_Mask,   dwl_Pin_Mask    'Wait for Dwell Clock line LOW

JMP      #:Dwell_Loop
'-------------------------------------------------------------------------


DAT 'Dwell_Off
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ Dwell_Off │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Catches _DWELL_OFF command when received in Direct or Single 
'             Shot data collection mode.
' Parameters: None
'    Results: None               
'+Reads/Uses: None
'    +Writes: None
'      Calls: None
'       Note: Dummy routine. Execution doesn't get here normally since the
'             #Dwell_On routine catches the _DWELL_OFF command during
'             Dwell data collection mode. However, Dwell_Clock_Off calls
'             Dwell_Mode_Off, and that issues the _DWELL_OFF command,
'             independently of the data collection mode. 
'-------------------------------------------------------------------------
Dwell_Off

Dwell_Off_Ret
RET
'-------------------------------------------------------------------------


DAT 'Read_H48C
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ Read_H48C │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: -Selects H48C
'             -Selects and writes ADC register
'             -Reads corresponding data into r1
' Parameters: 5 bit ADC register selection bit pattern in r1
'    Results: H48C data in r1 
'+Reads/Uses: /cs_Pin_Mask, dio_Pin_Mask, r2, r3, _Data_Mask
'    +Writes: r2, r3
'      Calls: #Clock_Pulse
'-------------------------------------------------------------------------
Read_H48C
                               
ANDN     OUTA,           cs_Pin_Mask   'Make CS pin LOW   (Select H48C)
  
'Select ADC register of H48C

OR       DIRA,           dio_Pin_Mask  'Set Data pin as an OUTPUT
MOV      r2,             #5            'Reg Sel data counter
MOV      r3,             #%10000       'Mask for it

'Send the code of the selected ADC register
:SoutLoop
TEST     r1,             r3 WC         'Test MSB of DataValue
MUXC     OUTA,           dio_Pin_Mask  'Set DataBit HIGH or LOW
SHR      r3,             #1            'Prepare for next DataBit
CALL     #Clock_Pulse                  'Send  a clock pulse
DJNZ     r2,             #:SoutLoop    'Decrement r2; jump if not zero
  
'ADC register has been selected. Now read ADC register data
ANDN     DIRA,           dio_Pin_Mask  'Set DIO pin as an INPUT
MOV      r2,             #13           'Set number of bits of ADC counts 

'Read the count in the selected ADC register
:SinLoop
CALL     #Clock_Pulse                  'Send a clock pulse
TEST     dio_Pin_Mask,   INA WC        'Read Data Bit into 'C' flag
RCL      r1,             #1            'Left rotate 'C' flag into r1
DJNZ     r2,             #:SinLoop     'Decrement r2; jump if not zero

AND      r1,             _Data_Mask    'Clean up r1

OR       OUTA,           cs_Pin_Mask   'Make CS pin HIGH  (Deselect H48C)

Read_H48C_Ret
RET              
'-------------------------------------------------------------------------


DAT 'Clock_Pulse
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ Clock_Pulse │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Sends a 250 ns pulse to CLK pin of H48C Module
' Parameters: None
'    Results: None 
'+Reads/Uses: /clk_Pin_Mask 
'    +Writes: None
'      Calls: None
'       Note: At 80_000_000 Hz the CLK pulse width is about 250 ns (20
'             ticks) and the pin is pulsed at the rate about 1.66 MHz
'             (c.a. 600 ns CLK pulse repetition time). This timing is
'             in according to the datasheet of the MCP3204 ADC where the
'             minimum clock High or Low time is 250 ns and the maximum
'             clock frequency at 5.0 V is 2.0 MHz. During a single-axis
'             acceleration readout the CLK pin is pulsed 2 x (5 + 13) = 36
'             times (addressing Vref, reading Vref, addressing value,
'             reading value) and that altogether takes about 22.2 us. This  
'             readout is very fast. However, when you are designing the 
'             acceleration sample rate for your application you should 
'             know, that on a single axis of the H48C module the useful
'             maximum sample rate is about 200 Hz because of the low-pass
'             analog filter circuitry on the analog outputs of the H48C.
'-------------------------------------------------------------------------
Clock_Pulse

OR       OUTA,           clk_Pin_Mask  'Set CLK Pin HIGH
NOP                                    'Trimming NOPs
NOP
NOP
NOP
ANDN     OUTA,           clk_Pin_Mask  'Set CLK Pin LOW
  
Clock_Pulse_Ret         
RET
'------------------------------------------------------------------------- 


DAT 'COG memory allocation via PASM symbols
'-------------------------------------------------------------------------
'--------Allocate COG memory for registers defined by PASM symbols--------
'-------------------------------------------------------------------------
  
'-------------------------------------------------------------------------
'-------------------------------Initialized data--------------------------
'-------------------------------------------------------------------------
_Zero          LONG    0

'-----------------------------ADC control codes --------------------------
'                       ┌─────── Start Bit              
'                       │┌────── Single/Differential Bit
'                       ││┌┬┬─── Channel Select
'                       
_X_Sel         LONG    %11000    'ADC Control Code to get Ax count 
_Y_Sel         LONG    %11001    'ADC Control Code to get Ay count
_Z_Sel         LONG    %11010    'ADC Control Code to get Az count
_Vref_Sel      LONG    %11011    'ADC Control Code to get Vref count

_Data_Mask     LONG    $1FFF     '13-Bit data mask


'-------------------------------------------------------------------------
'-----------------------------Uninitialized data--------------------------
'-------------------------------------------------------------------------

'----------------------------------Pin Masks------------------------------
cs_Pin_Mask    RES     1         'Pin mask in Propeller for CS          
dio_Pin_Mask   RES     1         'Pin mask in Propeller for DIO          
clk_Pin_Mask   RES     1         'Pin mask in Propeller for CLK
dwl_Pin_Mask   RES     1         'Pin mask in Propeller for Dwell CLK          

'--------------------------HUB memory addresses---------------------------
par1_Addr_     RES     1
par2_Addr_     RES     1
par3_Addr_     RES     1
par4_Addr_     RES     1

'------------------------Data read from H48C Module----------------------- 
vRef           RES     1    
aX             RES     1                  
aY             RES     1
aZ             RES     1
aXBar          RES     1
aYBar          RES     1
aZBar          RES     1

'------------------------------------Time---------------------------------
time           RES     1

'----------------------Recycled Temporary Registers-----------------------
r1             RES     1         
r2             RES     1         
r3             RES     1

fit            496


{{
┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}                                  