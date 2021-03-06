{{
┌──────────────────────────────────┬──────────────────┬──────────────────┐
│ DataLogger_Lite_Driver.spin v1.1 │ Author:I.Kövesdi │ Rel.: 12.08.2010 │  
├──────────────────────────────────┴──────────────────┴──────────────────┤
│                    Copyright (c) 2010 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  This is an UART driver object for the Memory Stick Datalogger. It uses│
│ the Parallax Serial Terminal object v1.0,  where the buffer size has to│
│ be set to 256 byte. It supports Excel compatible CSV data storage.     │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│ - The Vinculum firmware for the VNC1L-1A in the Parallax Memory Stick  │
│ Datalogger (#27937) is pre-compiled as an USB host for thumb drives    │
│ that are formatted in FAT12, FAT16 or FAT32 file systems with a sector │
│ size of 512 bytes. No other file systems, partitions  or sector sizes  │
│ are allowed. It works with drives up to 64G or more.                   │
│                                                                        │
│ - Communication with the firmware monitor can be jumper selected as    │
│ serial UART with handshaking or SPI. This driver is designed for UART. │
│                                                                        │
│ - The driver can operate at standard baud rates from 9600 to 115200    │
│                                                                        │
│ - The DataLogger_Lite_Driver object supports:                          │
│                         │                                              │
│                           CSV textfile storage                         │
│                                                                        │
│ - Peak data write speeds were measured:                                │
│                                                                        │ 
│                 215 ASCII numbers / sec to CSV textfiles.              │ 
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  It is prudent to test and verify different makes and models of disks  │
│ before deployment.                                                     │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
}}


CON

_DEF_MODE        = 0               'UART default mode
_DEF_BAUD        = 9600            'UART default baud rate

_TIMEOUT_MS      = 2000            'Maximum of RTS wait in ms
_MAX_SYNC_TRIALS = 32              'Maximum of synchronisation trials

_SECTOR_SIZE     = 512             'Default sector size (Fixed for VN1L)

_MAXFILES        = 42              'This can be adjusted for your needs
_MAXDIRS         = 8               'This can be adjusted for your needs
                                   'Smaller values spare a lot of HUB RAM

_FNBUF_SIZE      = _MAXFILES * 14  'But not less than _SECTOR_SIZE. Check
_DNBUF_SIZE      = _MAXDIRS * 14
_MAXIDDE         = 14              'Maximum of IDDE strings 
_SIZEIDDE        = 256             'Buffer for IDDE strings
_STRBUF_SIZE     = 32              'String buffer length

'Conversion
_MAX_STR_LEN     = 12
_32K             = 32768

'Block sizes (Small but safe values that always worked at 57600 baud)
_APPBLK_SIZE     = 64              'Append Block Size
_CPYBLK_SIZE     = 64              'Copy / Merge Block Size
'These small block sizes worked with all the drives I have tested (5
'vendors, 9 products from 512M to 16G) at 57600 baud . Some smaller
'capacity (0.5 to 2 G) drives proved to be noticably faster in comparison
'with others. These "fast" drives worked with 256 byte block sizes without
'any problem or with these block sizes at 115 Kbaud. Maybe the Vinculum
'Monitor software runs faster within those smaller address space, too. So,
'you can increase these default block sizes when you have faster drives
'or after you decreased the baud rate of the monitor.

'The copy, split merge and overwrite processes involve many file open /
'close operations. As in the Vinculum firmware only one file can be open
'at a time, this slows down random access data transfer rate.

'In a simple datalogging application we open a file once, append the data
'to it many times, then we close the file once after the datalogging
'session. This can be done with 100-200 ASCII format numbers per second
'in the CSV (Comma Separated Values) mode.                                      

'Command Sets
_SHORT           = 0       'Short Command Set (Not used in v1.0)
_EXTEN           = 1       'Extended Command Set

'Error Codes
_NOTRECOG        = -1
_NONE            = 0
_NODISK          = 1
_BADCOMMAND      = 2
_CMDFAILED       = 3
_DIRNOTEMPTY     = 4
_FILEOPEN        = 5
_BLOCKED         = 6
_INVALID         = 7
_FNINVALID       = 8


'Data types for CSV
_LONG            = 0
_QVAL            = 1
_FLOAT           = 2


VAR

'LONG             debug              'Global Debug Flag

'Pins
BYTE             rXP
BYTE             tXP 
BYTE             rTS
BYTE             cTS
BYTE             rNG
BYTE             rST
 
'Params
BYTE             cmd_Set            'Command Set flag
LONG             baudR              'Actual baud rate

'Directory and File Name data
LONG   nOfDirs                      'Number of directories
LONG   nOfFiles                     'Number of files
LONG   nOfIDDEs                     'Number of IDDE strings
LONG   ptrDirNames[_MAXDIRS]        'Pointer array to directory names
LONG   ptrFileNames[_MAXFILES]      'Pointer array to file names
LONG   ptrIDDEs[_MAXIDDE]           'Pointer array to IDDE strings

LONG   lineNumb                     'Line Number
LONG   filePntr                     'File Pointer
LONG   fileSize                     'File Size

'Name arrays with zero byte separator between strings
BYTE   strDirNames[_DNBUF_SIZE]     'Directory names                       
BYTE   strFileNames[_FNBUF_SIZE]    'File names
BYTE   strIDDE[_SIZEIDDE]           'IDDE strings

'String Buffer
BYTE   strBuffer[_STRBUF_SIZE]      'String Buffer

'Markers
BYTE   EOL                          'End of Line boolean
BYTE   EOF                          'End of File boolean



OBJ


'---------UART for Memory Stick Datalogger (Parallax item #27937)---------
UART       :"Parallax Serial Terminal"  'From Parallax Inc. v1.0 
 

DAT '------------------------Start of SPIN code---------------------------


PUB Start_Driver(rX, tX, rT, cT, rI, rS, reset) : yesNo | cid, i
'-------------------------------------------------------------------------
'----------------------------┌──────────────┐-----------------------------
'----------------------------│ Start_Driver │-----------------------------
'----------------------------└──────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Initializes driver
'' Parameters: - Lines of UART
''             - Ring Indicator line
''             - Reset line
''             - Flag for reset                   
''    Returns: TRUE if action successful, else FALSE 
''+Reads/Uses: UART#BUFFER_LENGTH                 (OBJ/CON)
''             _FNBUF_SIZE, _SECTOR_SIZE          (CON)
''             _DEF_MODE, _DEF_BAUD               (CON)
''             strNoCOG, strSomeErr               (DAT/string)
''             strDirNames, strFileNames, strIDDE (VAR/BYTE array)   
''    +Writes: ptrErrMess, ptrStatMess            (VAR/LONG)
''             baudR                              (VAR/LONG)
''             rXP, tXP, rTS, cTS, rNG, rST       (VAR/BYTE)
''             cmd_Set                            (VAR/BYTE)
''             nOfDirs , nofFiles, nOfIDDEs       (VAR/LONG)
''             ptrDirNames,ptrFileNames,ptrIDDEs  (VAR/LONG array)
''      Calls: Parallax Serial Terminal----------->UART.Stop
''                                                 UART.StartRxTx
''             Sync
''             Disk_Online
'-------------------------------------------------------------------------
ptrErrMess := @strNone

'Check buffers
IF (UART#BUFFER_LENGTH < 256)
  yesNo := FALSE
  ptrErrMess := @strTooSmall
  ptrStatMess := @strSomeErr
  RETURN

IF (_FNBUF_SIZE < _SECTOR_SIZE)
  yesNo := FALSE
  ptrErrMess := @strTooSmall
  ptrStatMess := @strSomeErr
  RETURN

'The default mode for the Vinculum's UART after reset is 9600 baud, 1 stop
'bit, no parity. Its firmware starts in Command Mode using Extended
'Command Set with binary input.
'The firmware in the Memory Stick Datalogger works in Command Mode only. 
'Alternative Command Set is the Shortened one and alternative input is the
'ASCII input. The Shortened Command Set and the ASCII input can be
'activated by software, but this driver does not uses them.

'Start Parallax Serial Terminal for UART to Memory Stick Datalogger
UART.Stop   
cid := UART.StartRxTx(rX, tX, _DEF_MODE, _DEF_BAUD)
baudR := _DEF_BAUD
'This launched 1 COG 

IF (cid == 0)                        'No success, send back FALSE and
  yesNo := FALSE                     'error meessage
  ptrErrMess := @strNoCOG
  RETURN

rXP := rX
tXP := tX  

rTS := rT                            'RTS output on Propeller
cTS := cT                            'CTS input on Propeller

rNG := rI                            'RNG output on Propeller
rST := rS                            'RST output on Propeller

'Setup RESET line---------------------------------------------------------
OUTA[rST]~~              'High 
DIRA[rST]~~              'Define RES on Prop as output, it is connected to
                         'the (R)eset input of datalogger

IF reset
  OUTA[rST]~                   'RST Low to force RESET
  WAITCNT((CLKFREQ / 10) + CNT)
  OUTA[rST]~~                  'High for default
  WAITCNT(CLKFREQ + CNT)       'Allow time for settle
             

'Setup lines for RTS/CTS handshaking with Datalogger----------------------
DIRA[cTS]~               'Define CTS on Prop as input, it is connected to
                         'the RTS output of datalogger
OUTA[rTS]~~              'High
DIRA[rTS]~~              'Define RTS on Prop as output in High state, it
                         'is connected to CTS of Datalogger. When RTS
                         'goes down, it signals the Datalogger that the
                         'Prop requests communication

'Setup Ring Indicator line and toggle it----------------------------------
OUTA[rNG]~~
DIRA[rNG]~~
WAITCNT((CLKFREQ / 10) + CNT)
OUTA[rNG]~
WAITCNT((CLKFREQ / 10) + CNT)
OUTA[rNG]~~

'Take Vinculum out of Post Power On Idle State----------------------------
OUTA[rTS] := 0                      'RTS on Prop goes down
WAITCNT(2 * CLKFREQ + CNT)          'Allow time to settle
yesNo := Wait(_TIMEOUT_MS)          'Check the RTS line of datalogger
IF (NOT yesNo)
  ptrErrMess := @strTimeOut
  RETURN

'The first task of the application is to establish a connection to and
'synchronize with the VNC1L-1A firmware monitor. This is accomplished
'by sending and receiving echo commands until the VNC1L-1A echoes them
'back. The code of Sync repeatedly sends out a capital "E" followed by
'Carrige Return $0D (CR) until the chip echoes the bytes back in the same
'order. The synchronization can be done with "e" + CR, too.   

'Synchronise with VNC1L-1A firmware monitor-------------------------------
yesNo := Sync                       'Synchronized?

IF (NOT yesNo)
  'Then check other baud rates. If we just restart the Prop meanwhile
  'letting the Vinculum powered, the Datalogger may use a different, non
  'default baud rate, that might have been set previously. Take care when
  'not using the AUTO RESET option
  UART.Stop   
  UART.StartRxTx(rXP, tXP, _DEF_MODE, 115200)
  baudR := 115200
  yesNo := Sync
  IF (NOT yesNo)
    UART.Stop   
    UART.StartRxTx(rXP, tXP, _DEF_MODE, 57600)
    baudR := 57600
    yesNo := Sync
    IF (NOT yesNo)
      UART.Stop   
      UART.StartRxTx(rXP, tXP, _DEF_MODE, 38400)
      baudR := 38400
      yesNo := Sync 
      IF (NOT yesNo)
        UART.Stop   
        UART.StartRxTx(rXP, tXP, _DEF_MODE, 19200)
        baudR := 19200
        yesNo := Sync

IF (NOT yesNo)                          'Try RESET
  OUTA[rST]~                            'RST Low to force RESET
  WAITCNT(CLKFREQ + CNT)
  OUTA[rST]~~                           'High for default
  WAITCNT(CLKFREQ + CNT)                'Allow time for settle
  'Start Parallax Serial Terminal for UART in default baud rate
  UART.Stop 
  cid := UART.StartRxTx(rX, tX, _DEF_MODE, _DEF_BAUD)
  baudR := _DEF_BAUD
  'Synchronise with VNC1L-1A firmware monitor-----------------------------
  yesNo := Sync                          'Synchronized?        

IF (NOT yesNo)
  baudR := -1
  ptrErrMess := @strNoSync
  ptrStatMess := @strNoSync
  RETURN

'Initialise arrays and pointers for Directory, File, IDDE operations
cmd_Set := _EXTEN
nOfDirs := 0
ptrDirNames[0] := @strDirNames
nOfFiles := 0
ptrFileNames[0] := @strFileNames
nOfIDDEs := 0
ptrIDDEs[0] := @strIDDE

'Actuate status string
RETURN Disk_Online
'-------------------------------------------------------------------------


PUB Stop
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ Stop │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Stops driver
'' Parameters: None                                 
''    Returns: None                    
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: Monitor_Suspend
''             Parallax Serial Terminal----------->UART.Stop  
'-------------------------------------------------------------------------
Monitor_Suspend
UART.Stop
'-------------------------------------------------------------------------


PUB Some_Error : yesNo
'-------------------------------------------------------------------------
'------------------------------┌───────────┐------------------------------
'------------------------------│ Some_Error│------------------------------
'------------------------------└───────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Cheks for an error
'' Parameters: None                                 
''    Returns: TRUE if some error occured, else FALSE                    
''+Reads/Uses: ptrErrMess                         (VAR/LONG)
''             strNone                            (DAT/string)
''    +Writes: None                                    
''      Calls: None
'-------------------------------------------------------------------------
RESULT := NOT STRCOMP(ptrErrMess, @strNone)
'-------------------------------------------------------------------------


PUB Baud_Rate
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ Baud_Rate │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Returns actual baud rate of Vinculum's UART
'' Parameters: None                                 
''    Returns: Baud rate of Vinculum's UART                   
''+Reads/Uses: baudR                              (VAR/LONG)
''    +Writes: None                                    
''      Calls: None
'-------------------------------------------------------------------------
RESULT := baudR
'-------------------------------------------------------------------------


PUB Status_Message : strPtr
'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ Status_Message │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Passes reference to status message pointer
'' Parameters: None                                 
''    Returns: Pointer to status message                
''+Reads/Uses: ptrStatMess                   
''    +Writes: None                               (VAR/LONG)
''      Calls: None
'-------------------------------------------------------------------------
RESULT := @ptrStatMess
'-------------------------------------------------------------------------


PUB Error_Message : strPtr
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ Error_Message │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Passes reference to error message pointer
'' Parameters: None                                 
''    Returns: Pointer to error message                   
''+Reads/Uses: ptrErrMess                         (VAR/LONG)
''    +Writes: None                                    
''      Calls: None
'-------------------------------------------------------------------------
RESULT := @ptrErrMess
'-------------------------------------------------------------------------


PUB Error_Code : errCode
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ Error_Code │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Sets Error Code
'' Parameters: None                                 
''    Returns: Error Code                  
''+Reads/Uses: Error message strings              (DAT/string)
''             Error codes                        (CON)
''    +Writes: None                                    
''      Calls: None
'-------------------------------------------------------------------------
CASE ptrErrMess
  @strNotRec:   RETURN _NOTRECOG   
  @strNoNE:     RETURN _NONE
  @NODISK:      RETURN _NODISK  
  @BADCOMMAND:  RETURN _BADCOMMAND
  @CMDFAILED:   RETURN _CMDFAILED
  @DIRNOTEMPTY: RETURN _DIRNOTEMPTY
  @FILEOPEN:    RETURN _FILEOPEN
  @strBlocked:  RETURN _BLOCKED 
  @INVALID:     RETURN _INVALID
  @FNINVALID:   RETURN _FNINVALID  
  @SHORTNODISK: RETURN _NODISK  
  @SHORTBADCOM: RETURN _BADCOMMAND
  @SHORTCMDF:   RETURN _CMDFAILED
  @SHORTDIRNE:  RETURN _DIRNOTEMPTY
  @SHORTFILEO:  RETURN _FILEOPEN
  @SHORTINV:    RETURN _INVALID
  @SHORTFNINV:  RETURN _FNINVALID  
'-------------------------------------------------------------------------


DAT '--------------------Basic Monitor Operations-------------------------


PUB Monitor_Reset : yesNo
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ Monitor_Reset │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Resets Vinculum firmware monitior
'' Parameters: None                                
''    Returns: TRUE if action successful, else FALSE       
''+Reads/Uses: rST, rNG, rTS, rXp, rXT            (VAR/BYTE)
''             _DEF_MODE, _DEF_BAUD               (CON)
''             strTimeOut                         (DAT/string)
''    +Writes: baudR
''             ptrErrMess            
''      Calls: Parallax Serial Terminal----------->UART.Stop
''                                                 UART.StartRxTx
''             Wait
''             Sync
'-------------------------------------------------------------------------
OUTA[rST]~                               'RST Low to force RESET
WAITCNT((CLKFREQ / 10) + CNT)
OUTA[rST]~~                              'High for default
WAITCNT(CLKFREQ + CNT)                   'Allow time for settle

'Toggle Ring Indicator Line-----------------------------------------------
OUTA[rNG]~
WAITCNT((CLKFREQ / 10) + CNT)
OUTA[rNG]~~

'Set UART baud rate of driver to default 9600-----------------------------
UART.Stop   
UART.StartRxTx(rXP, tXP, _DEF_MODE, _DEF_BAUD)
baudR := _DEF_BAUD

'Take Vinculum out of Idle State------------------------------------------
OUTA[rTS] := 0                      'RTS on Prop goes down
WAITCNT(2 * CLKFREQ + CNT)          'Allow time to settle
yesNo := Wait(_TIMEOUT_MS)          'Check the RTS line of datalogger
IF (NOT yesNo)
  ptrErrMess := @strTimeOut
  RETURN

'Synchronize with VNC1L-1A firmware monitor-------------------------------
RETURN Sync                   
'-------------------------------------------------------------------------


PUB Monitor_BaudRate(baudRate) : yesNo | b1, b2, cid
'-------------------------------------------------------------------------
'----------------------------┌──────────────────┐-------------------------
'----------------------------│ Monitor_BaudRate │-------------------------
'----------------------------└──────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Sets baud rate of VNC1L-1A firmware monitor's UART
'' Parameters: Baud Rate (of 9600, 19200, 38400, 57600, 115200 in v1.0)                                
''    Returns: TRUE if action successful, else FALSE       
''+Reads/Uses: strSomeErr, strBadPar, strNone     (DAT/string)             
''    +Writes: ptrStatMess, ptrErrMess            (VAR/LONG)
''             baudR                              (VAR/LONG)
''      Calls: Parallax Serial Terminal----------->UART.Stop
''                                                 UART.StartRxTx
''             SBD
''             Wait
''             Sync
''       Note: The driver was fully functional with 57600, but some slower
''             drives stopped at random access read/writes at 115K
'-------------------------------------------------------------------------
baudR := baudRate
CASE baudRate
  9600:
    b1 := $38
    b2 := $41
  19200:
    b1 := $9C
    b2 := $80
  38400:
    b1 := $4E
    b2 := $C0
  57600:
    b1 := $34
    b2 := $C0
  115200:
    b1 := $1A
    b2 := $00
  OTHER:
    ptrStatMess := @strSomeErr
    ptrErrMess := @strBadPar 
    RETURN FALSE

RETURN SBD( b1, b2)
'-------------------------------------------------------------------------


PUB Monitor_Suspend : yesNo
'-------------------------------------------------------------------------
'----------------------------┌─────────────────┐--------------------------
'----------------------------│ Monitor_Suspend │--------------------------
'----------------------------└─────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Suspends VNC1L-1A Monitor and stops its clocks
'' Parameters: None                                 
''    Returns: TRUE if action successful, else FALSE
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: SUM
''       Note: - Monitor goes to sleep only with an awake Drive
''             - Setting RNG line to Low resumes Vinculum from Suspend
'-------------------------------------------------------------------------
yesNo := Disk_WakeUp                     'Awake Drive
IF (NOT yesNo)
  RETURN                                 
RETURN SUM                             'Suspend Monitor
'-------------------------------------------------------------------------


PUB Monitor_WakeUp : yesNo
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ Monitor_WakeUp │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Wakes up monitor
'' Parameters: None                                 
''    Returns: TRUE if action successful, else FALSE
''+Reads/Uses: rNG, strReady          
''    +Writes: ptrStatMess                             
''      Calls: Sync
'-------------------------------------------------------------------------
OUTA[rNG]~                                 'Ring Monitor
WAITCNT((CLKFREQ / 5) + CNT)
OUTA[rNG]~~

yesNo := Sync                              'Check synchronization

IF (yesNo)
  ptrStatMess := @strReady
'-------------------------------------------------------------------------


DAT '-----------------------Basic Disk Operations-------------------------


PUB Disk_Online : yesNo | resp 
'-------------------------------------------------------------------------
'-----------------------------┌─────────────┐-----------------------------
'-----------------------------│ Disk_Online │-----------------------------
'-----------------------------└─────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Checks online disk
'' Parameters: None                                 
''    Returns: TRUE if disk is online, else FALSE
''+Reads/Uses: UART#NL
''             strBuffer
''             rTS                   
''    +Writes: ptrErrMess, ptrStatMess                                    
''      Calls: PrepCmd
''             EvalString
''             Parallax Serial Terminal----------->UART.RxFlush
''                                                 UART.Char
''                                                 UART.StrIn
'-------------------------------------------------------------------------
yesNo := PrepCmd
IF (NOT yesNo)
  RETURN

UART.RxFlush                         'Clear UART Rx buffer

'-------------------------Send an "Enter" command-------------------------
UART.Char(UART#NL)                              
'-------------------------------------------------------------------------

UART.StrIn(@strBuffer)               'Read in response until CR

OUTA[rTS] := 1                       'Signal to suspend communication

resp := EvalString                   'Evaluate response

CASE resp
  0:
    yesNo := TRUE
    ptrStatMess := @strDiskOn
  1: 
    yesNo := FALSE    
    ptrStatMess := @NODISK
  OTHER:
    yesNo := FALSE
    ptrStatMess := @strSomeErr
    ptrErrMess := @strBuffer
'-------------------------------------------------------------------------


PUB Disk_IDDE(nID_, ptrID_) : yesNo
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ Disk_IDDE │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Gets Identify Disk Drive (Extended) results
'' Parameters: Pointer to # of IDDE strings
''             Pointer to pointer array to IDDE strings                               
''    Returns: TRUE if action successful, else FALSE
'' Returns by: nID _ --> # of IDDE strings
''             ptrID_ -> Pointer array to IDDE strings                
''+Reads/Uses: nOfIDDEs                           (VAR/LONG)
''             ptrIDDEs                           (VAR/LONG)
''    +Writes: None                                
''      Calls: Sync
''             IDDE
'-------------------------------------------------------------------------
IF (NOT Sync)
  RETURN FALSE
  
nOfIDDEs~
yesNo := IDDE

IF (yesNo)
  LONG[nID_] := nOfIDDEs
  LONG[ptrID_] := @ptrIDDEs
'-------------------------------------------------------------------------


PUB Disk_Free_Space(hiFS_, loFS_) : yesNo
'-------------------------------------------------------------------------
'---------------------------┌─────────────────┐---------------------------
'---------------------------│ Disk_Free_Space │---------------------------
'---------------------------└─────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Gets free space on drive 
'' Parameters: Pointer to upper 2 bytes of result
''             Pointer to lower 4 bytes of result                                 
''    Returns: TRUE if action successful, else FALSE 
'' Returns by: hiFS_ -> Upper 2 bytes of result
''             loFS_ -> lower 4 bytes of result                 
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: FSE
'-------------------------------------------------------------------------
RETURN FSE(hiFS_, loFS_)
'-------------------------------------------------------------------------


PUB Disk_Free_K(fsK_) : yesNo | fh, fl, fk
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ Disk_Free_K │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Gets free space on drive in Kbytes 
'' Parameters: Pointer to result                                
''    Returns: TRUE if action successful, else FALSE 
'' Returns by: fsK_ -> Result            
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: FSE
'-------------------------------------------------------------------------
yesNo := FSE(@fh, @fl)
IF (yesNo)
  fk := (fl >> 10) + (fh << 22)
  LONG[fsK_] := fk
ELSE
  LONG[fsK_] := -1    
'-------------------------------------------------------------------------


PUB Disk_Suspend : yesNo
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ Disk_Suspend │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Automatically suspend disk when not in use 
'' Parameters: None                                 
''    Returns: TRUE if action successful, else FALSE              
''+Reads/Uses: strSUD                             (DAT/string)
''    +Writes: None                                    
''      Calls: CmdNL
''       Note: - Due to the variability of the quality of  USB Flash Disks
''             it is not always possible to reliably suspend and restore
''             disks.
''             - There is a large latency in accessing a disk in Suspend
''             Disk Mode. If frequent or rapid access to data on a disk is
''             required then the disk should be waked up (with Disk_WakeUp)
''             before the data is transferred.
''             - It is highly recommended that the disk should not be
''             suspended while a file is opened for write or read. 
''-------------------------------------------------------------------------
yesNo := CmdNL(@strSUD)
WAITCNT((CLKFREQ / 10) + CNT)          'Allow time to settle
'-------------------------------------------------------------------------


PUB Disk_WakeUp : yesNo
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Disk_WakeUp │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Keeps disk active when not in use
'' Parameters: None                                 
''    Returns: TRUE if action successful, else FALSE           
''+Reads/Uses: strWKD                             (DAT/string)
''    +Writes: None                                    
''      Calls: CmdNL 
''       Note: If frequent or rapid access to data on a disk is required
''             then the disk should be waked up before the data is
''             transferred.
'-------------------------------------------------------------------------
yesNo := CmdNL(@strWKD)
WAITCNT((CLKFREQ / 10) + CNT)          'Allow time to settle
'-------------------------------------------------------------------------


DAT '----------------------Basic Sector Operations------------------------

{
PUB Sector_Read(sectNo, ptrBuff_) : yesNo
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ Sector_Read │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Reads sector (512 bytes) from drive
'' Parameters: Sector #
''             Pointer to data buffer                                 
''    Returns: TRUE if action successful, else FALSE
'' Returns by. ptrBuff_ -> Start address of 512 byte sector data           
''+Reads/Uses: strFileNames                       (DAT/string)             
''    +Writes: None                                    
''      Calls: SD
''       Note: Overwrites the string buffer of file/dir names  
'-------------------------------------------------------------------------
yesNo := SD(sectNo)
IF (yesNo)
  LONG[ptrBuff_] := @strFileNames
'-------------------------------------------------------------------------


PUB Sector_Write(sectNo, ptrBuff_) : yesNo
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ Sector_Write │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes 512 bytes to sector of drive
'' Parameters: Sector number
''             Pointer to data buffer                                   
''    Returns: TRUE if action successful, else FALSE           
''+Reads/Uses: None                  
''    +Writes: None                                   
''      Calls: SW
''       Note: This is a quick and easy way to destroy your valuable data
''             on the drive. Take care and use this direct sector write
''             procedure only when you know what you are doing. Otherwise
''             disk and file system corruption can occur               
'-------------------------------------------------------------------------
RETURN SW(sectNo, ptrBuff_)
'-------------------------------------------------------------------------
}

DAT '--------------------Basic Directory Operations-----------------------


PUB Dir_List(nF_, ptrFN_, nD_, ptrDN_) : yesNo | dummy
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ Dir_List │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Lists contents of current directory
'' Parameters: Pointer to # of files
''             Pointer to file name strings
''             Pointer to # of directories
''             Pointer to directory name strings                                
''    Returns: TRUE if action successful, else FALSE
'' Returns by: nF_    -> Number of files
''             ptrFN_ -> Array of filename pointers
''             nD_    -> Number of directories
''             ptrFN_ -> Array of directory name pointers
''+Reads/Uses: strNull, strSomeErr                (DAT/string)
''             nOfFiles, nOfDirs                  (VAR/LONG)
''             ptrFileNames, ptrDirNames          (VAR/LONG array)          
''    +Writes: None                                     
''      Calls: Sync
''             DIR
''       Note: Set the _MAXFILES, _MAXDIRS constants (default 64, 32) as
''             your application requires.
'-------------------------------------------------------------------------
IF (NOT Sync)
  RETURN FALSE
  
nOfFiles~
nOfDirs~
yesNo := DIR(@strNull, @dummy)
IF (yesNo)
  LONG[nF_] := nOfFiles
  LONG[ptrFN_] := @ptrFileNames
  LONG[nD_] := nOfDirs
  LONG[ptrDN_] := @ptrDirNames
ELSE
  LONG[nF_] := -1
  LONG[nD_] := -1
'-------------------------------------------------------------------------


PUB Dir_Change(ptrDirName_) : yesNo
'-------------------------------------------------------------------------
'--------------------------------┌────────────┐---------------------------
'--------------------------------│ Dir_Change │---------------------------
'--------------------------------└────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Changes directory
'' Parameters: Pointer to directory name            
''    Returns: TRUE if action successful, else FALSE  
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: CmdNameNL
'-------------------------------------------------------------------------
RETURN CmdNameNL(@strCD, ptrDirName_)
'-------------------------------------------------------------------------

{
PUB Dir_Make(ptrDirName_) : yesNo
'-------------------------------------------------------------------------
'---------------------------------┌──────────┐----------------------------
'---------------------------------│ Dir_Make │----------------------------
'---------------------------------└──────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Makes new directory
'' Parameters: Pointer to directory name                                 
''    Returns: TRUE if action successful, else FALSE                  
''+Reads/Uses: strMKD                             (DAT/string)
''    +Writes: None                                    
''      Calls: CmdNameNL
''       Note: None
'-------------------------------------------------------------------------
RETURN CmdNameNL(@strMKD, ptrDirName_)
'-------------------------------------------------------------------------


PUB Dir_Rename(pDN1_, pDN2_) : yesNo
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ Dir_Rename │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Renames directory
'' Parameters: Pointer to directory name
''             Pointer to new directory name                  
''    Returns: TRUE if action successful, else FALSE           
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: REN
'-------------------------------------------------------------------------
RETURN REN(pDN1_, pDN2_)
'-------------------------------------------------------------------------


PUB Dir_Delete_Empty(ptrDirName_) : yesNo
'-------------------------------------------------------------------------
'-----------------------------┌──────────────────┐------------------------
'-----------------------------│ Dir_Delete_Empty │------------------------
'-----------------------------└──────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Deletes empty directory
'' Parameters: Pointer to directory name                                 
''    Returns: TRUE if action successful, else FALSE       
''+Reads/Uses: strDLD                             (DAT/string)
''    +Writes: None                                    
''      Calls: CmdNameNL
'-------------------------------------------------------------------------
RETURN CmdNameNL(@strDLD, ptrDirName_)
'-------------------------------------------------------------------------
}

DAT '-----------------------Basic File Operations-------------------------


PUB File_Size(ptrFileName_, ptrSize_) : yesNo
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ File_Size │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Gets size of file
'' Parameters: Pointer to filename
''             Pointer to LONG that holds result (-1 if op failed)                                 
''    Results: TRUE if operation successful, else FALSE                    
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: Sync
''             UCASE
''             DIR
''       Note: - The operation will be successful when
''               ~ Disk is online
''               ~ No file is opened
''               ~ File exists in the current directory
''             - When the 'filename' is a directory, a size of zero will
''             be displayed             
'-------------------------------------------------------------------------
IF (NOT Sync) 
  RETURN FALSE

UCASE(ptrFileName_)
File_Close(ptrFileName_)

yesNo := DIR(ptrFileName_, ptrSize_)
IF(NOT yesNo)
  LONG[ptrSize_] := -1  
'-------------------------------------------------------------------------


PUB File_Open_For_Read(ptrFileName_)
'-------------------------------------------------------------------------
'---------------------------┌────────────────────┐------------------------
'---------------------------│ File_Open_For_Read │------------------------
'---------------------------└────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Opens file for read
'' Parameters: Pointer to filename                                 
''    Returns: TRUE if action successful, else FALSE                   
''+Reads/Uses: strOPR                             (DAT/string)
''    +Writes: None                                    
''      Calls: CmdNameNL
''       Note: If open for read then it may only be read from. A file
''             pointer that indicates from where reads and writes will
''             commence is maintained for the currently open file. The
''             File_Seek procedure can be used to move the file pointer
''             within a file
'-------------------------------------------------------------------------
RETURN CmdNameNL(@strOPR, ptrFileName_)
'-------------------------------------------------------------------------

{
PUB File_ReadAll(ptrFileName_, fSize_, bSize, ptrBuf_) : yesNo | fsz
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ File_ReadAll │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Reads entire file
'' Parameters: Pointer to file name
''             Pointer to file size
''             Size of data buffer
''             Pointer to data buffer                                
''    Returns: TRUE if action successful, else FALSE
'' Returns by: ptrBuf_ -> File data             
''+Reads/Uses: stSomeErr                          (DAT/string)
''    +Writes: ptrStatMess, ptrErrMess            (VAR/LONG)                        
''      Calls: File_Size
''             RD
''       Note: - The file should be small enough not to overrun the
''             buffer
''             - Read in large files part by part with the
''              File_Random_Access_Read procedure.
''             - No file must be open directly before this procedure
'-------------------------------------------------------------------------
IF (NOT File_Size(ptrFileName_, fSize_)) 
  RETURN FALSE

IF (LONG[fSize_] > bSize)
  ptrStatMess := @strSomeErr
  ptrErrMess := @strBadPar
  RETURN FALSE

RETURN RD(ptrFileName_, LONG[fSize_], ptrBuf_)
'-------------------------------------------------------------------------
}

PUB File_Seek(offset) : yesNo
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ File_Seek │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Seeks to an offset within open file
'' Parameters: Position in file                                 
''    Returns: TRUE if action successful, else FALSE                  
''+Reads/Uses: None                   
''    +Writes: None                                    
''      Calls: SEK
''       Note: - File should be opened
''             - Position is valid from 0 to File Size. 0 means 1st byte
''             in File, Position File Size means the position after the
''             last byte
'-------------------------------------------------------------------------
RETURN SEK(offset)
'-------------------------------------------------------------------------


PUB File_Open_For_Write(ptrFileName_) : yesNo
'-------------------------------------------------------------------------
'--------------------------┌─────────────────────┐------------------------
'--------------------------│ File_Open_For_Write │------------------------
'--------------------------└─────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Opens a file for writing and reading or creates a new file
'' Parameters: Pointer to file name                                 
''    Returns: TRUE if action successful, else FALSE                     
''+Reads/Uses: strOPW                             (DAT/string)
''    +Writes: None                                    
''      Calls: CmdNameNL
''       Note: - If a file is open for writing, then it may be both written
''             to and read from.
''             - The end of the file is moved to the position of the file
''             pointer after a write operation and files open for write
''             will be truncated at the file pointer when closed. In other
''             words, if you write, say 10 bytes, into the middle of a
''             large file with the WRF procedure, all data after the 10
''             bytes will be lost. RIP. But wou can use the
''
''                             File_Random_Access_Write
''
''             procedure to overwrite data within file, if required
'-------------------------------------------------------------------------
RETURN CmdNameNL(@strOPW, ptrFileName_)
'-------------------------------------------------------------------------


PUB File_Append(dataSize, ptrData_) : yesNo
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ File_Append │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Appends data to open file 
'' Parameters: Number of data bytes
''             Pointer to buffer                                
''    Returns: TRUE if action successful, else FALSE              
''+Reads/Uses: _APPBLK_SIZE                       (CON)
''             strBadPar, strSomeErr              (DAT/string)      
''    +Writes: ptrErrMess, ptrStatMess            (VAR/LONG)                        
''      Calls: Sync
''             WRF
''       Note: Assumes an open file for write. Designed for continuous
''             data transfer, and it does not close the file 
'-------------------------------------------------------------------------
IF (dataSize > _APPBLK_SIZE)
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN FALSE

IF (NOT Sync)
  RETURN FALSE
  
RETURN WRF(dataSize, ptrData_)
'-------------------------------------------------------------------------


PUB File_Close(ptrFileName_) : yesNo
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ File_Close │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Closes currently open file
'' Parameters: Pointer to file name                                
''    Returns: TRUE if action successful, else FALSE           
''+Reads/Uses: strCLF                             (DAT/string)                
''    +Writes: None                                    
''      Calls: CmdNameNL
''       Note: - If the file exists and is not opened, this procedure does
''             not cause error. You can call it safely, for example,
''             before every File_Open procedure to avoid reopening a file,
''             which does, however, cause an error. Besides, many FAT
''             procedures of the monitor do not work with a file open.
''             - When file does not exist in the current directory, this
''             procedure causes an error. And this is, of course, good as
''             we can skip further operations with that nonexisting file     
'-------------------------------------------------------------------------
RETURN CmdNameNL(@strCLF, ptrFileName_)
'-------------------------------------------------------------------------

{
PUB File_Append_Close(ptrFileName_, dataSize, ptrData_) : yesNo
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ File_Append_Close │--------------------------
'--------------------------└-──────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: - Opens file
''             - Appends data
''             - Closes file
'' Parameters: Pointer to filename
''             Data size in bytes
''             Pointer to data buffer                                 
''    Returns: TRUE if action successful, else FALSE             
''+Reads/Uses: _CPYBLK_SIZE                       (CON)
''             strBadPar, strSomeErr              (DAT/string)                  
''    +Writes: ptrErrMess, ptrStatMess            (VAR/LONG)                        
''      Calls: File_Close
''             File_Open_For_Write
''             File_Append
'-------------------------------------------------------------------------
IF (dataSize > _CPYBLK_SIZE)
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN FALSE

IF (NOT File_Close(ptrFileName_))
  RETURN FALSE

IF (NOT File_Open_For_Write(ptrFileName_))
  RETURN FALSE

IF (NOT File_Append(dataSize, ptrData_))
  RETURN FALSE

RETURN File_Close(ptrFileName_)
'-------------------------------------------------------------------------
}
{
PUB File_Rename(pFN1_, pFN2_) : yesNo
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ File_Rename │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Renames file
'' Parameters: Pointer to filename
''             Pointer to new filename                  
''    Returns: TRUE if action successful, else FALSE           
''+Reads/Uses: None   
''    +Writes: None           
''      Calls: REN
'-------------------------------------------------------------------------
RETURN REN(pFN1_, pFN2_)
'-------------------------------------------------------------------------
}

PUB File_Delete(ptrFileName_) : yesNo
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ File_Delete │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Deletes file
'' Parameters: Pointer to file name                  
''    Returns: TRUE if action successful, else FALSE           
''+Reads/Uses: None   
''    +Writes: None            
''      Calls: CmdNameNL
'-------------------------------------------------------------------------
RETURN CmdNameNL(@strDLF, ptrFileName_)
'-------------------------------------------------------------------------


DAT '---------------------Advanced Sector Operations----------------------

{
PUB Sector_Peek(sectNo, datAddr, datSize, ptrBuf_) : yesNo
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Sector_Peek │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Reads datablock from sector
'' Parameters: Sector number
''             Address of datablock
''             Size of datablock
''             Pointer to buffer                                  
''    Returns: TRUE if action successful, else FALSE                   
''+Reads/Uses: _SECTOR_SIZE                       (CON)
''             strBadPar, strSomeErr              (DAT/string)                
''    +Writes: ptrErrMess, ptrStatMess            (VAR/LONG)
''             strFileNames                       (VAR/BYTE array)                               
''      Calls: Sector_Read
'-------------------------------------------------------------------------
IF ((datAddr + datSize) > (_SECTOR_SIZE - 1))
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN FALSE
IF (NOT Sector_Read(sectNo, @strFileNames))
  RETURN FALSE
BYTEMOVE(ptrBuf_, @strFileNames + datAddr, datSize)      
'-------------------------------------------------------------------------


PUB Sector_Poke(sectNo, datAddr, datSize, ptrBuf_) : yesNo
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Sector_Poke │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes datablock into sector
'' Parameters: Sector number
''             Address of datablock
''             Size of datablock
''             Pointer to buffer                                  
''    Returns: TRUE if action successful, else FALSE                   
''+Reads/Uses: _SECTOR_SIZE                       (CON)
''             strBadPar, strSomeErr              (DAT/string)                
''    +Writes: ptrErrMess, ptrStatMess            (VAR/LONG)
''             strFileNames                       (VAR/BYTE array)         
''      Calls: Sector_Read
''             Sector_Write 
'-------------------------------------------------------------------------
IF ((datAddr + datSize) > (_SECTOR_SIZE - 1))
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN FALSE
IF (NOT Sector_Read(sectNo, @strFileNames))
  RETURN FALSE
BYTEMOVE(@strFileNames + datAddr, ptrBuf_, datSize)
RETURN Sector_Write(sectNo, @strFileNames)     
'-------------------------------------------------------------------------
}

DAT '-------------------Advanced Directory Operations---------------------


PUB Dir_Set_To_Root : yesNo | done, dummy
'-------------------------------------------------------------------------
'----------------------------┌─────────────────┐--------------------------
'----------------------------│ Dir_Set_To_Root │--------------------------
'----------------------------└─────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Sets current directory to root directory
'' Parameters: None                                 
''    Returns: TRUE if action successful, else FALSE                   
''+Reads/Uses: strEmpty, dummy                   
''    +Writes: None                                    
''      Calls: DIR
'-------------------------------------------------------------------------
IF (NOT Sync)
  RETURN FALSE
  
done := FALSE
REPEAT UNTIL done
  yesNo := CmdNameNL(@strCD, STRING(".."))
  IF(NOT yesNo)
    done := TRUE
    
RETURN DIR(@strNull, @dummy)
'-------------------------------------------------------------------------


DAT '---------------------Advanced File Operations------------------------


PUB File_Random_Access_Read(pFN_, bP, nB, pB_) : yesNo | s
'-------------------------------------------------------------------------
'------------------------┌─────────────────────────┐----------------------
'------------------------│ File_Random_Access_Read │----------------------
'------------------------└─────────────────────────┘----------------------
'-------------------------------------------------------------------------
''     Action: - Gets file size
''             - Opens file for reading
''             - Seeks position in file
''             - Reads data into buffer
''             - Closes file   
'' Parameters: Pointer to file name 
''             Position of 1st byte to read (1st is at 0, 2nd is at 1,.)
''             Number of bytes to read
''             Pointer to data buffer
''    Returns: TRUE if action successful, else FALSE
'' Returns by: pB_ -> Datablock from file (nB bytes)
''+Reads/Uses: strBadpar, strSomeErr              (DAT/string)                  
''    +Writes: ptrErrMess, ptrStatMess            (VAR/LONG)
''      Calls: File_Close
''             File_Size
''             File_Open_For_Read
''             File_Seek
''             RDF 
''       Note: - This procedure of the driver does (can) not check for 
''             buffer overrun in the caller's code. This is the task of
''             the calling application (i.e. of your code) to manage that
''             - The position of the 1st byte in the file is seeked at 0,
''             the second byte is at 1, etc... 
'-------------------------------------------------------------------------
IF (NOT File_Close(pFN_)) 
  RETURN FALSE
  
IF (NOT File_Size(pFN_, @s))
  RETURN FALSE

IF ((s < (bP + nB)) OR (nB =< 0))        'File is small for required data
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN FALSE

IF (NOT File_Open_For_Read(pFN_)) 
  RETURN FALSE
  
IF (NOT File_Seek(bP)) 
  RETURN FALSE   

IF (NOT RDF(nB, pB_)) 
  RETURN FALSE

RETURN File_Close(pFN_) 
'-------------------------------------------------------------------------

{
PUB File_Random_Access_Write(pFN_,bP,nB,pB_):yesNo|fsz,f,sh,sl
'-------------------------------------------------------------------------
'------------------------┌──────────────────────────┐---------------------
'------------------------│ File_Random_Access_Write │---------------------
'------------------------└──────────────────────────┘---------------------
'-------------------------------------------------------------------------
''     Action: Overwrites data in file
'' Parameters: Pointer to file name
''             Position of data        (0 for 1st byte, 1 for 2nd, etc...)
''             Number of bytes
''             Pointer to data buffer                                   
''    Returns: TRUE if action successful, else FALSE
''+Reads/Uses: strBadpar, strSomeErr              (DAT/string)                  
''    +Writes: ptrErrMess, ptrStatMess            (VAR/LONG)
''      Calls: File_Close
''             File_Size
''             Disk_Free_Space
''             Sync
''             File_Split
''             File_Merge
''             File_Delete
''       Note: File size does not change
'-------------------------------------------------------------------------
IF (NOT File_Close(pFN_)) 
  RETURN FALSE
  
'Get size of file
IF (NOT File_Size(pFN_, @fsz)) 
  RETURN FALSE

'Get free space on disk (we need space for tmp files)
IF (NOT Disk_Free_Space(@sh, @sl)) 
  RETURN FALSE

f := (fsz + nB) >> 16
sl := sl >> 16
sh := sh << 16
sl := sl + sh
'Check available space 
IF (f > sl)
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN FALSE 

'Check space in file
IF (((bP + nB) > fsz) OR (nB =< 0))
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN FALSE

'Split file at overwrite (bP) position
IF (NOT File_Split(pFN_, bP, @strFR1, @strFR2)) 
  RETURN FALSE

'Append data (nB bytes)to 1st part
IF (NOT File_Append_Close(@strFR1, nB, pB_)) 
  RETURN FALSE

'Split 2nd part at nB
IF (NOT File_Split(@strFR2,nB,@strFR3,@strFR4)) 
  RETURN FALSE

'Merge 1st and last files 
IF (NOT File_Merge(@strFR1,@strFR4,pFN_))
  RETURN FALSE
 
'Delete temporary files
File_Delete(@strFR1)
File_Delete(@strFR2)
File_Delete(@strFR3)
File_Delete(@strFR4)
 '-------------------------------------------------------------------------


PUB File_Random_Access_Insert(pFN_,bP,nB,pB_):yesNo|fsz,f,sh,sl
'-------------------------------------------------------------------------
'-----------------------┌───────────────────────────┐---------------------
'-----------------------│ File_Random_Access_Insert │---------------------
'-----------------------└───────────────────────────┘---------------------
'-------------------------------------------------------------------------
''     Action: Inserts data into file
'' Parameters: Pointer to file name
''             Position of data        (0 for 1st byte, 1 for 2nd, etc...)
''             Number of bytes
''             Pointer to data buffer                                   
''    Returns: TRUE if action successful, else FALSE
''+Reads/Uses: strBadpar, strSomeErr              (DAT/string)                  
''    +Writes: ptrErrMess, ptrStatMess            (VAR/LONG)
''      Calls: File_Close
''             File_Size
''             Disk_Free_Space
''             Sync
''             File_Split
''             File_Merge
''             File_Delete
''       Note. File size increases with nB
'-------------------------------------------------------------------------
IF (NOT File_Close(pFN_)) 
  RETURN FALSE
  
'Get size of file
IF (NOT File_Size(pFN_, @fsz)) 
  RETURN FALSE

'Get free space on disk
IF (NOT Disk_Free_Space(@sh, @sl))
  RETURN FALSE

f := (fsz + nb) >> 16
sl := sl >> 16
sh := sh << 16
sl := sl + sh
'Check available space
IF (f > sl)
  ptrErrMess := @CMDFAILED
  ptrStatMess := @strSomeErr
  RETURN FALSE

'Check space in file
IF (((bP + nB) > fsz) OR (nB =< 0))
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN FALSE

'Split file at overwrite (bP) position
IF (NOT File_Split(pFN_, bP, @strFR1, @strFR2))
  RETURN FALSE

'Append data (nB bytes)to 1st part
IF (NOT File_Append_Close(@strFR1, nB, pB_)) 
  RETURN FALSE

IF (NOT Sync) 
  RETURN FALSE
  
'Merge files  
IF (NOT File_Merge(@strFR1,@strFR2,pFN_))
  RETURN FALSE

'Delete temporary files
File_Delete(@strFR1)
File_Delete(@strFR2)
'-------------------------------------------------------------------------


PUB File_Copy(pFN1_,pFN2_):yesNo|fsz,f,bsz,sph,spl,done,bdn,ncb
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ File_Copy │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Copies file in same directory
'' Parameters: Pointer to file name
''             Pointer to name of duplicate file
''    Returns: TRUE if action successful, else FALSE           
''+Reads/Uses: strBadPar, strSomeErr, CMDFAILED, strNone   (DAT/strings)
''             _CPYBLK_SIZE                                (CON)
''    +Writes: strFileNames byte array for file names                    
''      Calls: UCASE
''             File_Size
''             Disk_Free_Space
''             File_ReadAll
''             File_Append_Close
''             File_Random_Access_Read
''       Note: If file allready exists with name FN2 in current directory,
''             this procedure deletes it before the copy
'-------------------------------------------------------------------------
'Check for different file names
yesNo := NOT STRCOMP(UCASE(pFN1_) , UCASE(pFN2_))
IF (NOT yesNO)
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN

'Delete File FN2 (if exists) without warning. We are serious
File_Delete(pFN2_)

'Get size of 1st file
IF (NOT File_Size(pFN1_, @fsz)) 
  RETURN FALSE

'Get free space on disk
IF (NOT Disk_Free_Space(@sph, @spl)) 
  RETURN FALSE

f := fsz >> 16
spl := spl >> 16
sph := sph << 16
spl := spl + sph
'Check available space
IF (f > spl)
  ptrErrMess := @CMDFAILED
  ptrStatMess := @strSomeErr
  RETURN FALSE

'Set buffer size
bsz := _CPYBLK_SIZE

IF (NOT Sync) 
  RETURN FALSE   

'Copy 
bdn~                                    'Bytes Done is zero at start
done := FALSE
REPEAT UNTIL done
  IF (bdn < fsz)
    'Copy next chunk of data--------------------------------------------
    IF ((bdn + bsz) > fsz)             'Last block
      ncb := fsz - bdn                   
    ELSE                               'Next full block
      ncb := bsz
    IF (NOT File_Random_Access_Read(pFN1_, bdn, ncb, @strFileNames))
      RETURN FALSE
    IF (NOT File_Append_Close(pFN2_, ncb, @strFileNames))
      RETURN FALSE
  bdn := bdn + ncb
  IF (bdn => fsz)                     
    done := TRUE

File_Close(pFN1_)
File_Close(pFN2_)      
'-------------------------------------------------------------------------


PUB File_Split(pFN1_, bP, pFN2_, pFN3_) : yesNo | fsz, f, sph, spl
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ File_Split │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Splits file
'' Parameters: Pointer to filename
''             Byte position of split  
''             Pointer to filename of 1st part
''             Pointer to filename of 2nd part                               
''    Returns: TRUE if action successful, else FALSE                     
''+Reads/Uses: strBadPar, strSomeErr              (DAT/string)    
''    +Writes: ptrErrMess, ptrStatMess            (VAR/LONG)                        
''      Calls: UCASE
''             File_Size
''             File_Delete
''             Disk_Free_Space
''             SplitFile
''             File_Rename
'-------------------------------------------------------------------------
'Check distinct file names
yesNo := NOT STRCOMP(UCASE(pFN1_) , UCASE(pFN2_))
IF (NOT yesNO)
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN
yesNo := NOT STRCOMP(UCASE(pFN1_) , UCASE(pFN3_))
IF (NOT yesNO)
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN
yesNo := NOT STRCOMP(UCASE(pFN2_) , UCASE(pFN3_))
IF (NOT yesNO)
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN

'Get size of 1st file
yesNo := File_Size(pFN1_, @fsz)
IF (NOT yesNO) 
  RETURN

'Check valid split position
IF ((bP > fsz) OR (bP =< 1))
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN

'Delete File FN2, FN3
File_Delete(pFN2_)
File_Delete(pFN3_)

'Get free space on disk
IF (NOT Disk_Free_Space(@sph, @spl)) 
  RETURN FALSE

f := fsz >> 16
spl := spl >> 16
sph := sph << 16
spl := spl + sph
'Check free space
IF (f > spl)
  ptrErrMess := @CMDFAILED
  ptrStatMess := @strSomeErr
  RETURN FALSE

'Split file
IF (NOT SplitFile(pFN1_, bP)) 
  RETURN FALSE

'Rename files
IF (NOT File_Rename(@strSP1, pFN2_)) 
  RETURN FALSE
RETURN File_Rename(@strSP2, pFN3_) 
'-------------------------------------------------------------------------


PUB File_Merge(pFN1_,pFN2_,pFN3_):yesNo|s1,s2,s,sh,sl,bsz,bdn,done,ncb
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ File_Merge │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Merges 2 files
'' Parameters: Pointer to 1st filename
''             Pointer to 2nd filename 
''             Pointer to filename of merge file                               
''    Returns: TRUE if action successful, else FALSE                     
''+Reads/Uses: strBadPar, strSomeErr              (DAT/string)
''             _CPYBLK_SIZE                       (CON)   
''    +Writes: ptrErrMess, ptrStatMess            (VAR/LONG)                               
''      Calls: UCASE
''             File_Size
''             File_Delete
''             Disk_Free_Space
''             Sync
''             File_Copy
''             File_Random_Acccess_Read
''             File_Append_Close
'-------------------------------------------------------------------------
'Check for different file names
yesNo := NOT STRCOMP(UCASE(pFN1_) , UCASE(pFN3_))
IF (NOT yesNO)
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN
yesNo := NOT STRCOMP(UCASE(pFN2_) , UCASE(pFN3_))
IF (NOT yesNO)
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN

'Get size of 1st file
yesNo := File_Size(pFN1_, @s1)
IF (NOT yesNO) 
  RETURN

'Get size of 2nd file
yesNo := File_Size(pFN2_, @s2)
IF (NOT yesNO) 
  RETURN

'Get free space on disk
yesNo := Disk_Free_Space(@sh, @sl)
IF (NOT yesNO) 
  RETURN  

s := (s1 + s2) >> 16
sl := sl >> 16
sh := sh << 16
sl := sl + sh  
'Check free space
IF ((s > sl) OR (s1 == 0) OR (s2 == 0))
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN 

'Copy 1st file to merge file
File_Copy(pFN1_, pFN3_)
IF (NOT yesNO) 
  RETURN  

bsz := _CPYBLK_SIZE

yesNo := Sync
IF (NOT yesNO) 
  RETURN

'Append 2nd file to merge file
bdn~                                    'Bytes Done is zero at start
done := FALSE
REPEAT UNTIL done
  IF (bdn < s2)
    'Copy next chunk of data
    IF ((bdn + bsz) > s2)              'Last block
      ncb := s2 - bdn                   
    ELSE                               'Next full block
      ncb := bsz
        
    yesNo := File_Random_Access_Read(pFN2_, bdn, ncb, @strFileNames)
    IF (NOT yesNO) 
      RETURN
      
    yesNo := File_Append_Close(pFN3_, ncb, @strFileNames)
    IF (NOT yesNO)
      RETURN
      
  bdn := bdn + ncb
  IF (bdn => s2)                     
    done := TRUE
'-------------------------------------------------------------------------
}

DAT '-----------------Advanced CSV Textfile Operations--------------------


PUB Line_New
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ Line_New │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Empties CSV textline buffer 
'' Parameters: None                     
''    Returns: None                     
''+Reads/Uses: None                  
''    +Writes: strFileNames                       (VAR/BYTE array) 
''      Calls: None
'-------------------------------------------------------------------------
strFileNames[0] := 0
'-------------------------------------------------------------------------


PUB Line_Append_Int(iV) | sp_
'-------------------------------------------------------------------------
'----------------------------┌─────────────────┐--------------------------
'----------------------------│ Line_Append_Int │--------------------------
'----------------------------└─────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Appends an integer in ASCII to CSV textline 
'' Parameters: 32-bit integer           
''    Returns: None                     
''+Reads/Uses: None                  
''    +Writes: strFileNames                            
''      Calls: IntToStr
''             LineAppStr
'-------------------------------------------------------------------------
LineAppStr(IntToStr(iV))
'-------------------------------------------------------------------------


PUB Line_Append_Qval(qV) | sp_
'-------------------------------------------------------------------------
'---------------------------┌──────────────────┐--------------------------
'---------------------------│ Line_Append_Qval │--------------------------
'---------------------------└──────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Appends a Qs15_16 (Qvalue) number to CSV textline in buffer
'' Parameters: Qvalue                   
''    Returns: None                     
''+Reads/Uses: None                  
''    +Writes: strFileNames                            
''      Calls: QvalToStr
''             LineAppStr
'-------------------------------------------------------------------------
LineAppStr(QvalToStr(qV))
'-------------------------------------------------------------------------


PUB Line_WriteCRLF : yesNo | l
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ Line_WriteCRLF │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: - Appends CR, LF to CSV textline in buffer
''             - Writes CSV textline to open file
'' Parameters: None                     
''    Returns: TRUE if action successful, else FALSE 
''+Reads/Uses: UART#NL, UART#LF                   (OBJ/CON)                  
''    +Writes: strFileNames                       (VAR/BYTE array)                                    
''      Calls: File_Append
''       Note: Assumes an open file to write
'-------------------------------------------------------------------------
l := STRSIZE(@strFileNames)
strFileNames[l++] := UART#NL             'Carriege Return
strFileNames[l++] := UART#LF             'Line Feed
RETURN File_Append(l, @strFileNames)          
'-------------------------------------------------------------------------


PUB Line_Seek(pFN_,line):yesNo|done,ok,bckd,nrb,bsz,found,i,crlf,fp 
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ Line_Seek │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Seeks line in CSV textfile, puts file pointer to 1st byte
''             of line
'' Parameters: Pointer to filename
''             Line number (1st line is line #1, I am simple minded)
''    Returns: TRUE if action successful, else FALSE
''+Reads/Uses: strBadPar, strSomeErr, CMDFAILED   (DAT/strings)
''             _SECTOR_SIZE                       (CON)    
''    +Writes: filePointer, fileSize, lineNumb    (VAR/LONG)
''             ptrErrMess, ptrStatMess            (VAR/LONG)
''             lineNumb                           (VAR/LONG)                                                
''      Calls: File_Size
''             File_Open_For_Read
''             File_Seek
''             File_Random_Access_Read 
''       Note: File is left open for Read after this procedure
'-------------------------------------------------------------------------
lineNumb := 0

IF (line < 1)
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN FALSE

'Get size of file
IF (NOT File_Size(pFN_, @fileSize)) 
  RETURN FALSE

IF (fileSize < (2 * line))
  ptrErrMess := @CMDFAILED
  ptrStatMess := @strSomeErr
  RETURN FALSE  

IF (line == 1)
  IF (NOT File_Open_For_Read(pFN_)) 
    RETURN FALSE
  lineNumb := 1
  RETURN  
    
bckd~                                  'Bytes checked is zero at start
crlf~
done := FALSE
ok := FALSE
bsz := _SECTOR_SIZE
REPEAT UNTIL done
  IF (bckd < fileSize)
  'Read next chunk of data------------------------------------------------
    IF ((bckd + bsz) > fileSize)     'Last chunk
      nrb := fileSize - bckd                   
    ELSE                             'Next full chunk
      nrb := bsz

    IF (NOT File_Random_Access_Read(pFN_, bckd, nrb, @strFileNames))
      RETURN FALSE

    'Check bytes in buffer, look for CRLF
    REPEAT i FROM 1 TO (nrb - 1)
      IF (strFileNames[i-1]==13)AND(strFileNames[i]==10)
        crlf++ 
        IF (crlf == (line - 1))
          done := TRUE
          ok := TRUE
          filePntr := bckd + i + 1
          QUIT  
  bckd := bckd + nrb
  IF (bckd => fileSize)                     
    done := TRUE

IF ok
  yesNo := File_Open_For_Read(pFN_)
  IF (NOT yesNO) 
    RETURN
  yesNo := File_Seek(filePntr)
  lineNumb := line
  EOF := FALSE
ELSE
  ptrErrMess := @strEOF
  ptrStatMess := @strSomeErr
  RETURN FALSE   
'-------------------------------------------------------------------------


PUB Line_Read(pStr_) : yesNo | nrb, i, done, ok
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ Line_Read │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: - Reads line seeked previously
''             - Positions File Pointer to start of next line  
'' Parameters: Pointer to string                     
''    Returns: TRUE if action successful, else FALSE
'' Returns by: pStr_ ->String of textline       
''+Reads/Uses: filePntr, fileSize                 (VAR/LONG)
''             _SECTOR_SIZE                       (CON)
''             UART#NL                            (OBJ/CON)
''             strSomeErr                         (DAT/string)
''    +Writes: strFileNames                       (VAR/BYTE array)
''             ptrErrMess, ptrStatMess            (VAR/LONG)
''             EOF                                (VAR/BYTE)                
''      Calls: RDF
''       Note: - Assumes that file was seeked to that line previously
''             - Positions file pointer to 1st byte of next line for easy
''             repeat 
''-------------------------------------------------------------------------
IF (EOF)
  ptrErrMess:= @strEOF
  ptrStatMess := @strSomeErr 
  RETURN FALSE

IF (filePntr > fileSize)
  EOF := TRUE
  filePntr := fileSize
  RETURN
ELSE
  EOF := FALSE
  
IF ((fileSize - filePntr) < _SECTOR_SIZE) 'strFileNames will be the buffer
  nrb := fileSize - filePntr
ELSE
  nrb := _SECTOR_SIZE  

yesNo := RDF(nrb, @strFileNames)            
IF (NOT yesNO)                            
  RETURN

'Copy bytes from strFilenames to User's buffer until CR(=13) 
i~
done := FALSE
ok := FALSE
REPEAT UNTIL done
  BYTE[pStr_ + i] := strFileNames[i]
  IF (strFileNames[i++] == UART#NL)
    done := TRUE
    ok := TRUE
    BYTE[pStr_ + i]~                     'Terminate with zero for sure                   
  IF (i == _SECTOR_SIZE)
    done := TRUE
IF (NOT ok)
  ptrErrMess:= @strSomeErr
  ptrStatMess := @strSomeErr 
  RETURN FALSE
  
filePntr := filePntr + i + 1             'Seek next line
IF (filePntr => fileSize)
  EOF := TRUE
  filePntr := fileSize
ELSE
  EOF := FALSE

RETURN File_Seek(filePntr)
'--------------------------------------------------------------------------


PUB Value_Read(index, valType, pStr_) : val | done, found, i, j, count, l
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ Value_Read │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Reads value from CSV text line 
'' Parameters: Index of value (1 for 1st, I am simple minded)
''             Type of value  (LONG, Qvalue, 32-bit Float) 
''             Pointer to string of CSV textline                      
''    Returns: 32-bit value of the specified format or NaN if failed         
''+Reads/Uses: strSomeErr,strEOL                  (DAT/string)
''             floatNaN                           (DAT/LONG)
''             strBuffer                          (VAR/BYTE array)                 
''    +Writes: ptrErrMess, ptrStatMess            (VAR/LONG)                         
''      Calls: StrToInt
''             StrToQval
''      To Do: FloatToString
'-------------------------------------------------------------------------
l := STRSIZE(pStr_)
IF (l == 0)
  ptrErrMess := @strSomeErr
  RETURN floatNaN
  
done := FALSE
found := FALSE
i~
j~
count~
REPEAT UNTIL done
  'Search for comma, 0 or CRLF 
  strBuffer[j] := BYTE[pStr_ + i]
  i++
  j++
  IF (BYTE[pStr_ + i] == UART#NL)OR (BYTE[pStr_ + i] == 0)
    done := TRUE 
  IF (BYTE[pStr_ + i] == ",")OR (BYTE[pStr_ + i] == UART#NL) 
    count++
    IF (count == index)
      found := TRUE
      done := TRUE
      strBuffer[j]~
    i++
    j~

IF found
  CASE valType
    _LONG: RETURN StrToInt(@strBuffer)
    _QVAL: RETURN StrToQval(@strBuffer)
    '_FLOAT: RETURN StrToFloat(@strBuffer)
    OTHER:
      ptrErrMess := @strNotRec
      ptrStatMess := @strSomeErr
      RETURN floatNaN 
ELSE
  ptrErrMess := @strEOL
  ptrStatMess := @strSomeErr
  RETURN floatNaN
'-------------------------------------------------------------------------


DAT 'Conversions between numbers and strings------------------------------


PUB IntToStr(iV) : strP_ | d, nz, cp, c
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ IntToStr │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Converts an integer into string
'' Parameters: 32-bit signed integer                              
''     Result: Pointer to zero terminated ASCII string             
''+Reads/Uses: strBuffer                          (DAT/string)               
''    +Writes: None                                    
''      Calls: None
'-------------------------------------------------------------------------
'Set pointer to string buffer
strP_ := @strBuffer
cp~

'Check sign of Qvalue
IF (iV < 0)
  iV := ||iV
  BYTE[strP_][cp++] := "-"

d := 1_000_000_000                      '2^32 covered by 10 decimal dig
        
nz~
REPEAT 10
  IF (iV => d)
    c := (iV / d) + "0"
    BYTE[strP_][cp++] := c              
    iV //= d
    nz~~                                
  ELSEIF (nz OR (d == 1))
    c := (iV / d) + "0"                 
    BYTE[strP_][cp++] := c     
  d /= 10
BYTE[strP_][cp++] := 0
'-------------------------------------------------------------------------


PUB StrToInt(strP_) | c, s
'-------------------------------------------------------------------------
'-------------------------------┌──────────┐------------------------------
'-------------------------------│ StrToInt │------------------------------
'-------------------------------└──────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Converts a string to 32-bit integer                                 
'' Parameters: Pointer to string                                    
''    Results: Long value or NaN for invalid input                                                               
''+Reads/Uses: floatNaN                           (DAT/LONG)                                         
''    +Writes: None                                    
''      Calls: None
''       Note: No syntax check except for null strings. It assumes a
''             perfect string to describe signed decimal integers
'-------------------------------------------------------------------------
IF STRSIZE(strP_)           'Not a null string
  s~
  REPEAT WHILE c := BYTE[strP_++]
    CASE c
      "-": s := -1
      "+":
      "0".."9": RESULT := RESULT * 10 + c - $30
      OTHER: RETURN floatNaN
  IF s
    RESULT := -RESULT     
ELSE
  RESULT := floatNaN         'To signal invalid value
'-------------------------------------------------------------------------


PUB QvalToStr(qV) : strP_ | sg, ip, fp, d, nz, cp, c
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ QvalToStr │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Converts a Qs15_16 (Qvalue) number into ASCII string
'' Parameters: Number in Qs15_16 format                              
''     Result: Pointer to zero terminated ASCII string             
''+Reads/Uses: None                   
''    +Writes: strBuffer                          (DAT/string)                                 
''      Calls: None
'-------------------------------------------------------------------------
'Set pointer to string buffer
strP_ := @strBuffer
cp~

'Check sign of Qvalue
IF (qV < 0)
  qV := ||qV
  BYTE[strP_][cp++] := "-"

'Round up
qV := qV + 1  

'Separate Integer and Fractional parts
ip := qV >> 16
fp := (qV << 16) >> 16  

d := 100_000                   '2^16 approx. 64K, 5 decimal
                               'digit range
nz~
REPEAT 6
  IF (ip => d)
    c := (ip / d) + "0"
    BYTE[strP_][cp++] := c              
    ip //= d
    nz~~                                
  ELSEIF (nz OR (d == 1))
    c := (ip / d) + "0"                 
    BYTE[strP_][cp++] := c     
  d /= 10

IF (fp > 0)
  BYTE[strP_][cp++] := "."     'Add decimal point
  fp := (fp * 3125) >> 11      'Normalize fractional part

  d := 10_000                  '4 decimal digit range
 
  REPEAT 4
    IF (fp => d)
      c := (fp / d) + "0"
      BYTE[strP_][cp++] := c              
      fp //= d                                
    ELSE
      c := (fp / d) + "0"                 
      BYTE[strP_][cp++] := c     
    d /= 10

  'Remove trailing zeroes of decimal fraction
  REPEAT
    c := BYTE[strP_][--cp]
    IF (c <> "0")
      QUIT
       
  BYTE[strP_][++cp] := 0

  IF (BYTE[strP_][cp-1] == ".")
    BYTE[strP_][cp-1] := 0
ELSE
  BYTE[strP_][cp] := 0
'-------------------------------------------------------------------------


PUB StrToQval(strP_) : qV | sg, ip, d, fp, r
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ StrToQval │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Converts a String to Qs15_16 (Qvalue) format
'' Parameters: Pointer to string                             
''     Result: Number in Qs15_16 Fixed-point Qvalue format             
''+Reads/Uses: _MAX_STR_LEN, _32K                 (CON)                   
''    +Writes: None                                  
''      Calls: None
'-------------------------------------------------------------------------
sg~
ip~ 
d~ 
fp~ 
REPEAT _MAX_STR_LEN
  CASE BYTE[strP_]
    "-":
      sg := 1
    "+":
        
    ".",",":
      d := 1
    "0".."9":
      IF (d == 0)                          'Collect integer part
        ip := ip * 10 + (BYTE[strP_] - "0")
      ELSE                                 'Collect decimal part
        fp := fp * 10 + (BYTE[strP_] - "0")
        d++
    0:
      QUIT                                 'End of string
    OTHER:
      RETURN 
  ++strP_
  
'Process Integer part
IF (ip > _32K)
  RETURN FALSE

'Integer part ready  
ip := ip << 16

'Process Fractional part
r~  
IF (d > 1)
 fp := fp << (17 - d)
  REPEAT (d-1)
    r := fp // 5
    fp := fp / 5
    IF (r => 2)
      ++fp

'Get Qvalue      
qV := ip + fp

'Set sign
IF sg
  -qV
'-------------------------------------------------------------------------


DAT '------------------------Vinculum Utilities---------------------------


PRI Wait(timeOut_ms) : yesNo | t0, t1, maxTime 
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ Wait │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Waits for Low on Vinculum's RTS
' Parameters: Timeout im msec                                
'    Returns: TRUE if Vinculum ready within timeout, else FALSE
'+Reads/Uses: strNone, strTimeOut                 (DAT/string)
'             cTS                                 (VAR/BYTE)                    
'    +Writes: ptrErrMess                          (VAR/LONG)          
'      Calls: None
'-------------------------------------------------------------------------
ptrErrMess := @strNone                   'Clears error message
yesNo := TRUE
maxTime := timeOut_ms * (CLKFREQ / 1000)
t0 := CNT
REPEAT UNTIL (NOT(INA[cTS]))
  t1 := CNT
  IF ((t1 - t0) > maxTime)
    yesNo := FALSE
    ptrErrMess := @strTimeOut
'-------------------------------------------------------------------------


PRI Sync : yesNo | done, cntr, bE, bCR
'-------------------------------------------------------------------------
'-----------------------------------┌──────┐------------------------------
'-----------------------------------│ Sync │------------------------------
'-----------------------------------└──────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Synchronizes with the VNC1L-1A firmware
' Parameters: None                                 
'    Returns: TRUE if action successful, else FALSE               
'+Reads/Uses: UART#NL                             (OBJ/CON)
'             _MAX_SYNC_TRIALS                    (CON)   
'    +Writes: None                                    
'      Calls: PrepCmd
'             Parallax Serial Terminal------------>UART.RxFlush
'                                                  UART.Char
'                                                  UART.RxCount
'                                                  UART.CharIn
'-------------------------------------------------------------------------
IF (NOT PrepCmd)
  RETURN FALSE

yesNo := FALSE                       'Prepare loop
done := FALSE
cntr~                               
UART.RxFlush                         'Clean power on messages         
REPEAT UNTIL done
  cntr++                             'Increment counter
  UART.Char("E")                     'Send Echo command : "E" + CR 
  UART.Char(UART#NL)
  WAITCNT((CLKFREQ / 100) + CNT)
  IF (UART.RxCount > 1)              'Read response (should be E, CR or 
    bE  := UART.CharIn               'CR, E from the E,CR,E,CR,...sequence  
    bCR := UART.CharIn 
    IF (((bE=="E")AND(bCR==$0D))OR((bE==$0D)AND(bCR=="E")))
      yesNo := TRUE
      done := TRUE
  IF (cntr > (_MAX_SYNC_TRIALS / 4)) 'Quick check 
    done := TRUE

IF (NOT yesNo)                       'We do not give up so easily!
  done := FALSE
  cntr~                               
  UART.RxFlush                       'Clean previous garbage          
  REPEAT UNTIL done
    cntr++                           'Increment counter
    UART.Char("E")                   'Send Echo command : "E" + CR 
    UART.Char(UART#NL)
    WAITCNT((CLKFREQ / 50) + CNT)
    IF (UART.RxCount > 1)            'Read response (should be E, CR or 
      bE  := UART.CharIn             'CR, E from the E,CR,E,CR,...sequence  
      bCR := UART.CharIn 
      IF (((bE=="E")AND(bCR==$0D))OR((bE==$0D)AND(bCR=="E")))
        yesNo := TRUE
        done := TRUE
    IF (cntr > (_MAX_SYNC_TRIALS))   'Full check 
      done := TRUE
      
REPEAT UNTIL (UART.RxCount == 0)     'RxFlush sometimes chops off 1st byte
  UART.CharIn                        'of next transmission 
                          
IF (yesNo == FALSE)                  'Then we give up, It isn't good to be
  ptrErrMess := @strNoSync           'a goddamn fool about it
  ptrStatMess := @strSomeErr
  
OUTA[rTS] := 1                       'Suspend communication
'--------------------------------------------------------------------------


DAT '-------------Simple Structure DOS Style procedure Templates----------        


PRI CmdNL(ptrCmdStr_) : yesNo
'-------------------------------------------------------------------------
'----------------------------------┌───────┐------------------------------
'----------------------------------│ CmdNL │------------------------------
'----------------------------------└───────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Sends command string to Datalogger
' Parameters: Pointer to command string
'    Returns: TRUE if action successful, else FALSE                  
'+Reads/Uses: UART#NL                             (OBJ/CON)
'    +Writes: None                                    
'      Calls: PrepCmd
'             SendString
'             Parallax Serial Terminal------------>UART.Char
'             ReadVPrompt
'-------------------------------------------------------------------------
IF (NOT PrepCmd)
  RETURN FALSE
'---------------------------Send Cmd, NL command--------------------------
SendString(ptrCmdStr_)
UART.Char(UART#NL)
'-----------------------Command sent, read response-----------------------
RETURN ReadVPrompt
'-------------------------------------------------------------------------


PRI CmdNameNL(ptrCmdStr_, ptrNameStr_) : yesNo
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ CmdNameNL │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Sends command plus name string to Datalogger
' Parameters: Pointer to command string
'             Pointer to name string
'    Returns: TRUE if action successful, else FALSE                  
'+Reads/Uses: UART#NL                   
'    +Writes: None                                    
'      Calls: PrepCmd
'             SendString
'             Parallax Serial Terminal------------>UART.Char
'             ReadVPrompt
'-------------------------------------------------------------------------
IF (NOT PrepCmd)
  RETURN FALSE
'------------------------Send Cmd, Name, NL command-----------------------
SendString(ptrCmdStr_)
SendString(ptrNameStr_)
UART.Char(UART#NL)
'-----------------------Command sent, read response-----------------------
RETURN ReadVPrompt
'-------------------------------------------------------------------------


DAT '--------------------Vinculum Monitor procedures----------------------


PRI SBD(b1, b2) : yesNo
'-------------------------------------------------------------------------
'-----------------------------------┌─────┐-------------------------------
'-----------------------------------│ SBD │-------------------------------
'-----------------------------------└─────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Changes monitor baud rate
' Parameters: First 2 bytes of divisor table                                
'    Returns: TRUE if action successful, else FALSE                  
'+Reads/Uses: strSBD                              (DAT/string)
'             UART#NL                             (OBJ/CON)
'             rXP, tXP, baudR                     (VAR/LONG)
'             _DEF_MODE                           (DAT)
'    +Writes: None                                    
'      Calls: PrepCmd
'             SendString
'             ReadVPrompt
'             Parallax Serial Terminal------------>UART.Char
'                                                  UART.Stop
'                                                  UART.Start   
'-------------------------------------------------------------------------
IF (NOT PrepCmd)
  RETURN FALSE
'--------------------Send SBD, baud(3 bytes), NL command------------------
SendString(@strSBD)
UART.Char(b1)
UART.Char(b2)
UART.Char(0)
UART.Char(UART#NL)
'----------------Command sent, read response in old baud rate-------------
yesNo := ReadVPrompt
IF (NOT yesNo)
  RETURN
'Switch Propeller's UART to new baud rate
UART.Stop
UART.StartRxTx(rXP, tXP, _DEF_MODE, baudR)
WAITCNT((CLKFREQ / 20) + CNT)            'Wait 50 msec to settle VNC1L-1A
'Read response in new baud rate
RETURN ReadVPrompt
'-------------------------------------------------------------------------


PRI SUM : yesNo
'-------------------------------------------------------------------------
'-----------------------------------┌─────┐-------------------------------
'-----------------------------------│ SUM │-------------------------------
'-----------------------------------└─────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Suspends monitor 
' Parameters: None                                 
'    Returns: TRUE if action successful, else FALSE
'+Reads/Uses: strSUM                              (DAT/sring)
'             UART#NL                             (OBJ/CON)
'             rTS                                 (VAR/LONG)
'    +Writes: None                                    
'      Calls: PrepCmd
'             SendString
'             Parallax Serial Terminal------------>UART.Char
'                                                  UART.RxCount
'                                                  UART.CharIn
'       Note: After this the monitor is disabled. It is started again by
'             toggling the Ring Indicator (RI#) pin
'-------------------------------------------------------------------------
IF (NOT PrepCmd)
  RETURN FALSE
'---------------------------Send SUM, NL command--------------------------  
SendString(@strSUM)
UART.Char(UART#NL)
'-------------------------------Command sent------------------------------
WAITCNT((CLKFREQ / 5) + CNT)             'Allow time to settle

REPEAT UNTIL (UART.RxCount == 0)         'Clean up
  UART.CharIn                        

OUTA[rTS] := 1                           'Suspend communication
'-------------------------------------------------------------------------


PRI IDDE : yesNo | c, cntr, sc, done
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ IDDE │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Returns information about the disk 
' Parameters: None                                 
'    Returns: TRUE if action successful, else FALSE                 
'+Reads/Uses: strIDD                              (DAT/string)
'             rTS                                 (VAR/LONG)
'    +Writes: strIDDE                             (VAR/BYTE array)                                    
'      Calls: PrepCmd
'             SendString
'             ReadIDDEStr
'             Parallax Serial Terminal------------>UART.Char  
'-------------------------------------------------------------------------
yesNo := PrepCmd
IF (NOT yesNo)
  RETURN
'--------------------------Send IDDE, NL command--------------------------  
SendString(@strIDD)
UART.Char(UART#NL)
'------------------------Command sent, read response----------------------
ReadIDDEStr
OUTA[rTS] := 1                           'Suspend communication
'-------------------------------------------------------------------------


DAT '----------------Special Structure DOS Style procedures---------------


PRI FSE(hiL_, loL_) : yesNo | b
'-------------------------------------------------------------------------
'-----------------------------------┌─────┐-------------------------------
'-----------------------------------│ FSE │-------------------------------
'-----------------------------------└─────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Returns free space available on disk
' Parameters: Pointer to 2 LONGs that holds result                               
'    Returns: TRUE if action successful, else FALSE
' Returns by: hiL_ -> Upper 2 bytes of result
'             loL_ -> Lower 4 bytes of result                    
'+Reads/Uses: strFSE                              (DAT/string)
'             UART#NL                             (OBJ/CON)                   
'    +Writes: None                                    
'      Calls: PrepCmd
'             SendString
'             ReadVPrompt
'             Parallax Serial terminal------------>UART.Char
'                                                  UART.CharIn
'       Note: All output in binary or ASCII from the monitor is LSB first
'-------------------------------------------------------------------------
IF (NOT PrepCmd)
  RETURN FALSE
  
'----------------------------Send FSE, NL command-------------------------  
SendString(@strFSE)
UART.Char(UART#NL)
'------------------------Command sent, read response----------------------
'Read in 6 bytes  LSB first
'Lower 32-bit
b := UART.CharIn 
LONG[loL_] := b
b := UART.CharIn
LONG[loL_] := LONG[loL_] + (b << 8)
b := UART.CharIn 
LONG[loL_] := LONG[loL_] + (b << 16)
b := UART.CharIn
LONG[loL_] := LONG[loL_] + (b << 24)
'Upper 16-bit
b := UART.CharIn                   
LONG[hiL_] := b
b := UART.CharIn
LONG[hiL_] := LONG[hiL_] + (b << 8)
b := UART.CharIn                         'Read last NL

RETURN ReadVPrompt 
'-------------------------------------------------------------------------


PRI DIR(pFN_, pFS_) : yesNo | fnl, done, b, cntr, rc, i, fn
'-------------------------------------------------------------------------
'-----------------------------------┌─────┐-------------------------------
'-----------------------------------│ DIR │-------------------------------
'-----------------------------------└─────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: -Lists files in current directory with no filename passed
'             -Returns filesize with filename passed 
' Parameters: Pointer to filename
'             Pointer to LONG to store filesize                                 
'    Returns: TRUE if action successful, else FALSE                 
'+Reads/Uses: strDIR, strTooMany                  (DAT/string)
'             rTS                                 (VAR/LONG)
'             UART#NL                             (OBJ/CON)                  
'    +Writes: strBuffer                           (VAR/BYTE array)
'             ptrErrMess                          (VAR/LONG)                                    
'      Calls: PrepCmd
'             SendString
'             Parallax Serial terminal------------>UART.Char
'                                                  UART.StrIn
'                                                  UART.CharIn
'             ReadVPrompt
'             ReadFDNames
'-------------------------------------------------------------------------
IF (NOT PrepCmd)
  RETURN FALSE

fnl := STRSIZE(pFN_)
IF (fnl > 0)
  '------------------------Send DIR, Name, NL command--------------------
  SendString(@strDIR)
  UART.Char($20)
  SendString(pFN_)
  UART.Char(UART#NL)
  '------------------------Command sent, read response-------------------
  UART.StrIn(@strBuffer)                 'Read in response until CR
   IF(NOT(STRSIZE(@strBuffer) == 0))     'Prompt received
     UART.StrIn(@strBuffer)              'Read in response until CR 
  IF (STRSIZE(@strBuffer) == 0)          '1st NL received, now comes data
    'Check for echoed Filename
    done := FALSE
    cntr~
    REPEAT UNTIL done
      b := UART.CharIn
      strBuffer[cntr++] := b
      IF (cntr == fnl)
        strBuffer[cntr] := 0             'Terminate received string with 0   
        fn := STRCOMP(@strBuffer, pFN_)
        IF (fn)                          'Filename echoed back
          b := UART.CharIn               'Read in space
          b := UART.CharIn               'Read in File Size  
          LONG[pFS_] := b
          b := UART.CharIn
          LONG[pFS_] := LONG[pFS_] + (b << 8)
          b := UART.CharIn
          LONG[pFS_] := LONG[pFS_] + (b << 16)
          b := UART.CharIn
          LONG[pFS_] := LONG[pFS_] + (b << 24)
          b := UART.CharIn                     'Read last NL
          'Read prompt
          yesNo := ReadVPrompt
          RETURN
      IF (b == $0D)
        done := TRUE
        strBuffer[--cntr] := 0      
    'Evaluate response
    yesNo := FALSE
    rc := EvalString
ELSE
  '--------------------------Send DIR, NL command-------------------------
  SendString(@strDIR)
  UART.Char(UART#NL)
  '-----------------------Command sent, read response---------------------
  yesNo := ReadFDNames                   'Read file and directory names
  IF (NOT yesNo)
    ptrErrMess := @strTooMany            'Too many items in directory

OUTA[rTS] := 1                           'Suspend communication
'-------------------------------------------------------------------------


PRI SEK(fPos) : yesNo 
'-------------------------------------------------------------------------
'----------------------------------┌─────┐--------------------------------
'----------------------------------│ SEK │--------------------------------
'----------------------------------└─────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: Seeks to an absolute offset position in an open file.
' Parameters: File pointer                                 
'    Returns: TRUE if action successful, else FALSE               
'+Reads/Uses: strSEK                              (DAT/string)
'             UART#NL                             (OBJ/CON)                   
'    +Writes: None                                    
'      Calls: PrepCmd
'             SendString
'             Parallax Serial Terminal------------>UART.Char
'             ReadVPrompt   
'       Note: All numeric input to the monitor is LSB first 
'-------------------------------------------------------------------------
IF (NOT PrepCmd)
  RETURN FALSE

'-------------------Send SEK FilePos(4 bytes), NL command-----------------
SendString(@strSEK)
UART.Char(fPos.BYTE[3])
UART.Char(fPos.BYTE[2])
UART.Char(fPos.BYTE[1])
UART.Char(fPos.BYTE[0])
UART.Char(UART#NL)
'------------------------Command sent, read response----------------------
RETURN ReadVPrompt   
'-------------------------------------------------------------------------


PRI RD(pFN_, fSize, pB_) : yesNo
'-------------------------------------------------------------------------
'-----------------------------------┌────┐--------------------------------
'-----------------------------------│ RD │--------------------------------
'-----------------------------------└────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: Reads the entire contents of a file
' Parameters: Pointer to filename
'             File size
'             Pointer to buffer                                  
'    Returns: TRUE if action successful, else FALSE                 
'+Reads/Uses: strRD                               (DAT/string)
'             UART#NL                             (OBJ/CON)               
'    +Writes: None                                    
'      Calls: PrepCmd
'             SendString
'             Parallax Serial Terminal------------>UART.Char
'             ReadVPrompt
'-------------------------------------------------------------------------
IF (NOT PrepCmd)
  RETURN FALSE

'-----------------------Send RD, FileName, NL command---------------------
SendString(@strRD)
SendString(pFN_)
UART.Char(UART#NL)
'------------------------Command sent, read response----------------------
REPEAT fSize                             'Read stream of fSize bytes
  BYTE[pB_++] := UART.CharIn
RETURN ReadVPrompt   
'-------------------------------------------------------------------------


PRI RDF(dSize, pB_) : yesNo 
'-------------------------------------------------------------------------
'----------------------------------┌─────┐--------------------------------
'----------------------------------│ RDF │--------------------------------
'----------------------------------└─────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: Reads from an open file
' Parameters: Number of bytes
'             Pointer to buffer                                
'    Returns: TRUE if action successful, else FALSE                    
'+Reads/Uses: strRDF                              (DAT/string)
'             UART#NL                             (OBJ/CON)                     
'    +Writes: None                                    
'      Calls: PrepCmd
'             SendString
'             Parallax Serial Terminal------------>UART.Char
'             ReadVPrompt   
'       Note: All numeric input to the monitor is LSB first
'-------------------------------------------------------------------------
IF (NOT PrepCmd)
  RETURN FALSE

'-------------------Send RDF, Datasize(4 bytes), NL command---------------
SendString(@strRDF)
UART.Char(dSize.BYTE[3])
UART.Char(dSize.BYTE[2])
UART.Char(dSize.BYTE[1])
UART.Char(dSize.BYTE[0])
UART.Char(UART#NL)
'------------------------Command sent, read response----------------------
REPEAT dSize                             'Read stream of dSize bytes
  BYTE[pB_++] := UART.CharIn
RETURN ReadVPrompt   
'-------------------------------------------------------------------------


PRI WRF(dSize, pB_) : yesNo | stopped
'-------------------------------------------------------------------------
'----------------------------------┌─────┐--------------------------------
'----------------------------------│ WRF │--------------------------------
'----------------------------------└─────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: Writes data to an open file
' Parameters: Number of bytes
'             Pointer to buffer                                
'    Returns: TRUE if action successful, else FALSE                 
'+Reads/Uses: strWRF                              (DAT/string)
'             UART#NL                             (OBJ/CON)                  
'    +Writes: None
'      Calls: PrepCmd
'             SendString
'             Parallax Serial Terminal------------>UART.Char
'             ReadVPrompt                                      
'       Note: - All numeric input to the monitor is LSB first
'      To Do: - Hardware handshaking with UART's COG 
'-------------------------------------------------------------------------
IF (NOT PrepCmd)
  RETURN FALSE

stopped := FALSE
'------------------Send WRF, Datasize(4 bytes), NL command---------------
SendString(@strWRF)
UART.Char(dSize.BYTE[3])
UART.Char(dSize.BYTE[2])
UART.Char(dSize.BYTE[1])
UART.Char(dSize.BYTE[0])
UART.Char(UART#NL)
'---------------------Send Datablock (dSize bytes), NL--------------------
REPEAT dSize
  IF (INA[cTS])
    stopped := TRUE
    REPEAT UNTIL (NOT(INA[cTS]))   
  UART.Char(BYTE[pB_++])
    
IF stopped                               'Try to recover
  ptrErrMess := @strBlocked
  REPEAT 36
    UART.Char(UART#NL)
  WAITCNT((CLKFREQ / 10) + CNT)  
  UART.RxFlush
  RETURN FALSE
  
UART.Char(UART#NL)
'------------------------Command sent, read response----------------------          
RETURN ReadVPrompt   
'-------------------------------------------------------------------------

{
PRI REN(pFN1_, pFN2_) : yesNo
'-------------------------------------------------------------------------
'----------------------------------┌─────┐--------------------------------
'----------------------------------│ REN │--------------------------------
'----------------------------------└─────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: Renames a file
' Parameters: Filename
'             New filename                                 
'    Returns: TRUE if action successful, else FALSE                   
'+Reads/Uses: strREN                              (DAT/string)
'             UART#NL                             (OBJ/CON)                   
'    +Writes: None                                    
'      Calls: SendString
'             Parallax Serial terminal------------>UART.Char
'             ReadVPrompt  
'       Note: The filenames may refer to subdirectories as well as files.
'-------------------------------------------------------------------------
IF (NOT PrepCmd)
  RETURN FALSE

'----------------Send REN, FileName1, FileName2, NL command---------------
SendString(@strREN)
SendString(pFN1_)
UART.Char(32)                            '32 = " "
SendString(pFN2_)
UART.Char(UART#NL)
'------------------------Command sent, read response----------------------
RETURN ReadVPrompt 
'-------------------------------------------------------------------------
}

DAT '--------------------------Sector Procedures--------------------------

{
PRI SD(sNo) : yesNo | ptr_
'-------------------------------------------------------------------------
'-----------------------------------┌────┐--------------------------------
'-----------------------------------│ SD │--------------------------------
'-----------------------------------└────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: Dumps sector data into strFileNames buffer
' Parameters: Sector number                        
'    Returns: TRUE if action successful, else FALSE
'+Reads/Uses: strSD, strFileNames                 (DAT/string)
'             UART#NL                             (OBJ/CON)
'             _SECTOR_SIZE                        (CON)            
'    +Writes: strFileNames                        (VAR/BYTE array)           
'      Calls: PrepCmd
'             SendString
'             ReadVPrompt
'             Parallax Serial Terminal------------>UART.Char
'       Note: Overwrites the string buffer of file/dir names. After this 
'             you have to make a DIR to fill back name data, if needed
'-------------------------------------------------------------------------
IF (NOT PrepCmd)
  RETURN FALSE

ptr_ := @strFileNames  
'-----------------Send SD, sector No(4 bytes), NL command-----------------
SendString(@strSD)
UART.Char(sNo.BYTE[3])
UART.Char(sNo.BYTE[2])
UART.Char(sNo.BYTE[1])
UART.Char(sNo.BYTE[0])
UART.Char(UART#NL)
'------------------------Command sent, read response----------------------
REPEAT _SECTOR_SIZE                          'Read stream of 512 bytes
  BYTE[ptr_++] := UART.CharIn   
RETURN ReadVPrompt
'-------------------------------------------------------------------------


PRI SW(sNo, pB_) : yesNo       
'-------------------------------------------------------------------------
'-----------------------------------┌────┐--------------------------------
'-----------------------------------│ SW │--------------------------------
'-----------------------------------└────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: Writes 512 bytes raw binary to sector of drive
' Parameters: Sector number
'             Pointer to data buffer 
'    Returns: TRUE if action successful, else FALSE
'+Reads/Uses: strSW                               (DAT/string)
'             UART#NL                             (OBJ/CON)
'             _SECTOR_SIZE                        (CON) 
'    +Writes: none                                   
'      Calls: PrepCmd
'             SendString
'             ReadVPrompt
'             Parallax Serial Terminal------------>UART.Char  
'       Note: Use with care as disk and file system corruption can occur
'-------------------------------------------------------------------------
IF (NOT PrepCmd)
  RETURN FALSE

'------------------Send SW, sector No(4 bytes), NL command----------------
SendString(@strSW)
UART.Char(sNo.BYTE[3])
UART.Char(sNo.BYTE[2])
UART.Char(sNo.BYTE[1])
UART.Char(sNo.BYTE[0])
UART.Char(UART#NL)
'--------------------------Command sent, send data------------------------
REPEAT _SECTOR_SIZE                      'Write 512 bytes
  UART.Char(BYTE[pB_++]) 
'--------------------Command + data sent, read response-------------------
RETURN ReadVPrompt
'-------------------------------------------------------------------------
}

DAT '-------------------------Internal Utilities--------------------------


PRI PrepCmd : yesNo
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ PrepCmd │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: - Clears error message
'             - Activates Vinculum Firmware Monitor I/O
'             - Waits for Ready Monitor
' Parameters: None                                 
'    Returns: TRUE if Vinculum is ready within specified timeout
'+Reads/Uses: strNone, strTimeOut (strings)
'             _TIMEOUT_MS (CON)            
'    +Writes: ptrErrMess                                    
'      Calls: Wait
'       Note: None
'-------------------------------------------------------------------------
ptrErrMess := @strNone
OUTA[rTS]~                           'Request communication
yesNo := Wait(_TIMEOUT_MS)           'Wait for Datalogger ready
IF (NOT yesNo)         
  OUTA[rTS]~~ 
  ptrErrMess := @strTimeOut
'-------------------------------------------------------------------------


PRI UCASE(pStr_) | l, p, c
'-------------------------------------------------------------------------
'---------------------------------┌───────┐-------------------------------
'---------------------------------│ UCASE │-------------------------------
'---------------------------------└───────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Converts string in-place into uppercase
' Parameters: Pointer to string                                
'    Returns: Pointer to string (same)         
'+Reads/Uses: None                   
'    +Writes: None                                    
'      Calls: None
'-------------------------------------------------------------------------
l := STRSIZE(pStr_)
IF (l > 0)
  p := pStr_
  REPEAT l               
    IF (BYTE[p] => "a") AND (BYTE[p] =< "z")            
      BYTE[p] -= 32                                    '"A" = "a" - 32
    p++
RESULT := pStr_
'-------------------------------------------------------------------------


PRI SendString(pStr_)
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ SendString │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Sends a string to Vinculum
' Parameters: Pointer to string                                 
'    Returns: None                    
'+Reads/Uses: None                   
'    +Writes: None                                    
'      Calls: Parallax Serial Terminal------------>UART.Char
'       Note: Take care to terminate self made strings with zero
'-------------------------------------------------------------------------
REPEAT WHILE (BYTE[pStr_] <> 0)   'Send bytes of the param string
  UART.Char(BYTE[pStr_++])
'-------------------------------------------------------------------------


PRI ReadFDNames : yesNo | l, ds, ds0, dn, full
'-------------------------------------------------------------------------
'-----------------------------┌─────────────┐-----------------------------
'-----------------------------│ ReadFDNames │-----------------------------
'-----------------------------└─────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: - Reads file and directory names from byte stream
'             - Identifies directory names
'             - Appends names to appropriate lists
' Parameters: None                                 
'    Returns: TRUE if action successful, else FALSE       
'+Reads/Uses: strBuffer                          (VAR/BYTE array)
'             TERMDIR                            (DAT/string)
'             _MAXDIRS, _MAXFILES                (CON)
'    +Writes: nOfDirs                            (VAR/LONG)
'             nOfFiles                           (VAR/LONG)
'             ptrDirNames                        (VAR/LONG array)
'             ptrFileNames                       (VAR/LONG array)
'             strDirNames                        (VAR/BYTES array)
'             strFileNames                       (VAR/BYTES array) 
'      Calls: Propeller Serial Terminal---------->UART.StrIn
'             EvalString
'       Note: - Local ds0 shoud follow local ds (must keep order)
'             - Quits on last <prompt> 
'-------------------------------------------------------------------------
ds0 := 0                                 'Terminate 4-byte string in ds
                                
UART.StrIn(@strBuffer)                   'Read in 1st response until CR

yesNo := TRUE                            'Prepare loop
full := FALSE
REPEAT 
  UART.StrIn(@strBuffer)                 'Read in response until CR
  IF (EvalString == 0)                   'Quit on <prompt> 
    QUIT
  IF (full)
    yesNo := FALSE                       'DIR will set ErrMess
  ELSE                       
    l := STRSIZE(@strBuffer)             'Else string is NOT a prompt   
    IF (l > 0)                           'Name is not empty
      BYTEMOVE(@ds,@strBuffer+l-4,4)
      dn := STRCOMP(@ds,@TERMDIR)        'Check for a directory name  
      IF (dn == TRUE)                    'Append to list of directories
        l -= 4
        BYTEMOVE(ptrDirNames[nOfDirs++],@strBuffer,l)
        BYTE[ptrDirNames[nOfDirs-1]][l]:=0
        ptrDirNames[nOfDirs]:=ptrDirNames[nOfDirs-1]+l+1
      ELSE                               'Append to list of files  
        BYTEMOVE(ptrFileNames[nOfFiles++],@strBuffer,l)
        BYTE[ptrFileNames[nOfFiles-1]][l]:=0
        ptrFileNames[nOfFiles]:=ptrFileNames[nOfFiles-1]+l+1
      IF ((nOfDirs==(_MAXDIRS-1))OR(nOfFiles==(_MAXFILES-1)))
        full := TRUE       
'------------------------------------------------------------------------- 


PRI ReadIDDEStr | sz
'-------------------------------------------------------------------------
'-----------------------------┌─────────────┐-----------------------------
'-----------------------------│ ReadIDDEStr │-----------------------------
'-----------------------------└─────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Reads Identify Disk Drive Extended (IDDE) strings
' Parameters: None                                 
'    Returns: TRUE if action successful, else FALSE       
'+Reads/Uses: strBuffer                           (VAR/BYTE array)
'    +Writes: nOfIDDEs                            (VAR/LONG array)
'             ptrDirNames array                   (VAR/LONG array)
'             strDirNames                         (VAR/BYTE array) 
'      Calls: Propeller Serial Terminal----------->UART.StrIn
'             EvalString
'       Note: Quits on last <prompt>
'-------------------------------------------------------------------------
UART.StrIn(@strBuffer)                   'Read in 1st response until CR

REPEAT 
  UART.StrIn(@strBuffer)                 'Read in response until CR
  IF (EvalString == 0)                   'Quit on <prompt> 
    QUIT                                    
  sz := STRSIZE(@strBuffer)                  
  BYTEMOVE(ptrIDDEs[nOfIDDEs++], @strBuffer, sz) 'Append string to buffer
  BYTE[ptrIDDEs[nOfIDDEs - 1]][sz] := 0
  ptrIDDEs[nOfIDDEs] := ptrIDDEs[nOfIDDEs - 1] + sz + 1  'Update pointers
'-------------------------------------------------------------------------  


PRI EvalString : code | eq
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ EvalString │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Evaluates Vinculum's response
' Parameters: None                                 
'    Returns: Response Code           
'+Reads/Uses: strBuffer                         (
'             Response strings from DAT section (like PROMPT)
'             Response codes from CON section   (like _NONE)
'    +Writes: ptrErrMess                              
'      Calls: None
'-------------------------------------------------------------------------
'Check for prompt
CASE cmd_Set                     
  _SHORT: eq := STRCOMP(@strBuffer, @SHORTPROMPT)
  _EXTEN: eq := STRCOMP(@strBuffer,@PROMPT)    
IF (eq)
  code := _NONE
  ptrErrMess := @strNone
  ptrStatMess := @strSomeErr 
  RETURN
  
'Check for "No Disk"
CASE cmd_Set                     
  _SHORT:eq := STRCOMP(@strBuffer, @SHORTNODISK)
  _EXTEN:eq := STRCOMP(@strBuffer, @NODISK)
IF (eq)
  code := _NODISK
  ptrErrMess :=@NODISK
  ptrStatMess := @strSomeErr
  RETURN

'Check for "Bad Command" 
CASE cmd_Set                     
  _SHORT:eq := STRCOMP(@strBuffer, @SHORTBADCOM)
  _EXTEN:eq := STRCOMP(@strBuffer, @BADCOMMAND)
IF (eq)
  code := _BADCOMMAND
  ptrErrMess := @BADCOMMAND
  ptrStatMess := @strSomeErr  
  RETURN

'Check for "Command Failed"
CASE cmd_Set                     
  _SHORT:eq := STRCOMP(@strBuffer, @SHORTCMDF)
  _EXTEN:eq := STRCOMP(@strBuffer, @CMDFAILED)
IF (eq)
  code := _CMDFAILED
  ptrErrMess := @CMDFAILED
  ptrStatMess := @strSomeErr
  RETURN

'Check for "Dir Not Empty"
CASE cmd_Set                     
  _SHORT:eq := STRCOMP(@strBuffer, @SHORTDIRNE)
  _EXTEN:eq := STRCOMP(@strBuffer, @DIRNOTEMPTY)
IF (eq)
  code := _DIRNOTEMPTY
  ptrErrMess := @DIRNOTEMPTY
  ptrStatMess := @strSomeErr
  RETURN

'Check for "File Open"
CASE cmd_Set                     
  _SHORT:eq := STRCOMP(@strBuffer, @SHORTFILEO)
  _EXTEN:eq := STRCOMP(@strBuffer, @FILEOPEN)
IF (eq)
  code := _FILEOPEN
  ptrErrMess := @FILEOPEN
  ptrStatMess := @strSomeErr
  RETURN     

'Response is not recognised. This can be OK (e.g. filename is received.)
code := -1
ptrErrMess := @strNotRec
'-------------------------------------------------------------------------


PRI ReadVPrompt : yesNo | respCode
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ ReadVPrompt │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: - Reads response from Vinculum monitor
'             - Checks for <prompt> ('D:\>' or '>')
'             - Suspends communication
' Parameters: None                                 
'    Returns: TRUE if <prompt> received, else FALSE
'+Reads/Uses: strBuffer                           (DAT/string)
'             rTS                                 (VAR/BYTE)
'    +Writes: None                                    
'      Calls: EvalString
'-------------------------------------------------------------------------
UART.StrIn(@strBuffer)             'Read in response until CR
respCode := EvalString             'Evaluate it
CASE respCode                      'Check for <prompt>
  _NONE:yesNo := TRUE
  OTHER:yesNo := FALSE
OUTA[rTS]~                         'Suspend communication       
'-------------------------------------------------------------------------

{
PRI SplitFile(pFN_, bP) : yesNo | fsz, bsz, done, bdn, ncb, fsz1, fsz2
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ SplitFile │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Splits file in current directory
' Parameters: Pointer to filename
'             Byte position of split                                  
'    Returns: TRUE if action successful, else FALSE                    
'+Reads/Uses: strSP1, strSP2, strBadPar, strSomeErr   (DAT/strings)
'             _CPYBLK_SIZE                            (CON)                  
'    +Writes: ptrErrMess, ptrStatMess                 (VAR/LONG)                                    
'      Calls: File_Delete
'             File_Size
'             File_Random_Access_Read
'             File_Append_Close 
'       Note: Creates files "SPLIT1.TMP", "SPLIT2.TMP" 
'-------------------------------------------------------------------------
'Delete temporary files
File_Delete(@strSP1)
File_Delete(@strSP2)

'Get file size
yesNo := File_Size(pFN_, @fsz)
IF (NOT yesNO)
  RETURN

'Check bP
IF ((bP => fsz) OR (bP < 1))
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN   

'Write 1st part
bsz := _CPYBLK_SIZE
    
bdn~                                   'Bytes Done is zero
fsz1 := bP
done := FALSE
REPEAT UNTIL done
  IF (bdn < fsz1)
    'Copy next chunk of data----------------------------------------------
    IF ((bdn + bsz) > fsz1)            'Last block
      ncb := fsz1 - bdn                   
    ELSE                               'Next full block
      ncb := bsz 

    yesNo := File_Random_Access_Read(pFN_, bdn, ncb, @strFileNames)
    IF (NOT yesNO) 
      RETURN

    yesNo := File_Append_Close(@strSP1, ncb, @strFileNames)
    IF (NOT yesNO) 
      RETURN

  bdn := bdn + ncb
  IF (bdn => fsz1)                     
    done := TRUE

'Write 2nd part
bdn~                                   'Bytes Done is zero
fsz2 := fsz - bP
done := FALSE
REPEAT UNTIL done
  IF (bdn < fsz2)
    'Copy next chunk of data----------------------------------------------
    IF ((bdn + bsz) > fsz2)            'Last block
      ncb := fsz2 - bdn                   
    ELSE                               'Next full block
      ncb := bsz 

    yesNo := File_Random_Access_Read(pFN_, bP + bdn, ncb, @strFileNames)
    IF (NOT yesNO)
      RETURN

    yesNo := File_Append_Close(@strSP2, ncb, @strFileNames)
    IF (NOT yesNO)
      RETURN

  bdn := bdn + ncb
  IF (bdn => fsz2)                     
    done := TRUE
'-------------------------------------------------------------------------
}

PRI LineAppStr(pStr_) : yesNo | l1, l2
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ LineAppendStr │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Appends a string to CSV textline buffer (strFileNames) 
' Parameters: Pointer to string                    
'    Returns: TRUE if action successful, else FALSE         
'+Reads/Uses: strBadPar, strSomeErr               (DAT/string)
'    +Writes: strFileNames                        (VAR/BYTE array)        
'      Calls: None
'-------------------------------------------------------------------------
l1 := STRSIZE(@strFileNames)       
l2 := STRSIZE(pStr_)
IF (l2 == 0)
  RETURN TRUE
IF ((l1 + l2 + 1)> _FNBUF_SIZE)
  ptrErrMess := @strBadPar
  ptrStatMess := @strSomeErr
  RETURN FALSE
IF (l1 > 0)  
  strFileNames[l1] := ","
  BYTEMOVE(@strFileNames + l1 + 1, pStr_, l2 + 1)
  strFileNames[l1 + l2 + 1] := 0
ELSE
  BYTEMOVE(@strFileNames, pStr_, l2 + 1)
  strFileNames[l2 + 1] := 0  
RETURN TRUE 
'-------------------------------------------------------------------------


DAT '-----------------------------DAT section-----------------------------


'Invalid result code
floatNaN       LONG $7FFF_FFFF     'Not a Number code for invalid numeric


'-------------------------------Misc Strings------------------------------
'Empty string 
strNull        BYTE 0

'Command strings
strSBD         BYTE "SBD ", 0
strSUM         BYTE "SUM", 0
strIDD         BYTE "IDDE", 0
strFSE         BYTE "FSE", 0
strSUD         BYTE "SUD", 0
strWKD         BYTE "WKD", 0
strDIR         BYTE "DIR", 0
strCD          BYTE "CD ", 0
strMKD         BYTE "MKD ", 0 
strDLD         BYTE "DLD ", 0
strOPR         BYTE "OPR ", 0
strSEK         BYTE "SEK ", 0
strRD          BYTE "RD ", 0
strRDF         BYTE "RDF ", 0
strOPW         BYTE "OPW ", 0
strWRF         BYTE "WRF ", 0 
strCLF         BYTE "CLF ", 0
strREN         BYTE "REN ", 0
strDLF         BYTE "DLF ", 0
strSD          BYTE "SD ", 0
strSW          BYTE "SW ", 0

'Error messages
ptrErrMess     LONG @strNone
strNone        BYTE "None", 0
strTooSmall    BYTE "Buffer too small", 0
strTooMany     BYTE "Too Many Items", 0
strNoCOG       BYTE "No COG available", 0
strBadPar      BYTE "Invalid Parameter", 0
strTimeOut     BYTE "Timeout", 0
strNoSync      BYTE "No Sync", 0
strNotRec      BYTE "Not Recognised Response", 0
strReadStr     BYTE "in Read_String", 0
strBlocked     BYTE "Blocked Write", 0
strEOF         BYTE "EOF Reached", 0
strEOL         BYTE "EOL Reached", 0

'Status messages
ptrStatMess    LONG @strReady
strReady       BYTE "Ready", 0                                              
strSomeErr     BYTE "Some Error", 0
strDiskOn      BYTE "Disk Online", 0

'String responses from Memory Stick Datalogger
PROMPT         BYTE "D:\>", 0
SHORTPROMPT    BYTE ">", 0
TERMDIR        BYTE " DIR", 0
NODISK         BYTE "No Disk", 0
SHORTNODISK    BYTE "ND", 0
BADCOMMAND     BYTE "Bad Command", 0
SHORTBADCOM    BYTE "BC", 0
CMDFAILED      BYTE "Command Failed", 0
SHORTCMDF      BYTE "CF", 0
DIRNOTEMPTY    BYTE "Dir Not Empty", 0
SHORTDIRNE     BYTE "NE", 0
FILEOPEN       BYTE "File Open", 0
SHORTFILEO     BYTE "FO", 0
DISKFULL       BYTE "Disk Full", 0
SHORTDFULL     BYTE "DF", 0
INVALID        BYTE "Invalid", 0
SHORTINV       BYTE "FI", 0
FNINVALID      BYTE "Filename Invalid", 0
SHORTFNINV     BYTE "FN", 0

'Tmp filenames
strSP1         BYTE "SPLIT1.TMP", 0
strSP2         BYTE "SPLIT2.TMP", 0
strFR1         BYTE "FRAW1.TMP", 0
strFR2         BYTE "FRAW2.TMP", 0
strFR3         BYTE "FRAW3.TMP", 0
strFR4         BYTE "FRAW4.TMP", 0


DAT '-----------------------------MIT License-----------------------------


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