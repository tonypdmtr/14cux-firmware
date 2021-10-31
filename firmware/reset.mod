; ------------------------------------------------------------------------------
; 14CUX Firmware Rebuild Project

; File Date: 14-Nov-2013

; Description:    Code Reset Entry Point

; This contains the reset entry code.

; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Reset Entry Point

; When ignition power is applied to the board the MPU reads the 16-bit value
; stored at 0xFFFE/FF. This is called the reset vector and tells the MPU where
; to start executing code. This value is 0xC861 for all 14CUX units. The first
; thing is to set up the MPU ports for both data direction and data level.

; Port Direction   Level   Purpose
; --------------------------------
; P10   Output     High     MIL
; P11   Output     High     Purge Valve (uses MPU Timer 2)
; P12   Output     High     Even Injector Bank (uses Timer 3 and T4 transistor)
; P13   Output     High     Condensor Fan Timer
; P14   Output     Low      Stepper Motor Drive 1
; P15   Output     Low      Stepper Motor Drive 2
; P16   Output     Low      Fuel Pump Relay (defaults to ON)
; P17   Output     Low      Stay Alive Toggle

; P20   Input      (n/a)    Ignition Coil (used as TIn1 timer)
; P21   Output     High     Odd Injector Bank (uses Timer 1 and T2 transistor)
; P22   Output     Low      A/C Compressor
; P23   Output     Low      RDATA (Serial Port)
; P24   Output     Low      TDATA (Serial Port)

; Notes:
; 1) Transistor T4 may not be marked on older boards. It's the one nearest to
; R57 in the corner.
; 2) Programmed direction and level are ignored for P23 & P24 when in UART mode.

; Added note 19-Dec-2013:
; All references to L & R are reversed.
; MPU Pin 9  (Port 2.1) is R bank (Same Polarity)
; MPU Pin 15 (Port 1.2) is L bank (Reversed Polarity)

; ------------------------------------------------------------------------------

; ----------------------------
; Init MPU regs
; ----------------------------
reset               sei                           ; Set interrupt mask
                    lds       #$00FF              ; reset stack pointer
                    ldd       #$FFFE
                    std       port1ddr            ; all P1 & P2 pins to out (exc P20 pin-8, ignition coil)
                    ldb       #$FF
                    stb       port4ddr
                    stb       port4data           ; port 4 to std 16-bit addressing
                    ldd       #$0F02
                    std       port1data           ; write #0F02 to P1 & P2 data ports
                    ldb       #$A1                ; init P12 & P21 injector outputs (bit 2 low, bit 0 low)
                    stb       timerCntrlReg1
                    ldb       #$13                ; enable Input Capture Interrupt (ICI)
                    stb       timerCSR
                    ldb       #$53                ; enable Output Compare Interrupt 2
                    stb       timerCntrlReg2
                    cmpa      timerCSR            ; compare A with T1.CSR
                    cmpa      timerStsReg
                    ldd       counterHigh         ; load AB from counter (16 bits)
                    addd      #$0014              ; add $0014 to AB
                    std       ocr1High            ; store 16-bits in output cmpr reg
                    std       ocr2high
                    std       ocr3high
                    ldd       icrHigh             ; input cap reg (does this clr something?)
                    lda       ramControl          ; load RAM control
                    ora       #$40                ; set RAME bit (RAM at $40 to $FF)
                    sta       ramControl          ; write RAM control reg

; ----------------------------
; Clear internal memory
; ----------------------------
                    clra
                    ldx       #$0054              ;*** Zero Memory $54 to $FA ***
                    ldb       #$A6

.zeroRAM_0054       sta       $00,x
                    inx
                    decb
                    bne       .zeroRAM_0054       ;*** End Zero Memory ***

; ----------------------------
; Init more regs and vars
; ----------------------------
                    lda       #$20                ; init ADC (S&H mode, settling time avail., no IRQ)
                    sta       AdcControlReg0      ; write ADC control reg
                    lda       #$87
                    sta       iacvDriveValue      ; $87 is 1 of 4 stepper motor values (and the default position)
                    ldb       #$20
                    stb       $0086               ; set X0086.5 (clrd when RPM exceeds limit from fuel map)
                    ldb       #$01
                    stb       bits_008C           ; set bits_008C.0 (TP vs MAF in ICI, set for TP)

; ----------------------------
; Clear external memory
; ----------------------------
                    clra                          ;*** Start Zero Mem (2000h to 207F) ***
                    ldx       #$2000
                    ldb       #$80

.zeroRAM_2000       sta       $00,x
                    inx
                    decb
                    bne       .zeroRAM_2000       ;*** End Zero Memory ***

; ----------------------------
; Init external memory
; ----------------------------
                    lda       $C1FE               ; for R3526. value is $10
                    sta       closedLoopDelay     ; this is a 1Hz startup count-down timer
                    lda       $C1C9               ; for R3526, value is $B2 (178 dec)
                    sta       $200A               ; used to calc fuel map load index
                    ldd       #initialRpmLimit    ; see data file for value
                    std       rpmLimitRAM
                    lda       #initialRpmMargin   ; see data file for value
                    sta       $200B               ; store RPM safety margin
                    ldd       $C080               ; load map 0 multiplier (usually $54DD)
                    std       $2008               ; store fuel map multiplier value
                    lda       $C13C               ; data value is $7A or $6E
                    sta       $200E               ; an ECT sensor threshold
                    lda       $C13A               ; data value is $25 or $2C
                    sta       $200F               ; init coolant temp threshold
                    lda       $C0A5               ; data value is $51
                    sta       $2010               ; store at X2010
                    lda       $C134               ; data value is $64 (100 dec)
                    sta       $2011               ; used to multiply throttle pot delta
                    ldd       #$8000
                    std       stepperMtrCounter   ; reset stepperMtrCounter
                    sta       iacvVariable        ; reset iacvVariable to $80
                    sta       iacvValue1          ; store $80 at iacvValue1 (mid-point)
                    lda       bits_201F
                    ora       #$80                ; set bits_201F.7 high (unused otherwise)
                    sta       bits_201F
                    lda       #$04
                    sta       tpsDirectionAndRate  ; $400 or 1024 decimal
                    lda       #$34
                    sta       tpMinCounter        ; slows down TPmin adjustment
                    lda       #$64
                    sta       unusedValue         ; (unused)

; ----------------------------
; Check for locked map & init
; ----------------------------
                    lda       fuelMapLock         ; load fuel map lock value
                    beq       .LC92F              ; branch if unlocked (zero)

                    lda       #$05                ; load 5
                    sta       fuelMapNumber       ; store as fuel map number
                    sta       fuelMapNumberBackup  ; store as fuel map backup number
                    ldx       #$C7A9              ; ADC control table for fuel map 5
                    stx       adcMuxTableStart    ; store as as ADC control table ptr
                    ldd       #fuelMap5           ; load address ptr to fuel map 5
                    std       fuelMapPtr          ; store as fuel map base pointer
                    bra       .LC934              ; branch

; ----------------------------
; Init map 0 ADC table                          ; code branches here when fuel map is unlocked
; ----------------------------
.LC92F              ldx       #$C082              ; default ADC control table
                    stx       adcMuxTableStart

; ----------------------------
; Call init routine below
; ----------------------------
.LC934              jsr       reInitVars          ; call memory init subroutine below (inits external memory)

; ----------------------------
; Verify Battery-Backed RAM
; ----------------------------
                    ldb       ramControl          ; check reliability of RAM (see mpu doc)
                    bpl       .ramUnreliable      ; branch ahead if battery-backed RAM is no good

                    jsr       calcBatteryBackedChecksum  ; this code executes when ram is reliable
                    tab                           ; Xfer sum from A to B
                    lda       ramChecksum
                    cba                           ; Compare accumulators
                    bne       .initDefaults       ; Branch if bad checksum (battery backed)

                    ldd       throttlePotMinimum  ; if here, stored data in RAM is good
                    std       throttlePotMinCopy  ; overwrites RAM checksum
                    addd      $C1BD               ; for R3526, value is $0A, add to TPmin
                    std       throttlePotMinimum
                    bra       .i2cDispFault

; ----------------------------
; RAM is bad, set DTC 02
; ----------------------------
.ramUnreliable      lda       faultBits_4E
                    ora       #$40                ; <-- Set Fault Code 02 (RAM Fail, battery or ECU disconnected)
                    sta       faultBits_4E

; ----------------------------
; Reinitialize RAM values
; ----------------------------
.initDefaults       ldd       #$0070              ; branches here is bad RAM checksum; init default values
                    std       throttlePotMinimum  ; init throttle pot minimum to #$0070 (547 mV)
                    std       throttlePotMinCopy
                    ldd       #$8000              ; Note:
                    std       longLambdaTrimR     ; Two of these 4 values are long term trim and the other two are
                    std       longLambdaTrimL     ; related. They are similar in that $8000 is the initial neutral
                    std       secondaryLambdaR    ; value and the value goes positive or negative from there.
                    std       secondaryLambdaL
                    stb       hiFuelTemperature   ; this tells the software when there's a hot restart
                    stb       iacvObsolete        ; this value is added to 'iacvEctValue' but it's always zero anyway
                    lda       $C242               ; data value is $6C (108 dec)
                    sta       stprMtrSavedValue   ; init stprMtrSavedValue to $6C

; ----------------------------
; Check for locked fuel map
; ----------------------------
                    lda       fuelMapLock         ; load data value from XC7C1
                    beq       .mapNotLocked       ; zero means unlocked

                    ldd       #fuelMap5           ; non-zero, so fuel map is locked, load map 5
                    std       fuelMapPtr          ; load pointer to map 5 data structur
                    bra       .clearFaults        ; branch ahead

.mapNotLocked       ldd       #fuelMap1           ; unlocked, load map 1
                    std       fuelMapPtr          ; fuel map resistor will override this

; ----------------------------
; RAM is bad, so clear faults
; ----------------------------
.clearFaults        clra
                    clrb
                    sta       fuelMapNumberBackup  ; set fuel map backup number to zero
                    std       faultBits_49
                    std       faultBits_4B
                    sta       faultBits_4D
                    ldb       faultBits_4E
                    andb      #$C0                ; clr last fault bits exc. 7:6 (Data Corrupted & RAM Fail)
                    stb       faultBits_4E
                    lda       bits_008C
                    ora       #$40                ; set internal code fault indicator
                    sta       bits_008C
                    lda       faultBits_4E
                    ora       #$80                ; <-- Set Fault Code 03 (bad battery backed checksum)
                    sta       faultBits_4E

; ----------------------------
; Display stored fault                              ; branches here if battery backed RAM is good
; ----------------------------
.i2cDispFault       jsr       faultCodeScan
                    lda       tmpFaultCodeStorage
                    jsr       i2c                 ; I2C routine (display 1st digit)
                    jsr       i2c                 ; I2C routine (display 2nd digit)
                    clr       tmpFaultCodeStorage  ; clear fault code
                    lda       faultBits_4E
                    anda      #$3F                ; clr fault codes 02 and 03 (data corrupt / RAM fail)
                    sta       faultBits_4E

; ----------------------------
; Init some hardware regs
; ----------------------------
                    ldd       #$050A
                    std       sciModeControl      ; init SCI for 7812 baud (1 MHz/128)
                    lda       #$FE
                    sta       port2ddr            ; set port 2 data dir (again)
                    lda       timerStsReg
                    ldd       icrHigh             ; clears something?

; ----------------------------
; Copy RAM to ext. mirror
; ----------------------------
                    ldx       #externalRAMCopy-1  ; Loop: Copy battery backed to external memory
                    lds       #batteryBackedRAM-1

.copyToExternal     inx
                    pula                          ; pull pre-increments
                    sta       $00,x
                    cpx       #externalRAMCopy+sizeOfRAMBackup
                    bne       .copyToExternal

; ----------------------------
; Init stack and enter loop
; ----------------------------
                    lds       #$00FF              ; Reset stack ptr to FFh
                    cli                           ; Clear interrupt mask
                    bra       preMainLoop

; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Reinitialize Variables

; This seems to be reinitializing variables to the ignition-ON state. It is
; called during startup, by the Inertia Sense routine and by the Coolant
; Temperature routine.
; ------------------------------------------------------------------------------
reInitVars          lda       #$FF                ; init engine PW values to $FFFF
                    tab                           ; transfer a to b
                    std       ignPeriod           ; init to $FFFF
                    std       ignPeriodFiltered   ; init to $FFFF
                    lda       #$11
                    sta       $0085               ; set X0085.4 (0 = end of ADC list)
; set X0085.0 (1 = RPM < 505 or 375 for CWC)
                    ldd       #$00C0              ; 192 decimal (double inj rate for 192 sparks)
                    std       doubleInjecterRate  ; note that this does not need to be 2-bytes
                    clra
                    tab
                    std       engineRPM           ; set engineRPM to zero
                    sta       iacvValue2          ; clear stepper motor variable
                    sta       iacvValue0          ; clear stepper motor variable
                    lda       $0087
                    anda      #$02                ; clr X0087 except bit 1
                    sta       $0087
                    lda       $0088
                    anda      #$9E                ; clr X0088 bits 6, 5 and 0
                    sta       $0088
                    lda       bits_008C
                    anda      #$FD                ; clr bits_008C.1 (delay bit for double inj. pulses)
                    sta       bits_008C
                    lda       #$32                ; init X0069 to $32 (MAF based adj. value)
                    sta       $0069
                    ldd       $C1FC               ; data value is $00C8 (200 dec)
                    std       $2013               ; init right O2 sample counter
                    std       $2015               ; init left O2 sample counter
                    ldd       #$FFFF
                    std       $2017               ; right value (2017) = -1, left value (2018) = -1
                    ldd       $C7C8               ; value is $EA60 (60000)
                    std       throttlePotCounter
                    lda       #$01
                    sta       $2045               ; X2045 is unused
                    lda       bits_2038
                    anda      #$7F                ; clr bits_2038.7 (also unused)
                    sta       bits_2038
                    lda       $008B
                    anda      #$DF                ; clr X008B.5 (throttle closing bit)
                    sta       $008B
                    lda       bits_205B
                    anda      #$7F                ; clr bits_205B.7 (TPS routine, controls 1-time code)
                    sta       bits_205B
                    ldd       $C240               ; value is $0032 (50 dec)
                    std       rpmIndicatorDelay   ; init rpmIndicatorDelay to $0032
                    lda       bits_2059
                    anda      #$9F                ; clr bits_2059.6 and bits_2059.5 (related ICI bits?)
                    sta       bits_2059
                    clr       iciStartupCounter   ; used at start of ICI
                    rts

; ------------------------------------------------------------------------------
