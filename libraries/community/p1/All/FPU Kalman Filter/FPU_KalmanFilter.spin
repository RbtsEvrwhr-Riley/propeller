{{
┌────────────────────────────┬─────────────────────┬─────────────────────┐
│ FPU_KalmanFilter.spin v2.0 │  Author: I.Kövesdi  │ Rel.: 27 April 2009 │
├────────────────────────────┴─────────────────────┴─────────────────────┤
│                    Copyright (c) 2009 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│  Assuming that a discrete linear time-invariant system has n states, m │
│ inputs and r outputs, this application provides the user a general     │
│ coding framework of standard Time-Varying Kalman filter using the      │
│ following notations and definitions:                                   │
│                                                                        │
│         x(k+1) = A * x(k) + B * u(k) + w(k)   State equation           │
│                                                                        │
│           y(k) = C * x(k) + z(k)              Measurement equation     │
│                                                                        │
│ where                                                                  │
│                                                                        │
│     x is a [n-by-1] vector  Estimated state vector                     │
│     k is the time index                                                │   
│     A is a [n-by-n] matrix  System model matrix                        │ 
│     B is a [n-by-m] matrix  State control matrix                       │ 
│     u is a [m-by-1] vector  Known control input to the system          │
│     w                       Process noise, only its statistics known.  │
│                             It is "calculated" only during simulations.│
│                             In real applications it is just a notation │
│                             to remind us that it might be there. We    │
│                             don't have to program it within the filter.│
│     y is a [r-by-1] vector  Measured output, i.e. sensor readings      │
│     C is a [r-by-n] vector  Measurement model matrix                   │
│     z                       Measurement noise, only its statistics     │
│                             known. It is "calculated" only during      │
│                             simulations. In real filtering we do       │
│                             not have to calculate it. Nature will      │
│                             generate it for us.                        │
│                                                                        │
│ The w and z noise vectors are described by their covariance matrices:  │
│                                                                        │ 
│    Sw is a [n-by-n] matrix  Process noise covariance matrix            │
│    Sz is a [r-by-r] matrix  Measurement noise covariance matrix        │
│                                                                        │
│ that are the expected values of the corresponding covariance products: │
│                                                                        │
│    Sw = E[w(k) * wT(k)]     Estimated and fixed before calculation     │
│    Sz = E[z(k) * zT(k)]     Estimated and fixed before calculation     │
│                                                                        │
│ From these we can setup the Kalman filter equations:                   │
│                                                                        │
│    K(k) = A * P(k) * CT * Inv[C * P(k) * CT + Sz]                      │
│                                                                        │
│  x(k+1) = [A * x(k) + B * u(k)] + K(k) * [y(k) - C * x(k)]             │
│           -------1st term------   ---------2nd term-------             │
│                                                                        │
│  P(k+1) = A * P(k) * AT + Sw - A * P(k) * CT * Inv(Sz) * C * P(k) * AT │
│                                                                        │
│ where                                                                  │
│                                                                        │
│           K(k)   [n-by-r] Kalman gain matrix                           │
│           P(k)   [n-by-n] estimation error covariance matrix           │
│                                                                        │
│  The second, so called "State Estimate Equation" is fairly intuitive.  │
│ The first                                                              │ 
│                                                                        │ 
│                    [system model predicted x(k+1)]                     │
│                                                                        │
│ term would be the state estimate if we didn't have a measurement. The  │
│ second                                                                 │
│                                                                        │
│        K(k)*[measured y(k) - measurement model defined y(k)]           │
│                                                                        │
│ term is called the correction term and it represents the amount by     │
│ which to correct the propagated state estimate due to measurement.     │
│  Inspection of the first "K" equation shows that if the measurement    │
│ noise is large, Sz is large, so K will be small since it is            │
│ proportional to                                                        │
│                                                                        │
│          Inv(C * P(k) * CT + Sz) = 1 / (C * P(k) * CT + Sz)            │
│                                                                        │
│ with Sz in the denominator. If K is small we won't give much credence  │
│ to the measurement y(k) when computing x(k+1). On the other hand, if   │
│ the measurement noise is small then Sz is small, so K will be larger.  │
│ We will give then a lot of credibility to the measurement.             │
│  The third "P" equation updates the estimation error covariance which's│
│ evolution in time is not influenced by the states and the measurements.│
│ This decoupled evolution applies to the K Kalman gain matrix, as well. │ 
│  During the computation of this so called time-varying Kalman filter we│
│ have to compute the inverse of an [r-by-r] matrix in the "K" equation. │
│ In the "P" equation CT * INV(Sz) * C is a constant matrix, so we have  │
│ to compute it only once for all later calculations. In each k step the │
│ A * P(k) product can be used three times.  Even after all these tricks │
│ the calculation involves a lot of matrix algebra where the calls of the│
│ procedures of the "FPU_Matrix_Driver" came in very handy.              │
│  If our judgment of the Sw and Sz constant matrices are not correct or │
│ we face unpredictable noise sources during the run, then the filtering │
│ results will be suboptimal. Kalman filters usually work reasonably well│
│ even in these cases. However it is not a good practice to rely heavily │
│ on the robustness of the algorithm. It is much better to model the     │
│ noise in the system accurately.                                        │
│                                                                        │  
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  Perhaps the most famous application of Kalman filters to date was     │
│ guiding the Apollo spacecraft to the Moon. Rocket engineers have to    │
│ reconcile a spacecraft's current sensor readings with differential     │
│ equations that tell them where it ought to be, based on their knowledge│
│ of its past. When the designers of Apollo needed a way to blend these  │
│ two sources of information, they found it in Kalman filters that were  │
│ actually developed for those missions. Since then, the Kalman filter   │
│ became a reliable computational workhorse of inertial guidance systems │
│ for airplanes and spacecrafts. During the last three decades it has    │
│ found other applications in hundreds of diverse areas, including all   │
│ forms of navigation, manufacturing, demographic modeling, nuclear plant│
│ instrumentation, robotics, weather prediction, just to mention a few.  │
│  The idea behind Kalman filters can be tracked back to least-squares   │
│ estimation theory by (K)arl (F)riedrich Gauss. With his words:         │
│                                                                        │
│ "...But since all our measurements and observations are nothing more   │
│ than approximations to the truth, the same must be true for all        │
│ calculations resting upon them, and the highest aim of all computations│
│ concerning concrete phenomena must be to approximate, as nearly as     │
│ practicable, to the truth. ... This problem can only be properly       │
│ undertaken when approximate knowledge has been already attained, which │
│ is afterwards to be corrected so as to satisfy all the observations in │
│ the most accurate manner possible."                                    │
│                                                                        │
│ These ideas, which capture the essential ingredients of all data       │
│ processing methods, were incarnated in modern form as Kalman filters   │
│ when, following similar work of Peter Swerling, Rudolph Kálmán         │
│ developed the algorithm. Sometimes the filter is referred to as the    │
│ Kalman-Bucy filter because of Richard Bucy's early work on the topic,  │
│ conducted jointly with Kálmán.                                         │
│  If you have two measurements x1, and x2 of an unknown variable x, what│
│ combination of x1 and x2 gives you the best estimate of x? The answer  │
│ depends on how much uncertainty you expect in each of the measurements.│
│ Statisticians usually measure uncertainty with the variances sigma1    │
│ squared and sigma2 squared. It can be shown, then, that the combination│
│ of x1 and x2 that gives the least variance is                          │
│                                                                        │
│   xhat = [(sigma2^2)*x1 + (sigma1^2)*x2] / [(sigma2^2) + (sigma1^2)]   │
│                                                                        │
│ This result can be figured out, or at least accepted, with common sense│
│ without algebra. The larger the variance of x2 the larger is the weight│
│ we give to x1 in the weighted average. In Kalman filters the first     │
│ measurement, x1, comes from sensor data, and the second "measurement"  │
│ is not really a measurement at all: It is your last forecast of the    │
│ spacecraft's trajectory. In real, e.g. life-saving situations these    │
│ measurements are usually not single numbers, but array of numbers, i.e.│
│ vectors. In the case of the Apollo spacecraft, the vectors had a few   │
│ tens of components. In our demo application here we will use a simpler │
│ device, a bicycle but with a modern GPS, to illustrate Kalman filtering│
│ with commanded acceleration and noisy sensor data fusion with state    │
│ prediction. The coding is based on the FPU_Matrix_Driver.spin object,  │
│ which allows us to construct Kalman filters that apply vectors up to 11│
│ components and can use [11-by-11] matrices. In the famous book of      │
│ Robert M. Rogers "Applied Mathematics in Integrated Navigation Systems,│
│ Second Edition" (AIAA) the largest matrix you can find is a [13-by-13] │                                          
│ one at a single occasion (as a theoretical summary of error state      │
│ dynamics of INU fine alignments including even time-correlated         │
│ accelerometer error states). But all of the worked out and in-practice │
│ demonstrated  algorithms in that book, before and after this matrix,   │
│ use smaller than [11-by-11] matrices and vectors.                      │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  There are many mathematically equivalent ways of writing the Kalman   │
│ filter equations. This can be a pretty effective source of confusion to│
│ novice and veteran alike. The coded version is a so called prediction  │
│ form of the Kalman filter equations where x(k+1) is estimated on the   │
│ basis of the measurements up to and including time k. It can be found  │
│ for example in Embedded System Programming June and in 2001, Embedded  │
│ Systems Design June 2006 by Dan Simon.                                 │ 
│  Note that the "K" and "P" equations do not contain x or y values. In  │ 
│ other words they seem to be independent from the states of the system  │
│ and from the measurements. They are, of course, not totally independent│
│ since the value of deltaT influences the P(0), K(0) starting values of │
│ the matrices. Anyhow, we can compute the Kalman gain matrix K(k) off   │
│ line until we see it converges to a constant matrix. Then we can hard  │
│ code that constant matrix into the "State Estimate Equation". The      │
│ result is called the "Steady-State" Kalman filter. We then save a lot  │
│ of computational resources by using the steady-state version of the    │
│ filter. In many cases, the drop of performance will be negligible when │
│ compared to the Time-Varying Kalman filter. The Steady-State Kalman    │
│ filter algorithm is programmed in the "FPU_SteadyStateKF.spin"         │
│ application in this "FPU_Matrix_Driver" demonstration package release. │
│                                                                        │ 
└────────────────────────────────────────────────────────────────────────┘

Hardware:
 
                                           3.3V
                                            │
    │                               4.7K    │        
   P├A3─────────────────────────┳─────────┫  
   X│                           │           │
   3├A4─────────────────┐       │           │
   2│                   │       │           │ 
   A├A5────┳─────┐      │       │           │
    │      │     │      │       │           │
           │  ┌──┴──────┴───────┴──┐        │                               
         1K  │SIN12  SCLK16  /MCLR│        │                  
           │  │                    │        │
           │  │                AVDD├────────┫       
           └──┤SOUT11           VDD├────────┘
              │                    │         
              │     uM-FPU 3.1     │
              │                    │         
           ┌──┤CS                  │         
           ┣──┤SERIN9              │             
           ┣──┤AVSS                │         
           ┣──┤VSS                 │         
           ┴  └────────────────────┘
          GND

The CS pin of the FPU is tied to LOW to select SPI mode at Reset and must
remain LOW during operation. For this Demo the 2-wire SPI connection was
used, where the SOUT and SIN pins were connected through a 1K resistor and
the A5 pin(6) of the Propeller was connected to the SIN(12) of the FPU.
}}


CON

_CLKMODE = XTAL1 + PLL16X
_XINFREQ = 5_000_000

'Hardware
'_FPU_MCLR    = 0                     'PROP pin to MCLR pin of FPU
'_FPU_CLK     = 1                     'PROP pin to SCLK pin of FPU 
'_FPU_DIO     = 2                     'PROP pin to SIN(-1K-SOUT) of FPU

_FPU_MCLR    = 3                     'PROP pin to MCLR pin of FPU
_FPU_CLK     = 4                     'PROP pin to SCLK pin of FPU 
_FPU_DIO     = 5                     'PROP pin to SIN(-1K-SOUT) of FPU

_FLOAT_SEED  = 0.31415927            'Change this (from [0,1]) to run 
                                     'the demo with other pseudorandom
                                     'data
'_FLOAT_SEED  = 0.27182818
                                     
'Debug
_DBGDEL      = 40_000_000
'_DBGDEL      = 20_000_000

'Dimensions of the linear system
_N             = 2                   'States  (Max. 11)
_M             = 1                   'Inputs  (Max. 11) 
_R             = 1                   'Outputs (Max. 11) 


OBJ

DBG     : "FullDuplexSerialPlus"   'From Parallax Inc.
                                   'Propeller Education Kit
                                   'Objects Lab v1.1
                                   
FPUMAT  : "FPU_Matrix_Driver"      'v2.0


VAR

LONG  fpu3

LONG  cog_ID

LONG  debugLevel

LONG  rnd                    'Global random variable 
LONG  deltaT                 'Time step
LONG  time                   'Time

'I deliberatly will not be very parsimonious with HUB memory in the 
'followings to make the coding more trackable and easier to DBG. Most
'of the next allocated matrices and vectors are recyclable but I leave
'this memory optimization to the user when she/he tailors this general
'coding framework to a given application

'Constant matrices
LONG         mA[_N * _N]     'System model matrix
LONG         mB[_N * _M]     'State control matrix
LONG         mC[_R * _N]     'Measurement model matrix
LONG        mSw[_N * _N]     'Process noise covariance matrix
LONG        mSz[_R * _R]     'Measurement noise covariance matrix

'Pre-calculated constant matrices
LONG        mAT[_N * _N]     'Transpose of mA
LONG        mCT[_N * _R]     'Transpose of mC
LONG     mSzInv[_R * _R]     'Inverse of Sz
LONG    mSzInvC[_R * _N]     'SzInv * C
LONG  mCTSzInvC[_N * _N]     'The factor of CT * INV(Sz) * C

'Time varying vectors  
LONG         vX[_N]          'Estimate of state vector
LONG     vXtrue[_N]          'Hypotetic "true" state vector used only
                             'in simulations
LONG         vU[_M]          'Input vector
LONG         vY[_R]          'Measurement vector

LONG vProcNoise[_N]          'Process noise vector for simulations
LONG vMeasNoise[_R]          'Measurement noise vector for simulations 

'Time varying matrices
LONG         mK[_N * _R]     'Kalman gain matrix
LONG        mKp[_N * _R]     'Previous step Kalman gain matrix
LONG         mP[_N * _N]     'Estimation error covariance matrix

'Matrices and vectors created during Kalman filtering algorithm  
'In the calculation of the next Kalman gain matrix K(k+1)
LONG        mAP[_N * _N]
LONG      mAPCT[_N * _R]
LONG        mCP[_R * _N]
LONG      mCPCT[_R * _R]
LONG    mCPCTSz[_R * _R]
LONG mCPCTSzInv[_R * _R]

'In the calculation of the next state estimate x(k+1)
LONG        vCx[_R]
LONG       vyCx[_R]
LONG      vKyCx[_N]
LONG        vAx[_N]
LONG        vBu[_N]
LONG      vAxBu[_N]
 
'In the calculation of the new estimation error covariance matrix P(k+1) 
LONG           mAPAT[_N * _N]
LONG         mAPATSw[_N * _N]
LONG     mAPCTSzINVC[_N * _N]
LONG    mAPCTSzINVCP[_N * _N]
LONG  mAPCTSzINVCPAT[_N * _N]          

'User defined auxiliary variables to specify given model parameters
LONG  dt2              '[(deltaT)^2]/2
LONG  accAvr           'Average acceleration

'Define model and environment dependent process noise parameters
'These will be actuated in KF_Initialize procedure
LONG  accProcNoise     'One standard deviation. In this example this
                       'will be the source of process noises

LONG  posProcNoise     'One standard deviation
LONG  posProcNoiseVar  'Variance of position process noise  
LONG  velProcNoise     'One standard deviation
LONG  velProcNoiseVar  'Variance of velocity process noise
LONG  velPosPNCovar    'Covariance of velocity and position p. noises 

'Define sensor dependent measurement noises and covar. matrix elements
LONG  posMeasNoise     'One standard deviation  
LONG  posMeasNoiseVar  'Variance of the position measurement noise

'Root Mean Square position errors
LONG  gpsRmsError      'Root Mean Square of GPS error
LONG  kfRmsError       'Root Mean Square of Kalman Filter error


DAT '-------------------------Start of SPIN code--------------------------

               
PUB DoIt | ad_                              
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ DoIt │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: -Starts driver objects
''             -Makes a MASTER CLEAR of the FPU and
''             -Calls standard Time-Variable Kalman filter demo
'' Parameters: None
''    Results: None
''+Reads/Uses: /FPU pin CONs
''    +Writes: fpu3
''      Calls: FullDuplexSerialPlus------------->DBG.Start
''                                               DBG.Tx
''             FPU_Matrix_Driver --------------->FPUMAT.StartCOG
''                                               FPUMAT.StopCOG
''             Kalman_Filter_Demo  
'-------------------------------------------------------------------------
'Start FullDuplexSerialPlus Debug terminal
DBG.Start(31, 30, 0, 57600)

WAITCNT(6 * CLKFREQ + CNT)

DBG.Str(STRING(16, 1))
DBG.Str(STRING("Kalman filter with uM-FPU Matrix v2.0", 13))

WAITCNT(CLKFREQ + CNT)

ad_ := @cog_ID

fpu3 := FALSE

'FPU Master Clear...
DBG.Tx(13)
DBG.Str(STRING("FPU MASTER CLEAR...", 13))
outa[_FPU_MCLR]~~ 
dira[_FPU_MCLR]~~
outa[_FPU_MCLR]~
WAITCNT(CLKFREQ + CNT)
outa[_FPU_MCLR]~~
dira[_FPU_MCLR]~

'Start FPU_Matrix_Driver
fpu3 := FPUMAT.StartCOG(_FPU_DIO, _FPU_CLK, ad_)

IF fpu3
  DBG.Tx(13)
  DBG.Str(STRING("FPU Matrix Driver started in COG "))
  DBG.Dec(cog_ID)
  DBG.Tx(13)
  WAITCNT(2 * CLKFREQ + CNT)              

  Kalman_Filter_Demo

  DBG.Str(STRING(13, "Kalman filter with uM-FPU Matrix v2.0 "))
  DBG.Str(STRING("terminated normally...", 13))
  FPUMAT.StopCOG
ELSE
  DBG.Tx(13)
  DBG.Str(STRING("FPU Matrix Driver Start failed!", 13, 13))
  DBG.Str(STRING("No FPU found! Check board and try again...", 13))

WAITCNT(CLKFREQ + CNT)   
DBG.Stop  
'-------------------------------------------------------------------------    


PRI Kalman_Filter_Demo | okay, char, row, col, i, fV
'-------------------------------------------------------------------------
'-------------------------┌────────────────────┐--------------------------
'-------------------------│ Kalman_Filter_Demo │--------------------------
'-------------------------└────────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Demonstrates Kalman filter with the FPU_Matrix_Driver
''             procedures
'' Parameters: None
''    Results: None
''+Reads/Uses: None
''    +Writes: None
''      Calls: FullDuplexSerialPlus-------------->DBG.Str
''                                                DBG.Tx 
''                                                DBG.Dec
''             FloatToString
''             KF_Initialize
''             KF_Prepare_Next_TimeStep
''             KF_Next_K
''             KF_Next_X
''             KF_Next_P
'-------------------------------------------------------------------------
DBG.Str(STRING(16, 1)) 
DBG.Str(STRING("----------Kalman Filter Demo---------", 13))

WAITCNT(CLKFREQ + CNT)

okay := FALSE
okay := FPUMAT.Reset
DBG.Tx(13)   
IF okay
  DBG.Str(STRING("FPU Software Reset done...", 13))
ELSE
  DBG.Str(STRING("FPU Software Reset failed...", 13, 13))
  DBG.Str(STRING("Please check hardware and restart..."))
  REPEAT                             'Untill restart or switch off

WAITCNT(CLKFREQ + CNT)

char := FPUMAT.ReadSyncChar
DBG.Str(STRING(13, "Response to _SYNC: "))
DBG.Dec(char)
IF (char == FPUMAT#_SYNC_CHAR)
  DBG.Str(STRING("    (OK)", 13))  
ELSE
  DBG.Str(STRING("   Not OK!", 13, 13))
  DBG.Str(STRING("Please check hardware and restart...", 13))
  REPEAT                             'Untill restart or switch off

WAITCNT(CLKFREQ + CNT)

'Initialise pseudorandom run
rnd := FPUMAT.Rnd_Float_UnifDist(_FLOAT_SEED)
'Disperse values from very similar initial seeds       
REPEAT 12
  rnd := FPUMAT.Rnd_Float_UnifDist(rnd)

'debugLevel := 1  'Shows Setup, K and V evolution
debuglevel := 2   'Shows Setup, Time, Measurement, State est., K and V
'debuglevel := 3  'Shows allmost every details of the calculation


DBG.Str(STRING(16, 1))
DBG.Str(STRING("*****************Bicycle with GPS*****************"))
DBG.Str(STRING(13, 13))
DBG.Str(STRING("We try to speed up a bicycle with 1 m/s^2 commanded"))
DBG.Tx(13)
DBG.Str(STRING("acceleration. But the road is very bumpy and"))
DBG.Tx(13)
DBG.Str(STRING("the actual acceleration has large 0.5 m/s^2"))
DBG.Tx(13)
DBG.Str(STRING("standard deviation due to potholes. For position"))
DBG.Tx(13)
DBG.Str(STRING("determination we have only GPS data with 5 m"))
DBG.Tx(13)
DBG.Str(STRING("standard deviation 4 times a second. In spite of"))
DBG.Tx(13)
DBG.Str(STRING("all these odds and large randomness can we keep our"))
DBG.Tx(13)
DBG.Str(STRING("average position estimate error less than 2 m for"))
DBG.Tx(13)
DBG.Str(STRING("the 12 seconds of the run? The filter only 'knows'"))
DBG.Tx(13)
DBG.Str(STRING("the average acceleration and uses only the very "))     
DBG.Tx(13)
DBG.Str(STRING("noisy GPS position data. As a bonus from the system"))
DBG.Tx(13)
DBG.Str(STRING("model of the  Kalman filter we will obtain velocity"))
DBG.Tx(13)
DBG.Str(STRING("estimate, beside the primarily wanted position"))
DBG.Tx(13)
DBG.Str(STRING("estimate."))
DBG.Tx(13) 
  
WAITCNT(16*_DBGDEL + CNT) 

'Initialize Kalman filter***********************************************
KF_Initialize
'***********************************************************************

DBG.Str(STRING(16, 1))
DBG.Str(STRING("---------------------------------------")) 
DBG.Tx(13)
DBG.Str(STRING("Parameters of the linear system:"))
DBG.Tx(13)
DBG.Str(STRING(" Number of states n :"))  
DBG.Dec(_N) 
DBG.Str(STRING(13, " Number of inputs m :"))
DBG.Dec(_M) 
DBG.Str(STRING(13, "Number of outputs r :"))
DBG.Dec(_R) 
DBG.Tx(13)

WAITCNT(4*_DBGDEL + CNT) 

DBG.Str(STRING(13, "{A} [n-by-n]:", 13))
REPEAT row FROM 1 to _N
  REPEAT col FROM 1 to _N
    DBG.Str(FloatToString(mA[((row-1)*_N)+(col-1)], 96))
  DBG.Tx(13)
  WAITCNT((_DBGDEL/25) + CNT)

WAITCNT(4*_DBGDEL + CNT)  

DBG.Str(STRING(13, "{B} [n-by-m]:", 13))
REPEAT row FROM 1 to _N
  REPEAT col FROM 1 to _M
    DBG.Str(FloatToString(mB[((row-1)*_M)+(col-1)], 96))
  DBG.Tx(13)
  WAITCNT((_DBGDEL/25) + CNT)

WAITCNT(4*_DBGDEL + CNT)

DBG.Str(STRING(13, "{C} [r-by-n]:", 13))
REPEAT row FROM 1 to _R
  REPEAT col FROM 1 to _N
    DBG.Str(FloatToString(mC[((row-1)*_N)+(col-1)], 96))
  DBG.Tx(13)
  WAITCNT((_DBGDEL/25) + CNT)

WAITCNT(4*_DBGDEL + CNT)

DBG.Str(STRING(13, "{Sw} [n-by-n]:", 13))
REPEAT row FROM 1 to _N
  REPEAT col FROM 1 to _N
    DBG.Str(FloatToString(mSw[((row-1)*_N)+(col-1)], 96))
  DBG.Tx(13)
  WAITCNT((_DBGDEL/25) + CNT)

WAITCNT(4*_DBGDEL + CNT)

DBG.Str(STRING(13, "{Sz} [r-by-r]:", 13))
REPEAT row FROM 1 to _R
  REPEAT col FROM 1 to _R
    DBG.Str(FloatToString(mSz[((row-1)*_R)+(col-1)], 94))
  DBG.Tx(13)
  WAITCNT((_DBGDEL/25) + CNT)

WAITCNT(4*_DBGDEL + CNT)

DBG.Str(STRING(13, "{X(0)} [n-by-1]:", 13)) 
  REPEAT row FROM 1 to _N
    REPEAT col FROM 1 to 1
      DBG.Str(FloatToString(vX[(row-1)+(col-1)], 95))
    DBG.Tx(13)
    WAITCNT((_DBGDEL/25) + CNT)

WAITCNT(4*_DBGDEL + CNT)

DBG.Str(STRING(13, "{P(0)} [n-by-n]:", 13))
  REPEAT row FROM 1 to _N
    REPEAT col FROM 1 to _N
      DBG.Str(FloatToString(mP[((row-1)*_N)+(col-1)], 96))
    DBG.Tx(13)
    WAITCNT((_DBGDEL/25) + CNT)

WAITCNT(4*_DBGDEL + CNT)

IF debugLevel > 2

  DBG.Str(STRING(13, "{AT} [n-by-n]:", 13))
  REPEAT row FROM 1 to _N
    REPEAT col FROM 1 to _N
      DBG.Str(FloatToString(mAT[((row-1)*_N)+(col-1)], 96))
    DBG.Tx(13)
    WAITCNT((_DBGDEL/25) + CNT)

  WAITCNT(4*_DBGDEL + CNT)

  DBG.Str(STRING(13, "{CT} [n-by-r]:", 13))
  REPEAT row FROM 1 to _N
    REPEAT col FROM 1 to _R
      DBG.Str(FloatToString(mCT[((row-1)*_R)+(col-1)], 96))
    DBG.Tx(13)
    WAITCNT((_DBGDEL/25) + CNT)

  WAITCNT(4*_DBGDEL + CNT)

  DBG.Str(STRING(13, "{SzInv} [r-by-r]:", 13))
  REPEAT row FROM 1 to _R
    REPEAT col FROM 1 to _R
      DBG.Str(FloatToString(mSzInv[((row-1)*_R)+(col-1)], 96))
    DBG.Tx(13)
    WAITCNT((_DBGDEL/25) + CNT)

  WAITCNT(4*_DBGDEL + CNT)

  DBG.Str(STRING(13, "{SzInvC} [r-by-n]:", 13))
  REPEAT row FROM 1 to _R
    REPEAT col FROM 1 to _N
      DBG.Str(FloatToString(mSzInvC[((row-1)*_N)+(col-1)], 96))
    DBG.Tx(13)
    WAITCNT((_DBGDEL/25) + CNT)

  WAITCNT(4*_DBGDEL + CNT)

  DBG.Str(STRING(13, "{CTSzInvC} [n-by-n]:", 13))
  REPEAT row FROM 1 to _N
    REPEAT col FROM 1 to _N
      DBG.Str(FloatToString(mCTSzInvC[((row-1)*_N)+(col-1)], 96))
    DBG.Tx(13)
    WAITCNT((_DBGDEL/25) + CNT)

  WAITCNT(4*_DBGDEL + CNT)


REPEAT i FROM 1 TO 48

  'Prepare next time step***********************************************
  KF_Prepare_Next_TimeStep
  '*********************************************************************

  IF debugLevel > 2
      
    DBG.Str(STRING("Measurement {Y} [r-by-1]:"))
    DBG.Tx(13) 
    REPEAT row FROM 1 to _R
      REPEAT col FROM 1 to 1
        DBG.Str(FloatToString(vY[(row-1)+(col-1)], 95))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Str(STRING(13, "MeasNoise [r-by-1]:", 13)) 
      REPEAT row FROM 1 to _R
        REPEAT col FROM 1 to 1
          DBG.Str(FloatToString(vMeasNoise[(row-1)+(col-1)], 95))
        DBG.Tx(13)
        WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Str(STRING(13, "Input {U} [r-by-1]:", 13)) 
      REPEAT row FROM 1 to _R
        REPEAT col FROM 1 to 1
          DBG.Str(FloatToString(vU[(row-1)+(col-1)], 93))
        DBG.Tx(13)
        WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Str(STRING(13, "ProcNoise [n-by-1]:", 13)) 
      REPEAT row FROM 1 to _N
        REPEAT col FROM 1 to 1
          DBG.Str(FloatToString(vProcNoise[(row-1)+(col-1)], 95))
        DBG.Tx(13)
        WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

  'Calculate next Kalman gain matrix************************************
  KF_Next_K
  '*********************************************************************
  
  IF debugLevel > 2
    DBG.Str(STRING(13,"{AP} [n-by-n]:", 13))
    REPEAT row FROM 1 to _N
      REPEAT col FROM 1 to _N
        DBG.Str(FloatToString(mAP[((row-1)*_N)+(col-1)], 96))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Str(STRING(13,"{APCT} [n-by-r]:", 13))
    REPEAT row FROM 1 to _N
      REPEAT col FROM 1 to _R
        DBG.Str(FloatToString(mAPCT[((row-1)*_R)+(col-1)], 96))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Str(STRING(13,"{CP} [r-by-n]:", 13))
    REPEAT row FROM 1 to _R
      REPEAT col FROM 1 to _N
        DBG.Str(FloatToString(mCP[((row-1)*_N)+(col-1)], 96))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Str(STRING(13,"{CPCT} [r-by-r]:", 13))
    REPEAT row FROM 1 to _R
      REPEAT col FROM 1 to _R
        DBG.Str(FloatToString(mCPCT[((row-1)*_R)+(col-1)], 96))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Str(STRING(13,"{CPCTSz} [r-by-r]:", 13))
    REPEAT row FROM 1 to _R
      REPEAT col FROM 1 to _R
        DBG.Str(FloatToString(mCPCTSz[((row-1)*_R)+(col-1)], 93))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Str(STRING(13,"{CPCTSzInv} [r-by-r]:", 13))
    REPEAT row FROM 1 to _R
      REPEAT col FROM 1 to _R
        DBG.Str(FloatToString(mCPCTSzInv[((row-1)*_R)+(col-1)], 96))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

      WAITCNT(4*_DBGDEL + CNT)

  IF (debugLevel > 1)  
    DBG.Str(STRING(13,"{K} [n-by-r]:", 13))
    REPEAT row FROM 1 to _N
      REPEAT col FROM 1 to _R
        DBG.Str(FloatToString(mK[((row-1)*_R)+(col-1)], 95))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(6*_DBGDEL + CNT)
  
  'Calculate next State estimate****************************************
  KF_Next_X
  '*********************************************************************

  IF (debugLevel > 3)
  
    DBG.Str(STRING(13, "{vCx} [r-by-1]:", 13)) 
    REPEAT row FROM 1 to _R
      REPEAT col FROM 1 to 1
        DBG.Str(FloatToString(vCx[(row-1)+(col-1)], 95))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)
 
    DBG.Str(STRING(13, "{vyCx} [n-by-1]:", 13)) 
      REPEAT row FROM 1 to _R
        REPEAT col FROM 1 to 1
          DBG.Str(FloatToString(vyCx[(row-1)+(col-1)], 95))
        DBG.Tx(13)
        WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Str(STRING(13, "{vKyCx} [n-by-1]:", 13)) 

    REPEAT row FROM 1 to _N
      REPEAT col FROM 1 to 1
        DBG.Str(FloatToString(vKyCx[(row-1)+(col-1)], 95))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Str(STRING(13, "{vAx} [n-by-1]:", 13)) 
      REPEAT row FROM 1 to _N
        REPEAT col FROM 1 to 1
          DBG.Str(FloatToString(vAx[(row-1)+(col-1)], 95))
        DBG.Tx(13)
        WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Str(STRING(13, "{vBu} [n-by-1]:", 13)) 
      REPEAT row FROM 1 to _N
        REPEAT col FROM 1 to 1
          DBG.Str(FloatToString(vBu[(row-1)+(col-1)], 95))
        DBG.Tx(13)
        WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)
  
    DBG.Str(STRING(13, "{vAxBu} [n-by-1]:", 13)) 
      REPEAT row FROM 1 to _N
        REPEAT col FROM 1 to 1
          DBG.Str(FloatToString(vAxBu[(row-1)+(col-1)], 95))
        DBG.Tx(13)
        WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

  IF (debugLevel > 1)
  
    DBG.Str(STRING(16, 1))
    DBG.Str(STRING("---------------------------------------")) 
    DBG.Str(STRING(13, "Time : "))
    DBG.Str(FloatToString(time , 93)) 
    DBG.Tx(13)

    DBG.Str(STRING(13, "GPS position data [r-by-1]:"))
    DBG.Tx(13)  
      REPEAT row FROM 1 to _R
        REPEAT col FROM 1 to 1
          DBG.Str(FloatToString(vY[(row-1)+(col-1)], 71))
        DBG.Tx(13)
        WAITCNT((_DBGDEL/25) + CNT)
    WAITCNT(1*_DBGDEL + CNT)
    
    DBG.Str(STRING(13, "State estimate (pos. vel.) [n-by-1]:"))
    DBG.Tx(13)  
      REPEAT row FROM 1 to _N
        REPEAT col FROM 1 to 1
          DBG.Str(FloatToString(vX[(row-1)+(col-1)], 93))
        DBG.Tx(13)
        WAITCNT((_DBGDEL/25) + CNT)
    WAITCNT(_DBGDEL + CNT)

    DBG.Str(STRING(13, "'True' state (pos. vel.) [n-by-1]:"))
    DBG.Tx(13)  
      REPEAT row FROM 1 to _N
        REPEAT col FROM 1 to 1
          DBG.Str(FloatToString(vXtrue[(row-1)+(col-1)], 93))
        DBG.Tx(13)
        WAITCNT((_DBGDEL/25) + CNT)
    WAITCNT(_DBGDEL + CNT)

    'Calculate errors, this step is modell dependent
    'Update gpsRmsError
    FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)       
    FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, vY[0])
    FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)    
    FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, vXtrue[0])
    FPUMAT.WriteCmdByte(FPUMAT#_FSUB, 127)
    FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 126)
    FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
    FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, gpsRmsError)
    FPUMAT.WriteCmdByte(FPUMAT#_FADD, 126)
    FPUMAT.Wait
    FPUMAT.WriteCmd(FPUMAT#_FREADA)
    gpsRmsError := FPUMAT.ReadReg
    FPUMAT.WriteCmdByte(FPUMAT#_FDIVI, i)
    FPUMAT.WriteCmd(FPUMAT#_SQRT)  
    
    DBG.Str(STRING(13, "RMS average GPS position error = "))
    DBG.Str(FPUMAT.ReadRaFloatAsStr(52))
    DBG.Tx(13)

    'Update kfRmsError
    FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)       
    FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, vX[0])
    FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)    
    FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, vXtrue[0])
    FPUMAT.WriteCmdByte(FPUMAT#_FSUB, 127)
    FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 126)
    FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
    FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, kfRmsError)
    FPUMAT.WriteCmdByte(FPUMAT#_FADD, 126)
    FPUMAT.Wait
    FPUMAT.WriteCmd(FPUMAT#_FREADA)
    kfRmsError := FPUMAT.ReadReg
    FPUMAT.WriteCmdByte(FPUMAT#_FDIVI, i)
    FPUMAT.WriteCmd(FPUMAT#_SQRT)  
    
    DBG.Str(STRING(13, "RMS average  KF position error = "))
    DBG.Str(FPUMAT.ReadRaFloatAsStr(52))
    DBG.Tx(13)  
     
    WAITCNT(_DBGDEL + CNT)    
  
  'Calculate next estimation error covariance matrix********************
  KF_Next_P
  '*********************************************************************

  IF (debugLevel > 2)
  
    DBG.Str(STRING(13, "{APAT} [n-by-n]:", 13))
    REPEAT row FROM 1 to _N
      REPEAT col FROM 1 to _N
        DBG.Str(FloatToString(mAPAT[((row-1)*_N)+(col-1)], 96))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Str(STRING(13, "{APATSw} [n-by-n]:", 13))
    REPEAT row FROM 1 to _N
      REPEAT col FROM 1 to _N
        DBG.Str(FloatToString(mAPATSw[((row-1)*_N)+(col-1)], 96))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Tx(13)
    DBG.Str(STRING(13,"{APCTSzInvC} [n-by-n]:", 13))
    REPEAT row FROM 1 to _N
      REPEAT col FROM 1 to _N
        DBG.Str(FloatToString(mAPCTSzInvC[((row-1)*_N)+(col-1)], 96))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Tx(13)
    DBG.Str(STRING(13,"{APCTSzInvCP} [n-by-n]:", 13))
    REPEAT row FROM 1 to _N
      REPEAT col FROM 1 to _N
        DBG.Str(FloatToString(mAPCTSzInvCP[((row-1)*_N)+(col-1)], 96))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

    DBG.Tx(13)
    DBG.Str(STRING(13,"{APCTSzInvCPAT} [n-by-n]:", 13))
    REPEAT row FROM 1 to _N
      REPEAT col FROM 1 to _N
        DBG.Str(FloatToString(mAPCTSzInvCPAT[((row-1)*_N)+(col-1)],96))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(4*_DBGDEL + CNT)

  IF (debugLevel > 1)  
    DBG.Tx(13)
    DBG.Str(STRING("{P} [n-by-n]:", 13))
    REPEAT row FROM 1 to _N
      REPEAT col FROM 1 to _N
        DBG.Str(FloatToString(mP[((row-1)*_N)+(col-1)], 96))
      DBG.Tx(13)
      WAITCNT((_DBGDEL/25) + CNT)

    WAITCNT(2*_DBGDEL + CNT)
'-------------------------------------------------------------------------


DAT '-------------Modell dependent Kalman Filter procedures---------------


PRI KF_Initialize | row, col
'-------------------------------------------------------------------------
'------------------------------┌───────────────┐--------------------------
'------------------------------│ KF_Initialize │--------------------------
'------------------------------└───────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Initializes KF calculations
' Parameters: Timestep deltaT, process noise and measurement noise data
'             System parameters
'    Results: -A, B, C, Sw, Sz matrices
'             -Starting valu of vX, vXtrue vectors
'+Reads/Uses: /FPUMAT CONs 
'    +Writes: FPU Reg:127, 126
'      Calls: FPU_Matrix_Driver------------->FPUMAT.Read/Write procedures
'                                            FPUMAT.Matrix_Copy
'                                            FPUMAT.Matrix_Transpose
'                                            FPUMAT.Matrix_InvertSmall
'                                            FPUMAT.Matrix_Multiply    
'-------------------------------------------------------------------------
'Setup time step
deltaT := 0.25                     's
time := 0.0                        's

'Setup error statistics
gpsRmsError := 0.0
kfRmsError  := 0.0

'Setup average acceleration
accAvr := 1.0                      'm/s2
'Setup acceleration noise 
accProcNoise := 0.5                '(one standard deviation)
'In this example this uncertainity is the only source of process noises     
  
'Calculate user defined variables---------------------------------------
'Calculate (deltaT^2)/2
dt2 := FPUMAT.Float_MUL(deltaT, deltaT)
dt2 := FPUMAT.Float_DIV(dt2, 2.0) 

'One Standard deviation of the position process noise is
'             (dt2)*(accProcNoise)
posProcNoise := FPUMAT.Float_MUL(dt2, accProcNoise)

'One Standard deviation of the velocity process noise is
'           (deltaT)*(accProcNoise)
velProcNoise := FPUMAT.Float_MUL(deltaT, accProcNoise)

'Variance of the position proc. noise is
'          (sdev of pos. p. noise)^2
posProcNoiseVar := FPUMAT.Float_MUL(posProcNoise, posProcNoise)

'Variance of the velocity proc. noise is
'          (sdev of vel. p. noise)^2
velProcNoiseVar := FPUMAT.Float_MUL(velProcNoise, velProcNoise)

'Covariance of the position and velocity process noises
'      (sdev of pos. p. noise)*(sdev of vel. p. noise)
velPosPNCovar := FPUMAT.Float_MUL(posProcNoise, velProcNoise)

'Define Sw[n-by-n] matrix 
row := 1
col := 1
mSw[((row-1)*_N)+(col-1)] := posProcNoiseVar
row := 1
col := 2
mSw[((row-1)*_N)+(col-1)] := velPosPNCovar
row := 2
col := 1
mSw[((row-1)*_N)+(col-1)] := velPosPNCovar
row := 2
col := 2
mSw[((row-1)*_N)+(col-1)] := velProcNoiseVar
 
'Define sensor dependent measurement noise parameters
posMeasNoise := 5.0                'One standard deviation
'Variance of the position meas. noise is
'       (sdev of pos. m. noise)^2
posMeasNoiseVar := FPUMAT.Float_MUL(posMeasNoise, posMeasNoise) 

'Define Sz[r-by-r] matrix
row := 1
col := 1
mSz[((row-1)*_R)+(col-1)] := posMeasNoisevar

'Define linear system and measurement matrices--------------------------
'Define A[n-by-n] matrix
row := 1
col := 1
mA[((row-1)*_N)+(col-1)] := 1.0
row := 1
col := 2
mA[((row-1)*_N)+(col-1)] := deltaT
row := 2
col := 1
mA[((row-1)*_N)+(col-1)] := 0.0
row := 2
col := 2
mA[((row-1)*_N)+(col-1)] := 1.0

'Define B[n-by-m] matrix
row := 1
col := 1
mB[((row-1)*_M)+(col-1)] := dt2
row := 2
col := 1
mB[((row-1)*_M)+(col-1)] := deltaT

'Define C[r-by-n] matrix
row := 1
col := 1
mC[((row-1)*_N)+(col-1)] := 1.0
row := 1
col := 2
mC[((row-1)*_N)+(col-1)] := 0.0

'Initialize the P estimation error covariance matrix as Sw
FPUMAT.Matrix_Copy(@mP, @mSw, _N, _N)

'Specify starting value of state vector
row := 1
vX[row - 1] := 0.0       'Estimated position 
row := 2
vX[row - 1] := 0.0       'Estimated speed

'Specify starting value of the simulated "true" system state
row := 1
vXtrue[row - 1] := 0.0   '"true" position
row := 2
vXtrue[row - 1] := 0.0   '"true" speed
  
'Calculate permanently used constant matrices (*)
FPUMAT.Matrix_Transpose(@mAT, @mA, _N, _N)                       '(*)
FPUMAT.Matrix_Transpose(@mCT, @mC, _R, _N)                       '(*)
FPUMAT.Matrix_InvertSmall(@mSzInv, @mSz, _R)
FPUMAT.Matrix_Multiply(@mSzInvC, @mSzInv, @mC, _R, _R, _N)
FPUMAT.Matrix_Multiply(@mCTSzInvC, @mCT, @mSzInvC, _N, _R, _N)   '(*)
'-------------------------------------------------------------------------


PRI KF_Prepare_Next_TimeStep | fV, row, col
'-------------------------------------------------------------------------
'----------------------┌──────────────────────────┐-----------------------
'----------------------│ KF_Prepare_Next_TimeStep │-----------------------
'----------------------└──────────────────────────┘-----------------------
'-------------------------------------------------------------------------
'     Action: -Prepares data to calculate X(k+1), i.e.
'             -Generates process noise and   (for tests and filter tuning)
'             measurement noise              (for tests and filter tuning)
'             -Calculates input vector vU(k) for timestep k 
' Parameters: Noise parameters
'    Results: -Y(k) "noisy" measurement values
'             -Xtrue(k+1)
'+Reads/Uses: /FPUMAT CONs 
'    +Writes: FPU Reg:127, 126, 125
'      Calls: FPU_Matrix_Driver------------->FPUMAT.Read/Write procedures
'                                            FPUMAT.Rnd_Float_UnifDist
'                                            FPUMAT.Rnd_Float_NormDist
'       Note: This procedure now serves for testing and tuning but this is
'             the right place to enter actuator (input) data and sensor
'             (measurement) data in real applications. In that case Mother
'             Nature will do us the favour to generate all the noises.
'-------------------------------------------------------------------------
'Measurement data came here from real sensors in real applications.
'Now we are running a simulation, so we calculate the measurement
'vector from the hypothetical "true" state vector and then we perturb
'that vector delibaretly with the measurement error.
'First calculate measurement vector (or enter sensor values here!)
FPUMAT.Matrix_Multiply(@vY, @mC, @vXtrue, _R, _N, 1)
 
'Calculate Measurement Noise vector from posMeasNoise
rnd := FPUMAT.Rnd_Float_UnifDist(rnd)           
fV := FPUMAT.Rnd_Float_NormDist(rnd, 0.0, posMeasNoise)
row := 1
vMeasNoise[row - 1] := fV  
FPUMAT.Matrix_Add(@vY,@vY,@vMeasNoise,_R,1) 'Add simulated meas. noise

'Calculate new time
time := FPUMAT.Float_ADD(time, deltaT)

'Generate Process Noise [directly from acceleration noise]
rnd := FPUMAT.Rnd_Float_UnifDist(rnd)
fV := FPUMAT.Rnd_Float_NormDist(rnd, accAvr, accProcNoise)

'Calculate the perturbed acceleration for the simulation 
row := 1
vU[row - 1] := fV

'Calculate hypothetical "true" state vector from the acceleration     
'Next section for "true" state is for simulation purposes only
'Calculat "true" state vector from the input acceleration
'Integrate position first
'vXtrue[0](k+1) = vXtrue[0](k) + vXtrue[1](k)*deltaT + a*(deltaT2)/2
fV := vXtrue[0]     'Previous "true" Position
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, fV)
fV := vXtrue[1]     'Previous "true" Speed
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, fV)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 125)
FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, deltaT)
FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 126)
FPUMAT.WriteCmdByte(FPUMAT#_FADD, 127)
fV := vU[0]         'We simulate to know the acceleration
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, fV)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, dt2)
FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 127)
FPUMAT.WriteCmdByte(FPUMAT#_FADD, 125)
FPUMAT.Wait
FPUMAT.WriteCmd(FPUMAT#_FREADA)
fV := FPUMAT.ReadReg
vXtrue[0] := fV      'Integrated "true" position
'Now integrate speed
'vXtrue[1](k+1) = vXtrue[1](k) + a*deltaT  
fV := vXtrue[1]      'Previous "true" speed 
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, fV)
fV := vU[0]          'We simulate to know the acceleration
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, fV)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 125)
FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, deltaT)
FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 126)
FPUMAT.WriteCmdByte(FPUMAT#_FADD, 127)
FPUMAT.Wait
FPUMAT.WriteCmd(FPUMAT#_FREADA)
fV := FPUMAT.ReadReg
vXtrue[1] := fV      'Integrated "true" velocity

'Now set back the nominal value of the acceleration that we really
'assume and  take into account in the filter calculation 
row := 1
vU[row - 1] := accAvr    
'------------------------------------------------------------------------- 


DAT '---------Modell independent Kalman Filter Core procedures------------


PRI KF_Next_K
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ KF_Next_K │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: This sequence of FPU_Matrix procedure calls computes the
'             K(k) matrix
' Parameters: A, C, Sz, P
'    Results: Kalman gain matrix
'+Reads/Uses: /KF matrices 
'    +Writes: KF matrices
'      Calls: FPU_Matrix_Driver------------->FPUMAT.Matrix_Multiply 
'                                            FPUMAT.Matrix_Add
'                                            FPUMAT.Matrix_Invert(Small)
'-------------------------------------------------------------------------
FPUMAT.Matrix_Multiply(@mAP, @mA, @mP, _N, _N, _N)
FPUMAT.Matrix_Multiply(@mAPCT, @mAP, @mCT, _N, _N, _R)
FPUMAT.Matrix_Multiply(@mCP, @mC, @mP, _R, _N, _N)
FPUMAT.Matrix_Multiply(@mCPCT, @mCP, @mCT, _R, _N, _R)
FPUMAT.Matrix_Add(@mCPCTSz, @mCPCT, @mSz, _R, _R)
FPUMAT.Matrix_InvertSmall(@mCPCTSzInv, @mCPCTSz, _R)
'Use here Matrix_Invert IF necessary, i.e. when _R>3 
FPUMAT.Matrix_Multiply(@mK, @mAPCT, @mCPCTSzInv, _N, _R, _R)  
'-------------------------------------------------------------------------


PRI KF_Next_X
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ KF_Next_X │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: This sequence of procedure calls computes X(k+1)
' Parameters: -Previous state estimate X(k)
'             -Measurement values Y(k)
'             -Kalman gain matrix K(k)
'    Results: New state estimate vector X(k+1)
'+Reads/Uses: /KF matrices 
'    +Writes: KF matrices
'      Calls: FPU_Matrix_Driver------------->FPUMAT.Matrix_Multiply
'                                            FPUMAT.Matrix_Subtract         
'                                            FPUMAT.Matrix_Add
'-------------------------------------------------------------------------
FPUMAT.Matrix_Multiply(@vCx, @mC, @vX, _R, _N, 1)
FPUMAT.Matrix_Subtract(@vyCx, @vY, @vCx, _R, 1) 
FPUMAT.Matrix_Multiply(@vKyCx, @mK, @vyCx, _N, _R, 1)
FPUMAT.Matrix_Multiply(@vAx, @mA, @vX, _N, _N, 1)  
FPUMAT.Matrix_Multiply(@vBu, @mB, @vU, _N, _M, 1)
FPUMAT.Matrix_Add(@vAxBu, @vAx, @vBu, _N, 1)
FPUMAT.Matrix_Add(@vX, @vAxBu, @vKyCx, _N, 1)
'-------------------------------------------------------------------------


PRI KF_Next_P
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ KF_Next_P │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: This sequence of procedure calls computes the P(k+1) matrix
' Parameters: A, C, Sz, Sw
'    Results: P(k+1)
'+Reads/Uses: /KF matrices 
'    +Writes: KF matrices
'      Calls: FPU_Matrix_Driver------------->FPUMAT.Matrix_Multiply
'                                            FPUMAT.Matrix_Add         
'                                            FPUMAT.Matrix_Subtract
'-------------------------------------------------------------------------
FPUMAT.Matrix_Multiply(@mAPAT, @mAP, @mAT, _N, _N, _N)
FPUMAT.Matrix_Add(@mAPATSw, @mAPAT, @mSw, _N, _N) 
FPUMAT.Matrix_Multiply(@mAPCTSzInvC, @mAP, @mCTSzInvC, _N, _N, _N)
FPUMAT.Matrix_Multiply(@mAPCTSzInvCP,@mAPCTSzInvC,@mP,_N,_N,_N)
FPUMAT.Matrix_Multiply(@mAPCTSzInvCPAT,@mAPCTSzInvCP,@mAT,_N,_N,_N)
FPUMAT.Matrix_Subtract(@mP, @mAPATSw, @mAPCTSzInvCPAT, _N, _N)
'-------------------------------------------------------------------------


PRI FloatToString(floatV, format)
'-------------------------------------------------------------------------
'------------------------------┌───────────────┐--------------------------
'------------------------------│ FloatToString │--------------------------
'------------------------------└───────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Converts a HUB/floatV into string within FPU then loads it
'             back into HUB
' Parameters: -Float value
'             -Format code in FPU convention
'    Results: Pointer to string in HUB
'+Reads/Uses: FPUMAT#_FWRITE, FPUMAT#_SELECTA 
'    +Writes: FPU Reg: 127
'      Calls: FPU_Matrix_Driver------->FPUMAT.WriteCmdByte 
'                                      FPUMAT.WriteCmdFloat
'                                      FPUMAT.ReadRaFloatAsStr
'       Note: For debug and test purposes
'-------------------------------------------------------------------------
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
FPUMAT.WriteCmdFloat(FPUMAT#_FWRITEA, floatV)
RESULT := FPUMAT.ReadRaFloatAsStr(format) 
'-------------------------------------------------------------------------


DAT '---------------------------MIT License-------------------------------

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