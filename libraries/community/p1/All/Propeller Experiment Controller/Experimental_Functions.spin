{{

┌────────────────────────────────────────────┐
│ Experimental Functions v1.4                │
│ Author: Christopher A Varnon               │
│ Created: December 2011, Updated: 13-13-2013│
│ See end of file for terms of use.          │
└────────────────────────────────────────────┘

  Experimental Functions includes common functions for conducting experiments.
  Designed to interact with multiple Experimental Event objects.

}}

VAR
  Long Clock                                                                    ' Contains the clock value in milliseconds.
  Long ClockStack[10]                                                           ' The expclock runs here.
  Byte ClockCogID                                                               ' The ID of the cog that will run the expclock.
  Byte Data[100]                                                                ' A byte array of data used to read in files from memory. 100 bytes are more than sufficient.

  Long Sync                                                                     ' Used to contain the counter value for the start of a synchronized pause.

  Long LastRandom                                                               ' Used for the pseudorandom method. Notes the last value selected.
  Long FirstRandom                                                              ' Used for the pseudorandom method. Notes if the method has been run before.
  Byte ConsecutiveSelection                                                     ' Used for the pseudorandom method. Notes if there has been a string of the same selection.
  Byte RealRandomOn                                                             ' Notes if the real random method has been activated.

  Byte Error                                                                    ' Used to note occurrences of errors when processing data.
  Word ErrorNote                                                                ' Contains printed error notes. Error support currently only includes processing too many instances of behavior.

  Byte Generators                                                               ' Used to note which frequency generators are active.

  Long Generator12Stack[20]                                                     ' Frequency generator 1 and 2 run here.
  Long Generator34Stack[20]                                                     ' Frequency generator 3 and 4 run here.

  Byte FrequencyPin1                                                            ' The pin number associated with the first frequency.
  Byte FrequencyPin2                                                            ' The pin number associated with the second frequency.
  Byte FrequencyPin3                                                            ' The pin number associated with the third frequency.
  Byte FrequencyPin4                                                            ' The pin number associated with the fourth frequency.
  Byte InvertedPin1                                                             ' The pin number associated with the inverted first frequency.
  Byte InvertedPin2                                                             ' The pin number associated with the inverted second frequency.
  Byte InvertedPin3                                                             ' The pin number associated with the inverted third frequency.
  Byte InvertedPin4                                                             ' The pin number associated with the inverted fourth frequency.

  Long Frequency1                                                               ' The first frequency.
  Long Frequency2                                                               ' The second frequency.
  Long Frequency3                                                               ' The third frequency.
  Long Frequency4                                                               ' The fourth frequency.

  Byte PWMBasePin                                                               ' The base pin used for pulse-width modulation.
  Byte PWMPinMask                                                               ' The mask for other pins in the same block as the PWM base pin.

OBJ
  SD:       "EXP_FSRW"                                                          ' SD card object.
  RR:       "EXP_RealRandom"                                                    ' The real random object for generating better random numbers.
  FG[2]:    "EXP_FrequencyGenerator"                                            ' Two frequency generator objects for up to 4 frequencies. Each object uses 1 cog.
  PWM:      "EXP_PWMx8"                                                         ' A pulse width modulation object than can modulate up to 8 outputs using 1 cog.
  Numbers:  "EXP_Numbers"                                                       ' An object containing methods from Parallax's Numbers and Simple Numbers objects. Used to convert numbers to strings and vice versa.

CON
{{
┌──────────────────────────┐
│ Experiment Start Methods │
└──────────────────────────┘
}}
PUB StartExperiment(DO,CLK,DI,CS) | MemoryFile
  '' This method mounts the SD card, then launches the experiment clock.
  '' The user must provide the appropriate pins for the SD card.
  '' A cog is used to interface with the SD card, a second cog is used for the experimental clock.

  MemoryFile:=string("memory.txt")                                              ' Uses the default memory file name.
  return StartExperimentCustomMemory(DO,CLK,DI,CS,MemoryFile)                   ' Starts the experiment with the default memory file name. Returns -1 if SD card fails to mount.

PUB StartExperimentCustomMemory(DO,CLK,DI,CS,Memoryfile) | mount
  '' This method mounts the SD card, then launches the experiment clock.
  '' The user must provide the appropriate pins for the SD card.
  '' A cog is used to interface with the SD card, a second cog is used for the experimental clock.
  '' This method allows user to specify the name of the memory file.
  '' This can be useful in running several sessions in a series. Each session can have unique own memory and data files.

  '' Note that long file names are not supported. File names can be a maximum of 8 characters, plus a three letter extension.
  '' For example abc.txt or abcdefgh.txt are valid names while abcdefghij.txt is not a valid name.

  mount:=\SD.mount_explicit(DO,CLK,DI,CS)                                       ' Mounts SD drive on declared pins.
  if mount < 0                                                                  ' If the SD card can't be mounted.
    return -1                                                                   ' Return a -1.
  SD.popen(Memoryfile,"w")                                                      ' Creates or opens memory.txt for writing.
  ClockCogID:=cognew(EXPCLOCK, @ClockStack)                                     ' Starts the clock on a new cog.

PUB StartExperiment_NoData
  '' This method launches the clock without mounting an SD card.
  '' A cog is used for the experimental clock.

  ClockCogID:=cognew(EXPCLOCK, @ClockStack)                                     ' Starts the clock on a new cog.

CON
{{
┌──────────────────────┐
│ Time Related Methods │
└──────────────────────┘
}}
PRI ExpClock | systime
  '' The clock's maximum value is about 2,147,483,647.
  '' It can run for about 596 hours or 24 days.
  '' After this point it will start to return negative numbers.
  '' The clock has been tested for 7 hours and was still accurate to the millisecond.
  '' Note that ExpClock is a private method. It can only be called by experimental functions.

  SysTime:=cnt                                                                  ' Finds current value of system counter.
  repeat
    waitcnt(SysTime += clkfreq/1000)                                            ' Waits one millisecond. A synchronized pause.
    Clock++                                                                     ' After a millisecond passes, add 1 to the clock.

PUB SetClock(NewValue)
  '' This method changes the clock value.
  '' It can be used to reset the clock in the rare senario where the clock runs for over 24 days.

  Clock:=NewValue

PUB ClockID
  '' Returns the address of the clock so that other objects can store the address and refer to the value.
  '' This is primarily used to provide each experimental event with the system clock value for debouncing.

  return @Clock

PUB Time(Event)
  '' Reports time since an event. If time(0) is called it returns the current time.
  '' A session starting value can be set by creating a variable such as "start" and declaring start:=exp.time(0) at the start of the experiment.
  '' After this, calling exp.time(start) will report how much time has passed since the session started.

  return (Clock-Event)

PUB Pause(Duration)
  '' The cog that calls this method pauses for the duration in milliseconds.
  '' No code will run during the pause.

  '' This method is fairly accurate, however, longer durations  may introduce small (1 ms) inaccuracies.
  '' For example, a 1 ms error may occur after 5 consecutive 5 minute pauses.
  '' A single 25 minute pause is less likely to create this 1 ms error.

  '' If a repeated pause is needed in a loop, syncpause may be more accurate.
  '' Syncpause will consider the time it takes to run the code in a loop, pause will not.

  Duration#>=1                                                                  ' Limit duration to 1ms minimum.
  Duration+=Clock                                                               ' Adds the current clock value to the duration to obtain the time of the end of the pause.
  repeat until Clock=>Duration                                                  ' Pauses until the current clock value reaches the end of the pause.
    waitcnt(400+cnt)                                                            ' Pauses the cog as briefly as possible. The smallest value that can be paused is (381+cnt). 400 is used here to be safe.

PUB StartSync
  '' Marks a point to use for synchronized pauses.

  Sync:=Clock

PUB SyncPause(Duration)
  '' This method creates a synchronized pause in a repeat loop.
  '' The cog that calls this method pauses for the duration in milliseconds.
  '' No code will run during the pause.
  '' Call StartSync before a loop, then use SyncPause inside the loop.
  '' SyncPause takes into consideration the execution time of the code.
  '' SyncPause ensures that the loop will last exactly the duration provided.

  '' This example will do something exactly every 5 seconds.
  '' The time taken to do something is factored into the pause.
  '' The pause will be inaccurate only if it takes more than 5 seconds to do something.
  ''  exp.startsync
  ''  repeat
  ''    do something
  ''    exp.syncpause(5000)

  '' Note that the value created when StartSync is used is shared amongst all cogs.
  '' This means that a SyncPause can only be called on one cog at a time.
  '' If multiple cogs use SyncPause simultaneously errors may occur.

  Duration#>=1                                                                  ' Limit duration to 1ms minimum.
  Sync+=Duration                                                                ' Adds the duration to sync, the clock value at the start of the loop, to obtain the clock value at the end of the pause.
  repeat until Clock=>Sync                                                      ' Pauses until the current clock value reaches the end of the pause.
    waitcnt(400+cnt)                                                            ' Pauses the cog as briefly as possible. The smallest value that can be paused is (381+cnt). 400 is used here to be safe.

PUB PulseOutput(Pin,Duration)
  '' This method changes the state of an output for the duration provided.
  '' Note that it suspends all activity on that cog until it is complete.
  '' Repeated use may be inaccurate by a small degree.
  '' For high accuracy in a repeated application, use synchronized pauses.

  dira[pin]:=1                                                                  ' Make sure the pin is set to an output.
  !outa[pin]                                                                    ' Toggle the output state.
  Pause(Duration)                                                               ' Pause.
  !outa[pin]                                                                    ' Toggle the output to the initial state.                                                                ' Toggle output state.

CON
{{
┌─────────────────────────────────┐
│ Random Number Generation Methods │
└─────────────────────────────────┘
}}
  '' The follow methods generator random numbers using  pseudorandom number generator.
  '' The pseudorandom numbers generated are very close to random, but are not true random numbers.
  '' Two random number generators are available.
  ''
  '' By default random numbers are generated based on the experiment clock time.
  '' Numbers generated in this manner appear very random, but patterns may appear if they are generated at regular time intervals.
  '' For example, a pattern will likely emerge using the following code.
  '' The example assumes print is a method defined elsewhere.
  ''    repeat
  ''       print(exp.random)
  ''       exp.pause(50)
  '' In the next example a pattern is much less likely to emerge because the time intervals are irregular.
  ''    repeat
  ''       print(exp.random)
  ''       exp.pause(exp.randomrange(10,50)
  '' Fortunately, generating random numbers dependent on the subject's behavior is very unlikely to generate patterns.
  '' As the subject rarely response in precise time intervals, patterns are unlikely to emerge.
  '' In the following example, the condition is randomly selected only when the subject activates a lever.
  ''    repeat
  ''      lever.detect
  ''       if lever.state==1
  ''         condition:=exp.random
  ''
  '' Random numbers can also be generated using Parallax's RealRandom method.
  '' Numbers generated with this method are more random. However, an entire cog is needed to produce random numbers.
  ''
  '' The user is free to pick which method is used to generate random numbers.
  '' If the random numbers are generated when a subject responds, use the default generator to save a cog.
  '' If the random numbers are generated at regular time intervals, activate the RealRandom method.
  '' If free cogs are not available, the ReadRandom method can be activated, used, then deactivated to free the cog.
  '' The following methods to generate specific random numbers use whichever method the user selected.
  '' If RealRandom has been activated, it will be used. Otherwise the experiment clock method will be used.

PUB StartRealRandom
  '' This method launches Parallax's RealRandom method in a new cog.
  '' If the RealRandom method is active, it will be used to generate random numbers.
  '' This allows the user to generate better random numbers at the cost of a cog.
  '' If RealRandom is not activated, random numbers can be generated with a less advanced method.

  rr.start                                                                      ' Starts RealRandom.
  realrandomon:=1                                                               ' Notes that RealRandom is active.

PUB StopRealRandom
  '' This method stops Parallax's RealRandom method and frees a cog.

  rr.stop                                                                       ' Stops RealRandom.
  realrandomon:=0                                                               ' Notes that RealRandom is inactive.

PUB Random | value
  '' This method randomly generates 1 or 0.
  '' It can be used to randomly determine if an event occurs.
  '' This method returns 1 approximately 50 percent of the time.
  '' In one test, the chance that the random method returned a 1 during 100,000 was 50.07 percent.

  if realrandomon==1                                                            ' If RealRandom is active.
    value:=rr.random                                                            ' Use it to generate a random number.
  else                                                                          ' If RealRandom is inactive.
    value:=clock                                                                ' Use experimental clock as base to generate a random number.
    ?value

  if value > -1                                                                 ' If value is greater than -1, return 1 to indicate true.
    return 1
  else                                                                          ' If value is less than 0, return 0 to indicate false.
    return 0

PUB PseudoRandom(Limit) | value
  '' This method randomly generates 1 or 0, but will not randomly generate a long sequence of 1s or 0s.
  '' If a sequence of random numbers meets the user specified limit, the next number will be selected deliberately to break that sequence.
  '' This can be used to create psuedorandom sequences of conditions.
  '' Note that because it uses global variables, multiple simultaneous uses of pseudorandom will interfere with each other.

  value:=random                                                                 ' Obtain a random 1 or 0.

  if firstrandom==0                                                             ' If this is the first random number generated.
    firstrandom+=1                                                              ' Lastrandom will be 0 by default, so set firstrandom to 1 and ignore the rest.

  elseif value==lastrandom                                                      ' If that value is the same as the last value.
    consecutiveselection+=1                                                     ' Note that the same random number has been selected.
    if consecutiveselection=>limit                                              ' If a consecutive sequence of the same value has been selected and this exceeds the user defined limit.
      consecutiveselection:=0                                                   ' The sequence will be broken so reset consecutive selection.
      if value==1                                                               ' If the last value was 1.
        value:=0                                                                ' Force the selection to be 0.
      else                                                                      ' If the last value was 0.
        value:=1                                                                ' Force the selection to be 1.

  lastrandom:=value                                                             ' Save the current value for the next random generation.
  return value                                                                  ' Return the random value.

PUB RandomRange(Minimum,Maximum) | value, range
  '' This method generates a random number within a provided range.
  '' The range is limited to 2,000,000,000.
  '' Negative numbers are allowed.
  '' The maximum range can be expressed in a number of ways, such as (0,2000000000), (-1000000000,999999999), or (-2000000000,0).
  '' The average of repeated samplings of a range are generally close to the average of the smaller and larger numbers.
  '' In one test, after 100,000 iterations of randomrange(0,100), the results averaged to 50.00 - the expected value.

  if realrandomon==1                                                            ' If RealRandom is active.
    value:=rr.random                                                            ' Use it to generate a random number.
  else                                                                          ' If RealRandom is inactive.
    value:=clock                                                                ' Use experimental clock as base to generate a random number.
    ?value

  range:=||(Minimum-Maximum)                                                    ' The range is the absolute value of the difference between the numbers.
  value:=||(value//(range+1))                                                   ' Divide the random number by range+1 and save the remainder.
  value+=Minimum                                                                ' The final value is the remainer plus the smaller number.

  return value                                                                  ' Return the selected value.

PUB PseudoRandomRange(Minimum,Maximum,Limit) | value
  '' This method generates a random number within a provided range, but will not randomly generate a long sequence of the same number.
  '' This method generates generates 1 or 0, but will not randomly generate a long sequence of 1s or 0s.
  '' If a sequence of random numbers meets the user specified limit, the next number will be selected deliberately to break that sequence.
  '' This can be used to create psuedorandom sequences of conditions.
  '' Note that because it uses global variables, multiple simultaneous uses of pseudorandom will interfere with each other.
  '' As with RandomRange, the range is limited to 2,000,000,000.

  value:=randomrange(minimum,maximum)                                           ' Obtain a random number.

  if firstrandom==0                                                             ' If this is the first random number generated.
    firstrandom+=1                                                              ' Lastrandom will be 0 by default, so set firstrandom to 1 and ignore the rest.

  elseif value==lastrandom                                                      ' If that value is the same as the last value.
    consecutiveselection+=1                                                     ' Note that the same random number has been selected.
    if consecutiveselection=>limit                                              ' If a consecutive sequence of the same value has been selected and this exceeds the user defined limit.
      consecutiveselection:=0                                                   ' The sequence will be broken so reset consecutive selection.
      repeat while value==lastrandom                                            ' As long as the current value is the same as the previous value.
        value:=randomrange(minimum,maximum)                                     ' Generate a new value.

  lastrandom:=value                                                             ' Save the current value for the next random generation.
  return value                                                                  ' Return the random value.

PUB Probability(Chance) | value
  '' This method is used to determine the probability that an event occurs.
  '' The method takes a percent value and returns a 1 to indicate true, or a zero to indicate false.
  '' The value returned is more likely to be a 1 as probability approaches 100, and more likely to be a 0 as the probability approaches 0.
  '' Only whole numbers are allowed.

  '' The following data show expected probabilities provided to the method and obtained probabilities derived by running each probability 100,000 times.
  '' Expected: 0    Observed: 0.00                      Expected: 50    Observed: 51.59
  '' Expected: 5    Observed: 5.39                      Expected: 55    Observed: 56.55
  '' Expected: 10   Observed: 10.59                     Expected: 60    Observed: 61.21
  '' Expected: 15   Observed: 15.85                     Expected: 65    Observed: 66.33
  '' Expected: 20   Observed: 21.18                     Expected: 70    Observed: 70.97
  '' Expected: 25   Observed: 26.37                     Expected: 75    Observed: 75.71
  '' Expected: 30   Observed: 31.43                     Expected: 80    Observed: 80.51
  '' Expected: 35   Observed: 36.67                     Expected: 85    Observed: 85.22
  '' Expected: 40   Observed: 41.53                     Expected: 90    Observed: 89.94
  '' Expected: 45   Observed: 46.70                     Expected: 95    Observed: 94.51

  value:=RandomRange(0,100)                                                     ' Generates a random number between 0 and 100.
  if chance>value                                                               ' If the user provided chance is greater than the random number.
    return 1                                                                    ' Return a 1 to indicate true.
  elseif chance=<value                                                          ' Otherwise, if the chance is less than or equal the random number.
    return 0                                                                    ' Return a 0 to indicate false.

CON
{{
┌──────────────────────────────┐
│ Frequency Generation Methods │
└──────────────────────────────┘
}}
  '' The following methods generate frequencies on user provided pins.
  '' Once the frequencies are set, the pin will pulse at that frequency without delaying other tasks.
  '' The frequencies generators are primarily used to generate tones.
  '' Any other output, such as an LED or a motor can also be activated using the frequency generators.

  '' A total of 4 generators are available. Two generators run in a cog.
  '' If 1-2 generators are needed, 1 cog is used. If 3-4 generators are needed, 2 cogs are used.

  '' In addition to generating frequencies on the primary pin, inverted frequencies can be generated on another pin.
  '' The inverted pin will always be off when the primary pin is on, and vice versa.
  '' At high frequencies, the inversion will not be obvious.
  '' This can be used to generate the same tone on two audio channels, such as left and right, with one frequency generator.
  '' At slower frequencies, the inversion is obvious and can be used to do things such as alternatively blinking 2 LEDs.

  '' Musical Notes - rounded to the nearest Hz.
  '' Notes can be used in a program with exp#notename.
  '' For example, exp.SetFrequency(AudioPin,exp#A4)

  C0=0016,  Cs0=0017,  D0=0018,  Ds0=0019,  E0=0021,  F0=0022,  Fs0=0023,  G0=0025,  Gs0=0026,  A0=0028,  As0=0029,  B0=0031
  C1=0032,  Cs1=0035,  D1=0037,  Ds1=0039,  E1=0041,  F1=0044,  Fs1=0046,  G1=0049,  Gs1=0052,  A1=0055,  As1=0058,  B1=0062
  C2=0065,  Cs2=0069,  D2=0073,  Ds2=0078,  E2=0082,  F2=0087,  Fs2=0093,  G2=0098,  Gs2=0104,  A2=0110,  As2=0117,  B2=0123
  C3=0131,  Cs3=0139,  D3=0147,  Ds3=0156,  E3=0165,  F3=0175,  Fs3=0185,  G3=0196,  Gs3=0208,  A3=0220,  As3=0233,  B3=0247
  C4=0262,  Cs4=0277,  D4=0294,  Ds4=0311,  E4=0330,  F4=0349,  Fs4=0370,  G4=0392,  Gs4=0415,  A4=0440,  As4=0466,  B4=0494
  C5=0523,  Cs5=0554,  D5=0587,  Ds5=0622,  E5=0659,  F5=0698,  Fs5=0740,  G5=0784,  Gs5=0831,  A5=0880,  As5=0932,  B5=0988
  C6=1047,  Cs6=1109,  D6=1175,  Ds6=1245,  E6=1319,  F6=1397,  Fs6=1480,  G6=1568,  Gs6=1661,  A6=1760,  As6=1865,  B6=1976
  C7=2093,  Cs7=2217,  D7=2349,  Ds7=2489,  E7=2637,  F7=2794,  Fs7=2960,  G7=3136,  Gs7=3322,  A7=3520,  As7=3729,  B7=3951
  C8=4186,  Cs8=4435,  D8=4699,  Ds8=4978,  E8=5274,  F8=5588,  Fs8=5920,  G8=6272,  Gs8=6645,  A8=7040,  As8=7459,  B8=7902

PUB StartFrequencyGenerator(Pin,InvertedPin)
  '' This method starts a frequency generator on a user-provided pin.
  '' Optionally, it will generate an inverted frequency on the inverted pin.
  '' Use -1 for InvertedPin if no inverted pin is desired.
  '' The frequency generator requires 1 cog, but a second generator can also be started on that cog.
  '' Simply call the method a second time with a new pin to start a new generator.
  '' Up to 4 generators can be started this way, using a total of 2 cogs.
  '' No frequency will be generated until a specific frequency is provided with the SetFrequency method.

  case Generators                                                               ' Looks at the current state of the generators to find out which generator to start.
    %0000_0000:                                                                 ' No generators are active.
      cognew(Generator12, @Generator12Stack)                                    ' Start generator 1 in a new cog.
      Generators|= %0000_0001                                                   ' Note generator 1 now is active.
      FrequencyPin1:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin1:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_0001:                                                                 ' Generator 1 is active
      Generators|= %0000_0010                                                   ' Note generator 2 now is active.
      FrequencyPin2:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin2:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_0010:                                                                 ' Generator 2 is active
      Generators|= %0000_0001                                                   ' Note generator 1 now is active.
      FrequencyPin1:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin1:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_0011:                                                                 ' Generators 1 and 2 are active.
      cognew(Generator34, @Generator34Stack)                                    ' Start generator 3 in a new cog.
      Generators|= %0000_0100                                                   ' Note generator 3 now is active.
      FrequencyPin3:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin3:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_0100:                                                                 ' Generator 3 is active.
      Generators|= %0000_1000                                                   ' Note generator 4 now is active.
      FrequencyPin4:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin4:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_0101:                                                                 ' Generators 1 and 3 are active.
      Generators|= %0000_0010                                                   ' Note generator 2 now is active.
      FrequencyPin2:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin2:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_0110:                                                                 ' Generators 2 and 3 are active.
      Generators|= %0000_0001                                                   ' Note generator 1 now is active.
      FrequencyPin1:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin1:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_0111:                                                                 ' Generators 1, 2 and 3 are active.
      Generators|= %0000_1000                                                   ' Note generator 4 now is active.
      FrequencyPin4:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin4:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_1000:                                                                 ' Generator 4 is active.
      Generators|= %0000_0100                                                   ' Note generator 3 now is active.
      FrequencyPin3:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin3:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_1001:                                                                 ' Generators 1 and 4 are active.
      Generators|= %0000_0010                                                   ' Note generator 2 now is active.
      FrequencyPin2:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin2:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_1010:                                                                 ' Generators 2 and 3 are active.
      Generators|= %0000_0001                                                   ' Note generator 1 now is active.
      FrequencyPin1:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin1:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_1011:                                                                 ' Generators 1, 2 and 4 are active.
      Generators|= %0000_0100                                                   ' Note generator 3 now is active.
      FrequencyPin3:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin3:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_1100:                                                                 ' Generators 3 and 4 are active.
      cognew(Generator12, @Generator12Stack)                                    ' Start generator 1 in a new cog.
      Generators|= %0000_0001                                                   ' Note generator 1 now is active.
      FrequencyPin1:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin1:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_1101:                                                                 ' Generators 1, 3 and 4 are active.
      Generators|= %0000_0010                                                   ' Note generator 2 now is active.
      FrequencyPin2:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin2:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_1110:                                                                 ' Generators 2, 3 and 4 are active.
      Generators|= %0000_0001                                                   ' Note generator 1 now is active.
      FrequencyPin1:=Pin                                                        ' Save the provided pin number.
      if InvertedPin>-1                                                         ' If an inverted pin is to be used.
        InvertedPin1:=InvertedPin+1                                             ' Save the provided pin number.
    %0000_1111:                                                                 ' All generators are already active.
      return -1                                                                 ' Return -1 to indicate an error.

PUB SetFrequency(Pin, Frequency)
  '' This method sets a frequency on a pin.
  '' The user does not need to specify the frequency generator or the inverted pin.
  '' The method uses the primary pin to determine other variables.

  case pin                                                                      ' Match the provided pin number to previously recorded pins to determine which frequency to set.
    frequencypin1:                                                              ' If the pin is frequency pin 1.
      frequency1:=frequency                                                     ' Set the frequency to frequency 1.
    frequencypin2:                                                              ' If the pin is frequency pin 2.
      frequency2:=frequency                                                     ' Set the frequency to frequency 2.
    frequencypin3:                                                              ' If the pin is frequency pin 3.
      frequency3:=frequency                                                     ' Set the frequency to frequency 3.
    frequencypin4:                                                              ' If the pin is frequency pin 4.
      frequency4:=frequency                                                     ' Set the frequency to frequency 4.

PUB PlayNote(pin,note,duration)
  '' This method sets a frequency on a pin for the duration provided.
  '' Note that, like PulseOutput, it suspends all activity on that cog until it is complete.
  '' This method can be used to play melodies.

  SetFrequency(Pin,Note)                                                        ' Starts the frequency.
  Pause(Duration)                                                               ' Holds the frequency for the provided duration.
  SetFrequency(Pin,0)                                                           ' Stops the frequency.

PUB StopFrequencyGenerator(Pin)
  '' This method stops a frequency generator related to the provided pin.
  '' The frequency generator will also be stopped to the inverted pin if it was used.
  '' Stoping all frequency generators on a cog will result in freeing that cog.
  '' For example, if StartFrequencyGenerator is called twice, then 2 generators will be launched in one cog.
  '' Then calling StopFrequencyGenerator twice will stop those generators and free that cog.

  case pin                                                                      ' Match the provided pin number to previously recorded pins to determine which generator to stop.
    frequencypin1:                                                              ' If the pin is frequency pin 1.
      Generators &= %1111_1110                                                  ' Stop generator 1.
      FrequencyPin1:=0                                                          ' Reset the frequency pin.
      InvertedPin1:=0                                                           ' Reset the inverted pin.
      Frequency1:=0                                                             ' Reset the frequency.
    frequencypin2:                                                              ' If the pin is frequency pin 2.
      Generators &= %1111_1101                                                  ' Stop generator 2.
      FrequencyPin2:=0                                                          ' Reset the frequency pin.
      InvertedPin2:=0                                                           ' Reset the inverted pin.
      Frequency2:=0                                                             ' Reset the frequency.
    frequencypin3:                                                              ' If the pin is frequency pin 3.
      Generators &= %1111_1011                                                  ' Stop generator 3.
      FrequencyPin3:=0                                                          ' Reset the frequency pin.
      InvertedPin3:=0                                                           ' Reset the inverted pin.
      Frequency3:=0                                                             ' Reset the frequency.
    frequencypin4:                                                              ' If the pin is frequency pin 4.
      Generators &= %1111_0111                                                  ' Stop generator 4.
      FrequencyPin4:=0                                                          ' Reset the frequency pin.
      InvertedPin4:=0                                                           ' Reset the inverted pin.
      Frequency4:=0                                                             ' Reset the frequency.

PRI Generator12
'' This method runs frequency generators 1 and 2. It requires a cog.

  Repeat
    if Generators & %0000_0001 == %0000_0001                                    ' If generator 1 is active.
      if FG[0].GetCounter & %0000_0001 == %0000_0000                            ' If counter A is inactive
        FG[0].SquareWave("A",FrequencyPin1,InvertedPin1-1)                      ' Start the counter.
      FG[0].SetFrequency("A",Frequency1)                                        ' Set the frequency.
    else
      FG[0].StopCounter("A",FrequencyPin1,InvertedPin1-1)                       ' Stop the generator.

    if Generators & %0000_0010 == %0000_0010                                    ' If generator 2 is active.
      if FG[0].GetCounter & %0000_0010 == %0000_0000                            ' If counter B is inactive
        FG[0].SquareWave("B",FrequencyPin2,InvertedPin2-1)                      ' Start the counter.
      FG[0].SetFrequency("B",Frequency2)                                        ' Set the frequency.
    else
      FG[0].StopCounter("B",FrequencyPin2,InvertedPin2-1)                       ' Stop the generator.

    if Generators & %0000_0011 == %0000_0000                                    ' If generators 1 and 2 are inactive.
      cogstop(CogID)                                                            ' Stop the cog.

PRI Generator34
'' This method runs frequency generators 3 and 4. It requires a cog.

  Repeat
    if Generators & %0000_0100 == %0000_0100                                    ' If generator 3 is active.
      if FG[1].GetCounter & %0000_0001 == %0000_0000                            ' If counter A is inactive
        FG[1].SquareWave("A",FrequencyPin3,InvertedPin3-1)                      ' Start the counter.
      FG[1].SetFrequency("A",Frequency3)                                        ' Set the frequency.
    else
      FG[1].StopCounter("A",FrequencyPin3,InvertedPin3-1)                       ' Stop the generator.

    if Generators & %0000_1000 == %0000_1000                                    ' If generator 4 is active.
      if FG[1].GetCounter & %0000_0010 == %0000_0000                            ' If counter B is inactive
        FG[1].SquareWave("B",FrequencyPin4,InvertedPin4-1)                      ' Start the counter.
      FG[1].SetFrequency("B",Frequency4)                                        ' Set the frequency.
    else
      FG[1].StopCounter("B",FrequencyPin4,InvertedPin4-1)                       ' Stop the generator.

    if Generators & %0000_1100 == %0000_0000                                    ' If generators 3 and 4 are inactive.
      cogstop(CogID)                                                            ' Stop the cog.

CON
{{
┌────────────────────────────────┐
│ Pulse-width Modulation Methods │
└────────────────────────────────┘
}}
  '' The following methods use a technique called pulse-width modulation to simulate changes in voltage.
  '' A PWM signal is only on for a fraction of a duty cycle. Here, the duty cycle occurs 23,000 times a second.
  '' The result is that signals that are on for a small percent of the cycle appear to receive less voltage.
  '' For example, lights appear dimmer and motors appear slower.

  '' The following methods can generate up to 8 PWM signals using the video counter of a new cog.
  '' However, the all the pins receiving PWM must be within the same block.
  '' All pins must be in block 1 (0,7), block 2 (8-15), block 3 (6-23), or block 4(24-31)
  '' PWM will only occur on the desired pins, but no pins outside of the block can receive PWM.

PUB StartPWM(Pin)
  '' This method starts the PWM cog.
  '' Up to 8 outputs can be modulated simultaneously
  '' However they MUST be in the same block of pins.
  '' Blocks: 0-7, 8-15, 16-23, 24-31.
  '' If PWM is desired on multiple pins, simply call the StartPWM method for each pin.

  if pin<8                                                                      ' If the pin number is less than 8.
    pwmbasepin:=0                                                               ' It must be in the first block.
  elseif pin<16                                                                 ' Otherwise, if the pin number is less than 16.
    pwmbasepin:=8                                                               ' It must be in the second block.
  elseif pin<24                                                                 ' Otherwise, if the pin number is less than 24.
    pwmbasepin:=16                                                              ' It must be in the third block.
  elseif pin>23                                                                 ' Otherwise, if the pin number is greater than 23.
    pwmbasepin:=24                                                              ' It must be in the fourth block.

  case pin-pwmbasepin                                                           ' Subtract the base pin from the pin number to determine the pin's position.
    0: pwmpinmask|= %0000_0001                                                  ' Pin is in the first position. Note to use PWM on this pin in addition to any others.
    1: pwmpinmask|= %0000_0010                                                  ' Pin is in the second position. Note to use PWM on this pin in addition to any others.
    2: pwmpinmask|= %0000_0100                                                  ' Pin is in the third position. Note to use PWM on this pin in addition to any others.
    3: pwmpinmask|= %0000_1000                                                  ' Pin is in the fourth position. Note to use PWM on this pin in addition to any others.
    4: pwmpinmask|= %0001_0000                                                  ' Pin is in the firth position. Note to use PWM on this pin in addition to any others.
    5: pwmpinmask|= %0010_0000                                                  ' Pin is in the sixth position. Note to use PWM on this pin in addition to any others.
    6: pwmpinmask|= %0100_0000                                                  ' Pin is in the seventh position. Note to use PWM on this pin in addition to any others.
    7: pwmpinmask|= %1000_0000                                                  ' Pin is in the eighth position. Note to use PWM on this pin in addition to any others.

  pwm.start(pwmbasepin, pwmpinmask, 23_000)                                     ' Start or restart the PWM cog.

PUB SetPWM(Pin,Percent)
  '' This method sets the duty cycle of a pin from 0 to 100 percent.
  '' At 0 percent, pins will be off. At 100 percent pins will be on all the time.

  Percent#>=0                                                                   ' Ensures that the value is not less than 0.
  Percent<#=100                                                                 ' Ensures that the value is not more than 100.
  Percent*=1000000                                                              ' Scales up percent to divide without fractions.
  Percent/=390625                                                               ' Divides percent to transform it into a number from 0-256.
  pwm.duty(pin,percent)                                                         ' Sets the duty cycle for that pin.

PUB StopPWM
  '' This method stops PWM on all pins and frees the PWM cog.

  pwmpinmask:=%0000_0000                                                        ' Resets the pin mask.
  pwm.stop                                                                      ' Stops the PWM cog.

CON
{{
┌────────────────────────────────────────┐
│ Number and String Manipulation Methods │
└────────────────────────────────────────┘
}}
PUB ToStr(Number)
'' Converts a number to a string.

  return numbers.tostr(number)

PUB ToDec(StringAddress)
'' Converts a string to a decimal number.

  return numbers.todec(stringaddress)

CON
{{
┌─────────────────────────────────┐
│ Data and Memory Related Methods │
└─────────────────────────────────┘
}}
PUB Record(State,ID,EventTime)
  '' This method records data.
  '' For inputs, call this method every experiment loop to record data.
  '' For outputs, and manual events call this method ONLY when the event changes states to record data.

  '' States for input: 0-off, 1-onset, 2-on, 3-offset
  '' States for non-input: 1-onset, 3-offset

  if state==1                                                                   ' If it is an onset,
    SD.pputc(ID)                                                                ' Write the ID.
    SD.pputs(string("1",44))                                                    ' Write the onset code and a comma.
    SD.pputs(tostr(eventtime))                                                  ' Write the time.
    SD.pputs(string(44))                                                        ' Write another comma.

  if state==3                                                                   ' If it is an offset,
    SD.pputc(ID)                                                                ' Write the ID.
    SD.pputs(string("3",44))                                                    ' Write the offset code and a comma.
    SD.pputs(tostr(eventtime))                                                  ' Write the time.
    SD.pputs(string(13))                                                        ' Write a line-break.

PUB RecordRawData(RawData,ID,EventTime)
  '' This method saves raw data (integers) provided by the user.
  '' Call this method only when some raw data has been collected.

  SD.pputc(ID)                                                                  ' Write the ID.
  SD.pputs(string("1",44))                                                      ' Write the time code and a comma.
  SD.pputs(tostr(eventtime))                                                    ' Write the time.
  SD.pputs(string(44))                                                          ' Write another comma.

  SD.pputc(ID)                                                                  ' Write the ID.
  SD.pputs(string("3",44))                                                      ' Write the data code and a comma.
  SD.pputs(tostr(rawdata))                                                      ' Write the data.
  SD.pputs(string(13))                                                          ' Write a line-break.

PUB QuickSaveMemory
  '' This method closes and re-opens the memory file to quickly save it.
  '' It may be useful in experiments with longer sessions.

  quicksavecustommemory(string("memory.txt"))

PUB QuickSaveCustomMemory(MemoryFile)
  '' This method closes and re-opens the user-named memory file to quickly save it.
  '' It may be useful in experiments with longer sessions.

  SD.pclose
  SD.popen(Memoryfile,"a")

PUB NewMemoryFile(MemoryFile)
  '' Creates a new memory file without launching the experiment clock.
  '' This can be used after data is saved to start a memory file for a new session.

  SD.popen(Memoryfile,"w")                                                      ' Creates a memory file for writing.

PUB StopExperiment
  '' This method closes the memory file.
  '' This method must be called before saving any data.

  SD.pclose                                                                     ' Closes any open file on SD card, should close memory file.

PUB PrepareDataOutput | Datafile
  '' This method creates and prepares the data output file.
  '' This is used because data writing methods will need to be called multiple times and cannot write the headings.

  Datafile:=string("data.csv")                                                  ' Sets the default datafile name.
  PrepareCustomDataOutput(Datafile)                                             ' Prepares the dataoutput file with the default name.

PUB PrepareCustomDataOutput(DataFile)
  '' This method creates and prepares the data output file.
  '' This is used because data writing methods will need to be called multiple times and cannot write the headings.
  '' User specified data file name allows multiple data files to be written for one experiment.

  '' Note that long file names are not supported. File names can be a maximum of 8 characters, plus a three letter extension.
  '' For example abc.txt or abcdefgh.txt are valid names while abcdefghij.txt is not a valid name.

  SD.popen(datafile,"w")                                                        ' Creates or opens data file for writing. The next line writes the column headings.
  SD.pputs(string("Event,Instance,Onset,Offset,Duration,Inter-Event Interval,Total Duration,Total Occurrences",13))
  SD.pclose

PUB PrepareDataOutputForRawData | Datafile
  '' Adds headings for raw data to the end of a previously prepared data file.
  '' Save raw data LAST if using this methods or the headings will not match.

  Datafile:=string("data.csv")                                                  ' Sets the default datafile name.
  PrepareCustomOutputForRawData(Datafile)                                       ' Prepares the dataoutput file with the default name.

PUB PrepareSeparateRawDataOutput | Datafile
  '' Creates a separate file for raw data measurements.

  Datafile:=string("rawdata.csv")                                               ' Sets the default datafile name.
  PrepareSeparateCustomRawOutput(Datafile)                                      ' Prepares the dataoutput file with the default name.

PUB PrepareCustomOutputForRawData(DataFile)
  '' Adds headings for raw data to the end of a previously prepared data file.
  '' Save raw data LAST if using this methods or the headings will not match.

  '' Note that long file names are not supported. File names can be a maximum of 8 characters, plus a three letter extension.
  '' For example abc.txt or abcdefgh.txt are valid names while abcdefghij.txt is not a valid name.

  SD.popen(datafile,"a")                                                        ' Opens an existing file for writing. The next line writes the column headings.
  SD.pputs(string(13,"Event,Instance,Time,Data,Inter-Event Interval,Total Occurrences",13))
  SD.pclose

PUB PrepareSeparateCustomRawOutput(DataFile)
  '' Creates a separate file for raw data measurements.

  SD.popen(datafile,"w")                                                        ' Creates or opens data file for writing. The next line writes the column headings.
  SD.pputs(string("Event,Instance,Time,Data,Inter-Event Interval,Total Occurrences",13))
  SD.pclose

PUB SaveData(ID,Name) | totaloccurrences, Memoryfile, Datafile
  '' After the experiment ends, use this method to read data from memory, sort it, and save it to the data file.
  '' Call AFTER stopexperiment and preparedataoutput.
  '' There will be problems if it is called before stop experiment.

  Memoryfile:=string("memory.txt")                                              ' Default memory name.
  Datafile:=string("data.csv")                                                  ' Default data name.

  SaveCustomData(ID,Name,Memoryfile,Datafile)                                   ' Saves data with default memory and data names.

PUB SaveCustomData(ID,Name,Memoryfile,Datafile) | totaloccurrences
  '' After the experiment ends, use this method to read data from memory, sort it, and save it to the data file.
  '' Call AFTER stopexperiment and preparedataoutput.
  '' There will be problems if it is called before stop experiment.

  totaloccurrences:=readmemory(memoryfile,ID)                                   ' Run the readmemory method, and save the result as totaloccurrences.

  printdata(name,totaloccurrences,datafile)                                     ' Run the printdata method.

  longfill(@tempdata,-1,2000)                                                   ' Reset the tempdata array with -1s.

PUB SaveRawData(ID,Name) | totaloccurrences, Memoryfile, Datafile
  '' After the experiment ends, use this method to read data from memory, sort it, and save it to the data file.
  '' Call AFTER stopexperiment and preparedataoutput.
  '' There will be problems if it is called before stop experiment.

  Memoryfile:=string("memory.txt")                                              ' Default memory name.
  Datafile:=string("data.csv")                                                  ' Default data name.

  SaveCustomRawData(ID,Name,Memoryfile,Datafile)                                ' Saves data with default memory and data names.

PUB SaveCustomRawData(ID,Name,Memoryfile,Datafile) | totaloccurrences
  '' After the experiment ends, use this method to read data from memory, sort it, and save it to the data file.
  '' Call AFTER stopexperiment and preparedataoutput.
  '' There will be problems if it is called before stop experiment.

  totaloccurrences:=readmemory(memoryfile,ID)                                   ' Run the readmemory method, and save the result as totaloccurrences.

  printrawdata(name,totaloccurrences,datafile)                                  ' Run the printdata method.

  longfill(@tempdata,-1,2000)                                                   ' Reset the tempdata array with -1s.

PUB Shutdown
  '' Unmounts SD card and stops the clock.
  '' Call this method after all the data has been saved.
  '' This method will also create an error file with a description of the error if needed.

  if error==1                                                                   ' If there was an error.
    SD.popen(string("Error.txt"),"w")                                           ' Creates the error file.
    SD.pputs(Errornote)                                                         ' Prints the error note in the file.
    SD.pclose                                                                   ' Closes the file.
  SD.unmount                                                                    ' Unmounts the SD Card.

  Cogstop(ClockCogID)                                                           ' Stops the experiment clock.

PRI ReadMemory(memoryfile,ID) | read, counter, datacounter, slot, totaloccurrences
  '' Iterates through memory.txt, uses ID to save proper data to tempdata.
  '' Returns totaloccurrences.

  '' Onsets that occur before the experiment is ready are properly recorded as 0.
  '' If the experiment ends while an input is activate then offset and duration will be blank and total duration will not factor in that instance.
  '' In that case, some manual data editing will be needed, this appears unavoidable.
  '' Another solution is to check to see if an input was in the ONSET state (1) or ON state (2) after the experiment ends.
  '' If it was considered and ONSET or ON at the end of the experiment, you can manually record an OFFSET (3) after the experiment ends.

  '' Example use in a program:
  ''    repeat until exp.time(start) > sessionlength
  ''      exp.record(input1.detect, input1state, exp.time(start))
  ''    if input1.state==1 or input1.state==2
  ''      exp.record(input1.ID,3,exp.time(start))

  read:=0                                                                       ' The value of the current character being read from the file.
  counter:=0                                                                    ' A counter used to keep track of how many characters are contained in "data."
  datacounter:=0                                                                ' Keeps track of where in the tempdata array the program is.
  slot:=-1                                                                      ' Determines where in the array data is written. 0-writes to the onset slot, 1-writes to the offset slot.
  totaloccurrences:=0                                                           ' Total occurrences of the behavior.

  SD.popen(memoryfile,"r")                                                      ' Open the memory file.

  repeat
    if datacounter > 1998                                                       ' If the end of the tempdata array has been reached.
      read:=SD.pgetc                                                            ' Get the next character in the file.
      if read > -1                                                              ' If this isn't the end of the file.
        Error:=1                                                                ' The next line sets an error note that will be printed in an error file.
        ErrorNote:=string("Error: Too many instances of behavior. Only the first 1000 instances of behavior will be saved. Use the python program to further process the memory file.")
        Quit                                                                    ' Quit reading data - first 1000 instances will be saved. The rest will need to be recovered with a python script.
    read:=SD.pgetc                                                              ' Get the next character in the file.
    case read                                                                   ' Look at the character.
      -1:                                                                       ' If there is nothing there, quit looking at the file.
        Quit
      ID:                                                                       ' If the character is the ID of the event that is being saved.
        read:=SD.pgetc                                                          ' Read the next character.
          case read                                                             ' Look at the character.
             49:                                                                ' If it is a 1 (onset).
                if slot == 0                                                    ' If the last item written was an onset - This can be caused by some bug in hardware or software.
                   datacounter+=2                                               ' Move to the next slot, no offset will be written.
                slot:=0                                                         ' Make sure slot is 0, this is used to determine where in the tempdata array to save the data.
                totaloccurrences++                                              ' It was an onset, so add 1 to totaloccurrences.
             51:                                                                ' If it is a 3 (offset).
                if slot == 1                                                    ' If the last item written was an offset - This can be caused by some bug in hardware or software.
                   totaloccurrences++                                           ' Note that it is another occurrence of behavior
                slot:=1                                                         ' It is an offset, so make sure slot is 1.

          read:=SD.pgetc                                                        ' Now get the next character, it will be a comma, so we won't do anything with it.
          repeat
             read:=SD.pgetc                                                     ' Now get the next character.
             case read                                                          ' Look at the character.
                44,13:                                                          ' If it is a comma or line-break.
                   tempdata[datacounter+slot]:=todec(@data)                     ' Then put all the data that was read into the tempdata array. If it was an onset, it goes at the current space, if it is an offset it goes at the space+slot, or one slot over.
                   bytefill(@data,0,counter)                                    ' Now that the data is written, reset the data to all zeros.
                   counter:=0                                                   ' Reset the counter.
                   if slot==1                                                   ' If the slot was 1, an offset was written.
                      datacounter+=2                                            ' Since an offset was written, increase the datacounter to the next instance of behavior.
                   Quit                                                         ' Now quit this repeat loop, but still go back to the main repeat look to look for more data.
                48..57:                                                         ' If the next character is a number.
                   data[counter]:=read                                          ' Add that value to data. This makes a string.
                   counter++                                                    ' Increase the counter.
      NOT ID:                                                                   ' If the value read was not the ID of the event that was being saved.
        read:=SD.pgetc                                                          ' See what the next character is.
  SD.pclose                                                                     ' Close the memory file when everything is done.

  return totaloccurrences                                                       ' Return totaloccurences to whatever variable called the method.

PRI PrintData(Name,Totaloccurrences,datafile) | counter, datacounter, totalduration, continue
  '' Iterates though tempdata array, adds duration to the array, computes total duration, then prints to the data file.

  counter:=0                                                                    ' Used to keep track of how many instances have been written.
  datacounter:=0                                                                ' Determines where in the array data is read or written.
  totalduration:=0                                                              ' Sum of the duration of every instance.

  '' Calculates totalduration.
  repeat until (tempdata[datacounter]+tempdata[datacounter+1])==-2 or datacounter>1998
                                                                                ' Repeat until there is a -1 in the onset and offset slot being searched. This means there is no more data in the array.
                                                                                ' Also quit if the end of the data array is reached.
    if tempdata[datacounter] > -1 and tempdata[datacounter+1] > -1              ' If there is an onset and offset in this instance of behavior.
      totalduration+=tempdata[datacounter+1]-tempdata[datacounter]              ' Subtract the offset from the onset to produce duration and add it to the total duration.
    datacounter+=2                                                              ' Go to the next instance of behavior.

  '' Prints data to user specified data file.
  counter:=1                                                                    ' Set to one because the program starts with the first instance.
  datacounter:=0                                                                ' Resets the datacounter.
  SD.popen(datafile,"a")                                                        ' Opens the data file for appending. This way the file headers, or previous data are not overwritten.
  repeat until (tempdata[datacounter]+tempdata[datacounter+1])==-2 or datacounter>1998
                                                                                ' Repeat until there is a -1 in the onset and offset slot being searched. This means there is no more data in the array.
                                                                                ' Also quit if the end of the data array is reached.
    SD.pputs(name)                                                              ' Write the event name to the file.
    SD.pputc(44)                                                                ' Write a comma. This will cause the data file to jump to the next column.
    SD.pputs(tostr(counter))                                                    ' Write the instance of the event.
    SD.pputc(44)                                                                ' Write a comma.
    writeseconds(tempdata[datacounter])                                         ' Use the writeseconds method to write the onset.
    SD.pputc(44)                                                                ' Write a comma.
    if tempdata[datacounter+1]==-1                                              ' If there is not data in the offset slot.
      SD.pputc(44)                                                              ' Write a comma to leave that column blank.
    else                                                                        ' If there is data in the offset slot.
      writeseconds(tempdata[datacounter+1])                                     ' Use the writeseconds method to write the offset.
      SD.pputc(44)                                                              ' Write a comma.
    if tempdata[datacounter]==-1 or tempdata[datacounter+1]==-1                 ' If a duration cannot be computed.
      SD.pputc(44)                                                              ' Write a comma to leave that column blank.
    else                                                                        ' If a duration can be computed.
      writeseconds(tempdata[datacounter+1]-tempdata[datacounter] )              ' Use the writeseconds method to write the duration.
      SD.pputc(44)                                                              ' Write a comma.
    if datacounter==0                                                           ' If this is the first instance of an event.
      SD.pputc(48)                                                              ' No IEI can be written, so write a zero.
      SD.pputc(44)                                                              ' Write a comma.
    elseif tempdata[datacounter]==-1 or tempdata[datacounter+1]==-1             ' If an IEI cannot be computed.
      SD.pputc(44)                                                              ' Write a comma.
    else                                                                        ' If the IEI can be calculated.
      writeseconds(tempdata[datacounter]-tempdata[datacounter-1] )              ' Use the writeseconds method to write the IEI.
      SD.pputc(44)                                                              ' Write a comma.
    writeseconds(totalduration)                                                 ' Use the writeseconds method to write the total duration.
    SD.pputc(44)                                                                ' Write a comma.
    SD.pputs(tostr(totaloccurrences))                                           ' Write the total number of occurrences.
    SD.pputc(13)                                                                ' Write a carriage return to go to the next row and back to the first column.
    datacounter+=2                                                              ' Increase the data counter to look at the next instance of behavior.
    counter++                                                                   ' Increase the counter.
  SD.pclose

PRI PrintRawData(Name,Totaloccurrences,datafile) | counter, datacounter, continue
  '' Prints the raw data to the data file.

  counter:=0                                                                    ' Used to keep track of how many instances have been written.
  datacounter:=0                                                                ' Determines where in the array data is read or written.

  '' Prints data to user specified data file

  counter:=1                                                                    ' Set to one because the program starts with the first instance.
  datacounter:=0                                                                ' Resets the datacounter.
  SD.popen(datafile,"a")                                                        ' Opens the data file for appending. This way the file headers, or previous data are not overwritten.
  repeat until (tempdata[datacounter]+tempdata[datacounter+1])==-2 or datacounter>1998
                                                                                ' Repeat until there is a -1 in the onset and offset slot being searched. This means there is no more data in the array.
                                                                                ' Also quit if the end of the data array is reached.
    SD.pputs(name)                                                              ' Write the event name to the file.
    SD.pputc(44)                                                                ' Write a comma. This will cause the data file to jump to the next column.
    SD.pputs(tostr(counter))                                                    ' Write the instance of the event.
    SD.pputc(44)                                                                ' Write a comma.
    writeseconds(tempdata[datacounter])                                         ' Use the writeseconds method to write the time.
    SD.pputc(44)                                                                ' Write a comma.
    SD.pputs(tostr((tempdata[datacounter+1])))                                  ' Write the data value.
    SD.pputc(44)                                                                ' Write a comma.
    if datacounter>0                                                            ' As long as this isn't the first instance.
      SD.pputs(writeseconds(tempdata[datacounter]-tempdata[datacounter-2]))     ' Calculate and write the IEI.
      SD.pputc(44)                                                              ' Write a comma.
    else                                                                        ' If it is the first instance.
      SD.pputc(44)                                                              ' Write a comma.
    SD.pputs(tostr(totaloccurrences))                                           ' Write the total number of occurrences.
    SD.pputc(13)                                                                ' Write a carriage return to go to the next row and back to the first column.
    datacounter+=2                                                              ' Increase the data counter to look at the next instance of behavior.
    counter++                                                                   ' Increase the counter.
  SD.pclose

PRI WriteSeconds(milliseconds) | integer, decimal
  '' This method converts milliseconds to seconds with a decimal fraction and writes to the data output file.
  '' Example: writeseconds(1234)=="1.234"
  '' The current method maybe be sub-optimal.

  if milliseconds < 0                                                           ' If the value is less than zero.
    SD.pputc(32)                                                                ' Leave the field blank.

  else
    integer:=milliseconds / 1000                                                ' Whole seconds.
    SD.pputs(tostr(integer))                                                    ' Write whole seconds to the file.
    decimal:=milliseconds // 1000                                               ' Milliseconds.
    decimal:=tostr(decimal)                                                     ' Convert it to a string to make it easier to examine.
    SD.pputc(46)                                                                ' Writes the decimal point.

    case byte[decimal][1]                                                       ' Looks at the second value in the decimal string.
      48..57:                                                                   ' Is it a number?
        case byte[decimal][2]                                                   ' Then look at the third value in the decimal string.
          48..57:                                                               ' Is it a number?
             SD.pputs(decimal)                                                  ' Then the decimal string is 3 digits, so write it to the file.
          other:                                                                ' The second value is a number, but the third isn't.
             SD.pputc(48)                                                       ' Then it is a two digit string, add a zero.
             SD.pputs(decimal)                                                  ' Then write the decimal string.
      other:                                                                    ' The the second value is not a number.
        SD.pputc(48)                                                            ' Then it is a one digit string, add a zero.
        SD.pputc(48)                                                            ' Add another zero.
        SD.pputs(decimal)                                                       ' Write the decimal string.

DAT
'' This data array is used for sorting and processing the memory file.
'' It can hold 1000 instances of a behavior.

'' In tempdata: 0-onset, 1-offset
'' To data file: name, instance, 0-onset, 1-offset, duration, inter-event interval, total duration, total occurrences.

'' The format is slightly different when processing raw data.
'' In tempdata: 0-time, 1-data
'' To data file: name, instance, 0-time, 1-data, inter-event interval, total occurrences.

tempdata      LONG      -1[2000]                                                ' All values set to -1 initially to let the program determine when the array is empty

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