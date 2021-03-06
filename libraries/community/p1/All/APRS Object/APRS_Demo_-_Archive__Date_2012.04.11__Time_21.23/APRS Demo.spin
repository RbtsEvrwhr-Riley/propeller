CON

  'Usual clock stuff
  _clkmode      = xtal1 + pll16x
  _xinfreq      = 5_000_000
  
  'useful definitions 
  out   =       1  
  in    =       0
  on    =       1
  off   =       0

  'AX25 Modem Definitions
  XMTPIN =      27
  PTTPIN =      25


  'LED PORTS
  LED_MAIN =    3
  LED_AVG  =    16

  'Mode Switch pin - used for vehicle/pedestrian changes
  '1 = walking, 0 = driving
  Mode_Switch = 11

  'Packet send beep
  Beep_Port =   9
  
  'GPS Config
  GPS_RX   =    23    'NMEA data sent to this port from GPS
  GPS_Baud =    9_600 'Default for most GPS modules

  'Config for automatic AZ messages - SOTA facility

  Target_Altitude = 559 'Height of summit to be ascended in metres
  AZ_Trigger = Target_Altitude - 15 'sets altitude for "in AZ" msg send

  'Debug modes - used for testing things
  Debug_Mode = false    'changes to shorter timings etc
  Suppress_SOTA = false 'used to suppress APRS2SOTA messages
  Debug_Pin = 19       'used for serial LCD display

DAT

  'Strings for automatic APRS2SOTA messages
  'Null terminated string format
  
  Summit   Byte "G/SP-004" ,0  'summit reference e.g. G/SP-004
         
  Act_call Byte "G3CWI/P"  ,0  'activating callsign e.g. G3CWI/P
 
OBJ

  mdm   :  "ax25"        'generates AX25 packet

  gps   :  "GPS_IO_mini" 'Extracts data from GPS NMEA string

  Num   :  "Numbers"     'Used to convert strings into decimals

  FS    :  "FloatString" 'Number conversion

  Debug :  "Debug_LCD03" 'My own debug stuff

  F32   :  "F32"

VAR

  byte packet[255]
  byte packetcount
  Long TX_DELAY 'used for timing polling rate
  Long TX_DEL   'used for selecting polling rate
  Long valid_dec, valid_addr 'used in string to dec routine
  Long speed_dec, speed_addr, speed_str 'used in string to dec routine
  Long gps_alt_addr, gps_alt_dec, gps_alt_str 'used in string to dec routine
  Long gps_heading_addr, gps_heading_dec, gps_heading_str 'used in string to dec routine  
  Long vdop_addr, vdop_dec 'used to check how good alt data is

  Long TX_LVL 'used to set modem o/p level

  Long stack_avg[100]'used in averaging routine 
  Long speed_avg, speed_avg_str, speed_avg_last
  Long alt_avg, alt_avg_str, alt_avg_last, alt_avg_counter
  Long heading_avg, heading_avg_str, heading_avg_last
  Long heading_avg_slide[60] 'Array for sliding average
  Long Direction, Direction_addr, Velocity, Velocity_addr, Height, Height_addr 'For APRS instantaneous display
  Long gps_altitude_addr, gps_altitude_dec, gps_altitude_str 'used in metric/imperial calc
  Long Quickness, Quickness_addr, Quickness_test 'Used in fun routine for variable messages
  Long Sats_visible
  Long FS_Stack[100]

  Long Switch_State 'Used to store state of walking/driving switch
  
  'Used in APRS2SOTA
  Byte az_flag
  Byte been_there

PUB main |tst, i, stringptr, tmp

    If Debug_Mode == TRUE
    
        'debug stuff
        Dira[Debug_Pin]~~
        Debug.init(Debug_Pin, 9_600, 4) 'Pin 0, 9_600 baud, 4 lines
        waitcnt((clkfreq/10)+cnt)
        Debug.cls
        waitcnt((clkfreq/10)+cnt)
        
        Debug.str(string ("DEBUG MODE"))
        Debug.BackLight(TRUE)
        Debug.NL
        Debug.CURSOR(3)
   
    '*****************MAIN STARTS HERE*********************
    
    dira~~            'sets all pins to outputs - this help avoid problems with RF
    dira[GPS_RX]      := in      'GPS Port set to input
    dira[Mode_Switch] := in      'Set Mode Switch to input
    switch_state      := Ina [Mode_Switch]
    been_there        := 0        'not ascended summit yet
    az_flag           := 0
    
    fs.SetPositiveChr(0) 'No leading spaces

    'Change TX level depending on mode
    '1 = Walking, 0 = Driving
    'Note - Mode only checked at boot-up
    Case switch_state
       1 : TX_LVL := 9   'level for VX-110
       0 : TX_LVL := 10  'level for FT-7800

    'Start parallel processes and initialise
    cognew(Averages, @stack_avg) 'start independent averaging routine
    
    mdm.start_simple(mdm#NONE, XMTPIN, PTTPIN, TX_LVL) 'Start AX25
    
    gps.start(GPS_Rx, GPS_Baud) 'Start GPS
    
    Num.Init 'Initialise Numbers Object
    
    F32.Start 'Start F32 maths
    
    'Change maximum delay depending on mode
    '1 = Walking, 0 = Driving
    'Note - Mode only checked at boot-up
    
    {If Debug_Mode == TRUE
    'Uncomment to set deviation : sends 1200Hz modem tone
      repeat
      
        repeat 10
          mdm.transmit

       waitcnt(clkfreq * 10 + cnt)}

         
        
    If Switch_State == 1  'If walking
    
       IF Debug_Mode == FALSE 'Normal mode
      
          TX_DEL := 180 '3 minutes between updates

          Repeat 5 'Five slow beeps to indicate walking mode
        
             led_(on)
             outa [Beep_Port] := 1
             waitcnt((clkfreq/3)+cnt) 
             led_(off)
             outa [Beep_Port] := 0 
             waitcnt((clkfreq/3)+cnt)
             
          '1 min delay for GPS lock and
          'put on rucksack
          Repeat 60
            waitcnt(clkfreq + cnt)          
            
       Else 'We are in debug mode
        
          TX_DEL := 20 'Short delay only
          
          Repeat 5 'Five very fast beeps to show debug mode
        
             led_(on)
             outa [Beep_Port] := 1
             waitcnt(clkfreq / 100 + cnt) 
             led_(off)
             outa [Beep_Port] := 0 
             waitcnt(clkfreq / 100 + cnt)
             
      
       If Suppress_SOTA == false
       
         Repeat 3 'Send "starting ascent" message three times
       
        
          
            clearpacket
            fill_starting_ascent_Packet
            mdm.createPacket(@packet, 0)  '1 = no path, 0 = full path (recommended)
          
          'Send two beeps and flash an LED
          'to show special packet being sent
            Repeat 2
           
              OutA [Beep_Port] := 1
              waitcnt(clkfreq/20 + cnt)
              OutA [Beep_Port] := 0
              waitcnt(clkfreq/20 + cnt)
             
            led_(on) 'packet being sent
          
            mdm.sendPacket

            waitcnt (clkfreq * 5 + cnt) '5 secs between attempts
           
            led_(off)           
               
       
    Else 'If mobile
    
        IF Debug_Mode == FALSE 'In normal mode
        
           TX_DEL := 600 '10 minutes
       
           OutA [Beep_Port] := 1 'One short beep
           waitcnt(clkfreq/10 + cnt)
           OutA [Beep_Port] := 0
           
           '1 min time delay to allow GPS lock
           repeat 60
             waitcnt (clkfreq + cnt) 
           
        Else 'We are in debug mode
        
          TX_DEL := 20 'Short delay only
          
          Repeat 5 'Five fast beeps to show debug mode
        
             led_(on)
             outa [Beep_Port] := 1
             waitcnt((clkfreq/100)+cnt) 
             led_(off)
             outa [Beep_Port] := 0 
             waitcnt((clkfreq/100)+cnt)
       
       Repeat 10 'Flash LED  
         led_(on)
         waitcnt((clkfreq/10)+cnt) 
         led_(off)
         waitcnt((clkfreq/10)+cnt) 

  
    
          
 '**********************************************************************************
 '                   This is the main loop
 '********************************************************************************** 
    Repeat 

      valid_addr := gps.satellites 'get address of satellites
      
      valid_Dec  := num.FromStr(valid_addr, num#dec) 'convert to decimal
      
        if  Debug_Mode == TRUE 'always send packets
        
          valid_Dec := 5
       
        if valid_Dec > 4  'Don't send packets unless position useful
         
          clearPacket
          
          'Send left_az message on descending - some hysteresis included
          If (alt_avg_last < (az_trigger - 15)) AND (been_there == 1) AND switch_state == 1 AND Suppress_SOTA == false
             
             Repeat 3 'Send packet three times
                clearPacket
                fill_left_az_packet 'send spot to APRS2SOTA on leaving az
                mdm.createPacket(@packet, 0)  '1 = no path, 0 = full path (recommended)

          '     'Send four beeps and flash an LED
          '     'to show special packet being sent
                repeat 4
                
                  OutA [Beep_Port] := 1
                  waitcnt(clkfreq/20 + cnt)
                  OutA [Beep_Port] := 0
                  waitcnt(clkfreq/20 + cnt)
                  
                led_(on) 'packet being sent
          
                mdm.sendPacket
              'debug.str(string("send_pkt"))
                waitcnt (clkfreq + cnt)
                led_(off)
           
               '10 second delay. No less than 5 seconds allowed between updates
                waitcnt (clkfreq * 10 + cnt)
                 
             az_flag    := 0 'keep the flag low while out of az
             
             been_there := 0 'not got there or we have left

          'test to see if in AZ also do some other tests for validity
          'if so send "arrived in AZ" message three times
          If (alt_avg_last > az_trigger) AND (been_there == 0) AND alt_avg_last < 9999 AND switch_state == 1 AND Suppress_SOTA == False
           
             Repeat 3 'Send packet three times
                clearPacket
                fill_entered_az_packet 'send spot to APRS2SOTA on leaving az
                mdm.createPacket(@packet, 0)  '1 = no path, 0 = full path (recommended)

          '     'Send three beeps and flash an LED
          '     'to show special packet being sent
                Repeat 3
                
                 OutA [Beep_Port] := 1
                 waitcnt(clkfreq/20 + cnt)
                 OutA [Beep_Port] := 0
                 waitcnt(clkfreq/20 + cnt) 
                
                led_(on) 'packet being sent
          
                mdm.sendPacket
              'debug.str(string("send_pkt"))
                waitcnt (clkfreq + cnt)
                led_(off)
           
               '10 second delay. No less than 5 seconds allowed between updates
                waitcnt (clkfreq * 10 + cnt)
             
             been_there := 1 'Flag to show that reached summit          
             
          Else
          
             fillGPSpacket 'send normal GPS Spot

          mdm.createPacket(@packet, 0)  '1 = no path, 0 = full path (recommended)

          'Send a beep and flash an LED
          'to show packet being sent
           OutA [Beep_Port] := 1
           
           If switch_state == 1
           
              waitcnt(clkfreq/10 + cnt) 'long pip walking
              
           Else
           
              waitcnt(clkfreq/200 + cnt) 'very short pip in car
              
           OutA [Beep_Port] := 0
           
           led_(on) 'packet being sent
          
          mdm.sendPacket 'send the packet
          'debug.str(string("send_pkt"))
          waitcnt (clkfreq + cnt)
          led_(off)
           
          '10 second delay. No less than 5 seconds allowed between updates
          waitcnt (clkfreq * 10 + cnt) 

          TX_DELAY := TX_DEL 'initialise TX hold off (seconds)

          Repeat until TX_DELAY < 1 'simple adaptive delay
             
            'Get Instaneous Speed as a decimal          
            speed_dec := gps.speed  'get address of gps.speed
            speed_dec  := FS.StringToFloat(tmp) 'turn string into FP decimal
            'Convert to mph*100 integer using floating point maths
            speed_dec := F32.FMul (Speed_Dec, 115.0)
            speed_dec := F32.FTrunc (Speed_Dec)
             
             
            'If the direction changes quickly send a position
            If speed_dec > 50 'only do this if actually moving more than 0.5MPH
               gps_heading_addr := gps.heading 'Get gps.heading string address
               'Returns integer part of string
               gps_heading_dec  := num.FromStr(gps_heading_addr, num#DEC)
                             
               IF gps_heading_dec - heading_avg_last >  45
                  TX_DELAY := 0
               IF gps_heading_dec - heading_avg_last < -45
                  TX_DELAY := 0
            
            'Adaptive transmission delay
            Case speed_dec
              5000..9900 : TX_DELAY := TX_Delay - 4 '50-99MPH
              3000..4900 : TX_DELAY := TX_Delay - 3 '30-49MPH
              2000..2900 : TX_DELAY := TX_Delay - 2 '20-29MPH
              Other  : TX_DELAY := TX_Delay - 1
              
            waitcnt( clkfreq + cnt ) 'Wait 1 second

PRI fill_left_az_Packet | r, temp
'Packet comforms to APRS2SOTA descriptor

      'add summit ref, a letter at a time
        r    := 0
        temp := 0
        temp := strsize(@summit)
      repeat until r == temp                    
        addToPacket (@summit[r], 1)
        r:= r+1
        
      addToPacket(string(":"), 1)
        
      'add activating callsign, a letter at a time
        r    := 0
        temp := 0
        temp := strsize(@act_call)
      repeat until r == temp                    
        addToPacket (@act_call[r], 1)
        r:= r+1
        
      addToPacket(string(":"), 1) 
      addToPacket(string("144.800:DATA:"), 13)
      addToPacket(string("Left activation zone. Thanks all. Autospot."), 43)
      addToPacket(0,1)          'end of packet
      
PRI fill_starting_ascent_Packet  | r, temp
'Packet comforms to APRS2SOTA descriptor

      'add summit ref, a letter at a time
        r    := 0
        temp := 0
        temp := strsize(@summit)
      repeat until r == temp                    
        addToPacket (@summit[r], 1)
        r:= r+1

      addToPacket(string(":"), 1)
       
      'add activating callsign, a letter at a time
        r    := 0
        temp := 0
        temp := strsize(@act_call)
      repeat until r == temp                    
        addToPacket (@act_call[r], 1)
        r:= r+1
        
      addToPacket(string(":"), 1) 
      addToPacket(string("144.800:DATA:"), 13)
      addToPacket(string("Starting ascent. Track on APRS.FI G3CWI-4. Autospot."), 52)
      addToPacket(0,1)          'end of packet
      
PRI fill_entered_az_Packet | r, temp
'Packet comforms to APRS2SOTA descriptor

     'add summit ref, a letter at a time
        r    := 0
        temp := 0
        temp := strsize(@summit)
      repeat until r == temp                    
        addToPacket (@summit[r], 1)
        r:= r+1
        
      addToPacket(string(":"), 1)
        
      'add activating callsign, a letter at a time
        r    := 0
        temp := 0
        temp := strsize(@act_call)
      repeat until r == temp                    
        addToPacket (@act_call[r], 1)
        r:= r+1
        
      addToPacket(string(":"), 1) 
      addToPacket(string("144.800:DATA:"), 13)
      addToPacket(string("In activation zone. Check alert for details. Autospot."), 54)
      addToPacket(0,1)          'end of packet
      
PRI fill_test_packet

     'Dummy packet, useful for initial testing
      addToPacket(string("!5315.60N/00207.70W-"), 20)        
      addToPacket(string("Propellor Test 12345"), 20)  
      addToPacket(0,1)          'end of packet

PRI fillGPSPacket | y,i,tempA,a,b

      'First add the latest position data
      addToPacket(string("!"), 1)
      addToPacket(gps.latitude, 7)
      addToPacket(gps.N_S, 1)   
      addToPacket(string("/"), 1) 'Selects primary icon set
      addToPacket(gps.longitude, 8)
      addToPacket(gps.E_W, 1)
     
      'Choose icon to display
      'see http://wa8lmf.net/aprs/APRS_symbols.htm

        If speed_avg_last == 0
            addToPacket(string("}"), 1) 'Cross-hairs icon if not moving 
        ElseIf Switch_State == 1 'Walking
            addToPacket(string("["), 1) 'Walking man icon 
        Else 
            addToPacket(string("v"), 1) 'Blue car icon
            
        'Add basic heading/speed/altitude data
        

        If speed_avg_last > 50 'Suppress random headings

          direction      := heading_avg_last
          direction      := num.ToStr(direction, num#dec4) 'returns fixed format with leading space
          bytemove(direction, direction + 1, 3) 'gets rid of space
          addToPacket(direction, 3)
          
        Else
        
          AddToPacket(String("000"), 3)
        
        addToPacket(string("/"),1)
        
        'Add velocity              
        velocity  := F32.FDIV(speed_avg_last, 100.0)
        velocity  := F32.FTrunc(velocity)
        velocity  := num.ToStr(velocity, num#dec4)
        bytemove(velocity, velocity + 1, 3) 'gets rid of space
        addToPacket(velocity, 3)
        
        addToPacket(string("/A="),3)
        
        'Add altitude
        If alt_avg_last < 9999
          height  := alt_avg_last * 3281
          height  := height / 1000
          height  := num.ToStr(height, num#dec7)
          bytemove(height, height + 1, 6) 'gets rid of space
        Else
          Height := string("000000")
          

        addToPacket(height, 6)

        
        If  Debug_Mode == True 'Shows mode on packets
        
          addToPacket (String(" ***Debug Mode*** "),18)
           
      '****Your data payload goes here****
      'Max 255 characters

        if Switch_State == 1
      
          addToPacket(string(" Pedestrian Mobile.") ,19) 
 
        'Reliable data needed for SOTA work.
          
        If Switch_State == 1 'While walking
            'Variable messages for follower interest
            Quickness_addr := gps.speed
            Quickness  := FS.StringToFloat(quickness_addr)   'turn string into FP decimal

            'Convert to mph*100 integer using floating point maths
            Quickness := F32.FMul (Quickness, 115.0)     
            Quickness_test := F32.FTrunc (quickness) 'Store result in temp variable
            
          Case Quickness_Test
            0..9     : AddToPacket(string(" Stopped."), 9)
            10..50   : AddToPacket(string(" Dawdling."), 10)
            51..150  : AddToPacket(string(" Walking slowly."), 16)
            151..200 : AddToPacket(string(" Making progress."), 17)
            201..300 : AddToPacket(string(" Walking well."), 14)
            301..450 : AddToPacket(string(" Walking briskly."), 17)
            451..700 : AddToPacket(string(" Running!"), 9)
            Other    : AddToPacket(string(" Must have got a lift or falling over cliff."), 44) 

          Quickness := F32.FDiv (Quickness, 100.0) 'Convert back to MPH * 1
          Quickness := fs.floattoformat(Quickness, 4, 1) 'Change to format to send  
          addtopacket(string(" "), 1)
          addtopacket (Quickness, strsize(Quickness))
          addtopacket (string(" MPH."), 5)
                   '

        'Fix data for diagnostic use
        addToPacket(string(" Instantaneous data:") ,20)
        tempA := gps.satellites
        addToPacket(string(" #") ,2)
        addToPacket(tempA , strsize(tempA)) 
        addToPacket(string(" sat fix.") ,9)

        tempA := gps.hdop         
        addToPacket(string(" HDOP=") ,6)
        addToPacket(tempA , 3)
        addToPacket(string(".") ,1)
        
        tempA := gps.vdop
        addToPacket(string(" VDOP=") ,6) 
        addToPacket(tempA , 3) 
        addToPacket(string(".") ,1)

      addToPacket(0,1)          'end of packet

PUB led_(onoff)

      outa[LED_Main] := onoff

PUB addToPacket(straddr, length) | pointer        'no nulls may be added, except at the end!

    pointer := straddr

    repeat length
       if (packetcount<256)
         packet[packetcount++] := byte[pointer++]      

PUB clearPacket | i

    repeat 255
        packet[i] := 0
        i++
        packetcount := 0

PUB Averages | counter_av, counter_av1
    
    dira[LED_Avg]~~ 'Cog running indicator set to output
  
    'this routine averages various GPS data to
    'give more stable readings for use in
    'calculations and display.
    
    'Set averages to zero before
    'first fills
    speed_avg_last   := 0
    alt_avg_last     := 0
    
  Repeat
      'initialise loop counters
      counter_av      := 0   
      alt_avg_counter := 0

      'reset averages
      speed_avg   := 0  
      alt_avg     := 0
      
      
        Repeat until  counter_av == 60
      
          !outa[LED_Avg] 'cog running indicator LED
          
  '       Speed processing
          speed_addr := gps.speed 'Get speed string address
          speed_dec  := FS.StringToFloat(speed_addr)          
          speed_dec  := F32.FMul (speed_dec, 115.0) 'Convert to MPH *100
          speed_dec  := F32.FTrunc (speed_dec) 'convert to integer
          speed_avg  := speed_avg + speed_dec
          
          'Altitude processing
          vdop_addr := gps.vdop 'Get speed string address
          vdop_dec  := num.FromStr(vdop_addr, num#DEC)

          IF vdop_dec < 2 'only use if the fix is good
          
            gps_alt_addr := gps.gpsaltitude 'Get gps.alt string address
            gps_alt_dec  := num.FromStr(gps_alt_addr, num#DEC)
            alt_avg := alt_avg + gps_alt_dec
            alt_avg_counter := alt_avg_counter + 1
          
          'Heading processing using sliding average
          gps_heading_addr := gps.heading 'Get gps.heading string address
          gps_heading_dec  := num.FromStr(gps_heading_addr, num#DEC)
          heading_avg_slide[counter_av] := gps_heading_dec
          
          counter_av1 := 0 'Initialise counter for sliding avg
          heading_avg := 0 'Initialise heading average
          
           Repeat until counter_av1 == 60 'Revise average
              heading_avg := heading_avg + heading_avg_slide [counter_av1]
              counter_av1 := counter_av1 + 1 'increment loop counter
          'store value for use elsewhere   
          heading_avg_last := heading_avg / 60
        
          
          counter_av := counter_av + 1 'Increment averaging loop counter
          
          waitcnt(clkfreq + cnt)'wait a second for the next GPS string

      'Calculate averages
      speed_avg := speed_avg / 60
      
      if alt_avg_counter > 19 'miniumum of 20 acceptable samples
       
        alt_avg := alt_avg / alt_avg_counter
        
      Else
      
        alt_avg := 9999 'flag to show data quality poor
      
      'Fill the average variables
      speed_avg_last   := speed_avg
      alt_avg_last     := alt_avg
      