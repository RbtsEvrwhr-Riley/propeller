'
' SNEcog demonstartion.
' A minimalistic and stupid play routine playing a stupid little tune. ;)
 
CON _clkmode = xtal1 + pll16x
    _xinfreq = 5_000_000    

    playRate = 21 'Hz
    rightPin = 10  
    leftPin  = 11

VAR
  long volume[3]
  
OBJ
  SN : "SNEcog"

PUB Main | i, note, channel, musicPointer

  sn.start(rightPin, leftPin, false)            ' Start the emulated SN chip in one cog. DONT use shadow registers
 
  musicPointer := -1
  repeat
    waitcnt(cnt + (clkfreq/playRate))
    repeat channel from 0 to 2
      note := music[++musicPointer]             ' Get note

      if note == 255                            ' Restart tune if note = 255   
        note := music[musicPointer := 0]
        
      if note                                   ' Note on if note > 0
      
        ifnot channel == 1                      ' Handle bass and lead tone (channel 1 and 3)
          volume[channel] := 15
          sn.setFreq(channel, note2freq(note-30))
         
        else                                    ' Handle drum (channel 4)
          volume[3] := 15
          sn.setFreq(3, note)

    repeat channel from 0 to 3                  ' Handle amplitude decay 
      if (volume[channel] -= 2) < 0                  
        volume[channel] := 0
      sn.setVolume(channel, (15-volume[channel]))
                   
PUB note2freq(note) | octave
    octave := note/12
    note -= octave*12 
    return (noteTable[note]>>octave)

DAT
noteTable word 3087, 2914, 2750, 2596, 2450, 2312, 2183, 2060, 1945, 1835, 1732, 1635 
                            
DAT
               'Ch1,Ch4,Ch3 

music     byte  50,  0 , 0 
          byte  50,  0 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  0 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  0 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0 
                         
          byte  55,  0 , 0 
          byte  55,  0 , 0 
          byte  55,  0 , 0 
          byte  0 ,  0 , 0 
          byte  55,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  65,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  55,  0 , 0 
          byte  55,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  55,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  65,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  55,  0 , 0 
          byte  55,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0 
          byte  55,  0 , 0 
          byte  0 ,  0 , 0 
                         
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  0 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  0 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0 

          byte  60,  0 , 0 
          byte  60,  0 , 0 
          byte  60,  0 , 0 
          byte  0 ,  0 , 0 
          byte  60,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  67,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  60,  0 , 0 
          byte  60,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  55,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  67,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  55,  0 , 0 
          byte  55,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  67,  0 , 0 
          byte  0 ,  0 , 0 
          byte  67,  0 , 0 
          byte  0 ,  0 , 0 
'------------------------------------  
          byte  50,  6, 0 
          byte  50,  0,  0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  4, 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  0 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  6, 0 
          byte  0 ,  0,  0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  6, 0 
          byte  0 ,  0,  0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  4,  0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0 
                         
          byte  55,  6, 0 
          byte  55,  0,  0 
          byte  55,  0 , 0 
          byte  0 ,  0 , 0 
          byte  55,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  65,  4 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  55,  0 , 0 
          byte  55,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  55,  6, 0 
          byte  0 ,  0,  0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  65,  6, 0 
          byte  0 ,  0,  0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  55,  4 , 0 
          byte  55,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  4 , 0 
          byte  0 ,  0 , 0 
          byte  55,  4 , 0 
          byte  0 ,  0 , 0 
                         
          byte  50,  6, 0 
          byte  0 ,  0,  0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  4 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  0 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  6, 0 
          byte  0 ,  0,  0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  6, 0 
          byte  0 ,  0,  0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  50,  4 , 0 
          byte  50,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0 

          byte  60,  6, 0 
          byte  60,  0,  0 
          byte  60,  0 , 0 
          byte  0 ,  0 , 0 
          byte  60,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  67,  4 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  60,  0 , 0 
          byte  60,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  55,  6, 0 
          byte  0 ,  0,  0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  67,  0 , 0 
          byte  0 ,  0 , 0 
          byte  0 ,  6, 0 
          byte  0 ,  0 , 0 
          byte  55,  4 , 0 
          byte  55,  0 , 0 
          byte  0 ,  6, 0 
          byte  0 ,  0 , 0 
          byte  67,  4 , 0 
          byte  0 ,  0 , 0 
          byte  67,  4 , 0 
          byte  0 ,  0 , 0         
'------------------------------------ 
          byte  50,  6, 0  
          byte  50,  0,  0  
          byte  50,  0 , 0  
          byte  0 ,  0 , 0  
          byte  50,  0 , 0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  62,  4 , 86 
          byte  0 ,  0 , 86 
          byte  0 ,  0 , 86 
          byte  0 ,  0 , 86 
          byte  50,  0 , 0 
          byte  50,  0 , 0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  50,  6, 86 
          byte  0 ,  0,  86 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0 
          byte  62,  6, 93 
          byte  0 ,  0,  93 
          byte  0 ,  0 , 93 
          byte  0 ,  0 , 93 
          byte  50,  4 , 93 
          byte  50,  0 , 93 
          byte  0 ,  0 , 93 
          byte  0 ,  0 , 93 
          byte  62,  0 , 93 
          byte  0 ,  0 , 93 
          byte  62,  0 , 0  
          byte  0 ,  0 , 0  
                           
          byte  55,  6, 79 
          byte  55,  0,  79 
          byte  55,  0 , 79 
          byte  0 ,  0 , 79 
          byte  55,  0 , 79 
          byte  0 ,  0 , 79 
          byte  0 ,  0 , 79 
          byte  0 ,  0 , 79 
          byte  65,  4 , 0 
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  55,  0 , 0  
          byte  55,  0 , 0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  55,  6, 77 
          byte  0 ,  0,  77 
          byte  0 ,  0 , 77 
          byte  0 ,  0 , 77 
          byte  65,  6, 77 
          byte  0 ,  0,  77 
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  55,  4 , 83 
          byte  55,  0 , 83 
          byte  0 ,  0 , 83 
          byte  0 ,  0 , 83 
          byte  62,  4 , 0  
          byte  0 ,  0 , 0  
          byte  55,  4 , 0 
          byte  0 ,  0 , 0  
                         
          byte  50,  6, 81 
          byte  0 ,  0,  81 
          byte  50,  0 , 81 
          byte  0 ,  0 , 81 
          byte  50,  0 , 81 
          byte  0 ,  0 , 81 
          byte  0 ,  0 , 81 
          byte  0 ,  0 , 81 
          byte  62,  4 , 81 
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  50,  0 , 79 
          byte  50,  0 , 79 
          byte  0 ,  0 , 79 
          byte  0 ,  0 , 79 
          byte  50,  6, 0  
          byte  0 ,  0,  0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  62,  6, 77 
          byte  0 ,  0,  77 
          byte  0 ,  0 , 77 
          byte  0 ,  0 , 77 
          byte  50,  4 , 0  
          byte  50,  0 , 0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  62,  0 , 84 
          byte  0 ,  0 , 84 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0  

          byte  60,  6, 86 
          byte  60,  0,  86 
          byte  60,  0 , 86 
          byte  0 ,  0 , 86 
          byte  60,  6, 86 
          byte  0 ,  0,  86 
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  67,  4 , 86 
          byte  0 ,  0 , 86 
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0 
          byte  60,  0 , 0  
          byte  60,  0 , 0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  55,  6, 89 
          byte  0 ,  0,  89 
          byte  0 ,  0 , 89 
          byte  0 ,  0 , 89 
          byte  67,  0 , 0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  55,  4 , 88 
          byte  55,  0 , 88 
          byte  0 ,  6, 88 
          byte  0 ,  0 , 88 
          byte  67,  4 , 88 
          byte  0 ,  0 , 88 
          byte  67,  4 , 88 
          byte  0 ,  0 , 88 

'------------------------------------------
          byte  50,  6, 88 
          byte  50,  0,  88 
          byte  50,  0 , 0  
          byte  0 ,  0 , 0  
          byte  50,  0 , 81 
          byte  0 ,  0 , 81 
          byte  0 ,  0 , 81 
          byte  0 ,  0 , 81 
          byte  62,  4 , 90 
          byte  0 ,  0 , 89 
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  50,  0 , 81 
          byte  50,  0 , 81 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0  
          byte  50,  6, 89 
          byte  0 ,  0,  88 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0  
          byte  62,  6, 89 
          byte  0 ,  0,  89 
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0 
          byte  50,  4 , 81 
          byte  50,  0 , 81 
          byte  0 ,  0 , 81 
          byte  0 ,  0 , 81 
          byte  62,  0 , 81 
          byte  0 ,  0 , 81 
          byte  62,  0 , 0 
          byte  0 ,  0 , 0 
                         
          byte  55,  6, 84 
          byte  55,  0,  84 
          byte  55,  0 , 84 
          byte  0 ,  0 , 84 
          byte  55,  0 , 84 
          byte  0 ,  0 , 84 
          byte  0 ,  0 , 84 
          byte  0 ,  0 , 84 
          byte  65,  4 , 84 
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0 
          byte  55,  0 , 0  
          byte  55,  0 , 0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0 
          byte  55,  6, 83 
          byte  0 ,  0,  83 
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0 
          byte  65,  6, 0  
          byte  0 ,  0,  0 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0  
          byte  55,  4 , 79 
          byte  55,  0 , 79 
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  62,  4 , 0 
          byte  0 ,  0 , 0  
          byte  55,  4 , 0  
          byte  0 ,  0 , 0  
                         
          byte  50,  6, 86 
          byte  0 ,  0,  86                                                                                   '
          byte  50,  0 , 86 
          byte  0 ,  0 , 86 
          byte  50,  0 , 86 
          byte  0 ,  0 , 86 
          byte  0 ,  0 , 86 
          byte  0 ,  0 , 86 
          byte  62,  4 , 86 
          byte  0 ,  0 , 86 
          byte  0 ,  0 , 86 
          byte  0 ,  0 , 86 
          byte  50,  0 , 0  
          byte  50,  0 , 0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  50,  6, 0  
          byte  0 ,  0,  0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  62,  6, 82 
          byte  0 ,  0,  81 
          byte  0 ,  0 , 81 
          byte  0 ,  0 , 81 
          byte  50,  4 , 0  
          byte  50,  0 , 0  
          byte  0 ,  0 , 8  
          byte  0 ,  0 , 79 
          byte  62,  0 , 79 
          byte  0 ,  0 , 79 
          byte  62,  0 , 0  
          byte  0 ,  0 , 0  

          byte  60,  6, 82 
          byte  60,  0,  81 
          byte  60,  0 , 81 
          byte  0 ,  0 , 81 
          byte  60,  6, 81 
          byte  0 ,  0,  0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  67,  4 , 84 
          byte  0 ,  0 , 84 
          byte  0 ,  0 , 0 
          byte  0 ,  0 , 0  
          byte  60,  0 , 8  
          byte  60,  0 , 79 
          byte  0 ,  0 , 79 
          byte  0 ,  0 , 79 
          byte  55,  6,  0  
          byte  0 ,  0,  0  
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  67,  0 , 79 
          byte  0 ,  0 , 79 
          byte  0 ,  0 , 0  
          byte  0 ,  0 , 0  
          byte  55,  4 , 77 
          byte  55,  0 , 77 
          byte  0 ,  6,  0  
          byte  0 ,  0 , 0  
          byte  67,  4 , 72 
          byte  0 ,  0 , 72 
          byte  67,  4 , 72 
          byte  0 ,  0 , 72 
        
          byte  255' Song end
           