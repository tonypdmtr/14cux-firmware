; ------------------------------------------------------------------------------
; 14CUX Firmware Rebuild Project

; File Date: 14-Nov-2013

; Description:
; ADC Routine - Inertia Switch - Channel 0 (8-bit conversion)

; ADC service routines are entered with the newly measured ADC value in
; X00C8/C9 (only X00C9 for 8-bit readings). The A accumulator also contains
; the 8-bit reading.

; This ADC service routine is for the fuel pump supply voltage through the
; inertia switch. It comes in at Pin 19 of the 40-pin connector. Besides
; being measured by the ADC here, it is also routed through I3 and to the
; MPU /Reset line. Removal of voltage from Pin 19 causes the 14CUX to go
; into reset after a small delay (about 5 seconds). This shuts off the main
; relay.

; X0085.2 is only set in this routine and is used to indicate that the
; shutdown sequence has started.

; The measured voltage must be below the threshold for 50 consecutive
; samples for the shutdown sequence to start.

; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; This routine is 'jumped to' at the end of the main inertia switch routine
; below. This routine then jumps to the top of the main loop. This is basically
; the ignition-ON state (waiting for restart).
; ------------------------------------------------------------------------------
.LCFBA              lds       #$00FF              ; re-init stack
                    lda       #$C0
                    sta       ramControl          ; set RAME and reliability bits
                    clr       fuelPumpTimer
                    lda       port1data
                    anda      #$BF                ; P1.6 low (fuel pump ON)
                    sta       port1data
                    jsr       reInitVars          ; memory init routine
                    lda       $0085
                    ora       #$81                ; set 0085.7 and 0 (indicates no or low engine RPM)
                    sta       $0085
                    jmp       LCB2A               ; jump to top of main executive loop

; ------------------------------------------------------------------------------

; ADC Routine - Inertia Switch - Channel 0 (8-bit conversion)

; ------------------------------------------------------------------------------

adcRoutine0         ldb       $0085               ; load X0085 bits value
                    bitb      #$04                ; test X0085.2 (1 = shutdown sequence has started)
                    bne       .LD053              ; branch ahead if shutdown has already started

                    cmpa      #$1F                ; compare measured voltage with $1F
                    bcc       .LCFEA              ; branch ahead if > $1F (normal path)

; if here, voltage dropped below thrshold
                    ldb       inertiaCounter      ; local counter
                    incb                          ; increment the delay counter
                    cmpb      #50                 ; compare with 50 decimal
                    bhs       .LCFEE              ; if counter >= 50, branch to start shutdown

                    stb       inertiaCounter      ; count < 50, so just store it
                    rts                           ; and return

; ----------------------------------------------------------

.LCFEA              clr       inertiaCounter      ; clear counter
                    rts                           ; and return (normal path)

; -----------------------------------------------------------
; Start of Shutdown Sequence
; -----------------------------------------------------------
.LCFEE              sei                           ; set interrupt mask
                    ldb       fuelTempCount       ; load EFT sensor count
                    cmpb      hiFuelTempThreshold  ; compare with data value XC0B4 ($65 = 40 deg C)
                    bcs       .fuelTempHi         ; branch if fuel temperature is warmer than this
                    ldb       #$00                ; else load zero

.fuelTempHi         stb       hiFuelTemperature   ; store at X0048 (battery-backed value)
                    ldb       $0088               ; load bits value
                    bitb      #$04                ; test X0088.2 (set when eng starts, never cleared)
                    bne       .LD005              ; branch if bit is high (branch if eng running)

; if here, eng not running
                    lda       $0054               ; load working value of Throttle Pot Minimum (TPmin)
                    sta       $0052               ; store TPmin in battery backed RAM

.LD005              lda       bits_2047           ; load bits value
                    bita      #$04                ; test bits_2047.2 (VSS fail bit)
                    bne       .copyRAM            ; branch if road speed sensor is bad

                    bita      #$40                ; test bits_2047.6 (this bit is normally low)
                    beq       .copyRAM            ; branch if bit is low

                    jsr       LF7A5               ; this subroutine is called only here, this is the only place
; where battery backed location stprMtrSavedValue is written

.copyRAM            ldx       #externalRAMCopy-1  ; copy internal to external RAM, the software
                    lds       #batteryBackedRAM-1  ; tries to keep these areas synchronized

.copyRAMLoop        inx                           ; <-- Start Copy Loop
                    pula
                    sta       $00,x
                    cpx       #$2073
                    bne       .copyRAMLoop        ; <-- End Copy Loop

                    lds       #$00FF              ; reset stack ptr

                    ldb       $008B
                    bitb      #$40                ; test X008B.6 (1 = main voltage OK, 0 = low voltage)
                    beq       .LD09C              ; branch ahead if bit is zero (low voltage)

                    ldb       $008A
                    andb      #$FE                ; clr X008A.0 (stepper mtr direction bit, 0 = open)
                    stb       $008A
                    ldb       #200                ; load B with 200 decimal
                    stb       iacMotorStepCount   ; store the number of counts to move stepper motor
                    ldb       $0085               ; load X0085 bits value
                    orb       #$04                ; set X0085.2 (to indicate start of shutdown sequence)
                    andb      #$9F                ; clr X0085.6 and X0085.5 (clear some housekeeping bits)
                    stb       $0085               ; store X0085 bits value
                    lda       bits_2047
                    anda      #$DF                ; clr bits_2047.5 (this bit is set when eng RPM > 350)
                    sta       bits_2047
                    lda       $0087
                    anda      #$FB                ; clr X0087.2 (code control bit?)
                    sta       $0087
                    lda       bits_2047
                    ora       #$80                ; set bits_2047.7 (controls timer in stepper mtr routine)
                    sta       bits_2047

; ------------------------------------------------
; Code branches here from above if the shutdown
; sequence has already started (X0085.2 is set)

; This section winds back the stepper mtr
; and leaves it in the $87 position.
; ------------------------------------------------
; Open the IACV (stepper motor)
.LD053              jsr       driveIacMotor       ; stepper motor routine
                    jsr       keepAlive           ; toggle stay-alive
                    ldb       iacMotorStepCount   ; load number of counts (init to 200 earlier)
                    bne       .LD053              ;*** end SM loop

                    ldd       #$8001
                    std       stepperMtrCounter   ; reset stepperMtrCounter to $8001
                    sta       iacvVariable        ; reset iacvVariable to $80 (zero point)
                    sta       iacvValue1          ; reset iacvValue1 to $80 (zero point)
                    ldd       #$0000
                    std       faultCode26Counter  ; reset road speed (distance) counter
                    ldb       iacvDriveValue      ; stepper motor drive value
                    cmpb      #$87                ; $87 is 1 of 4 drive values and is the default
                    beq       .checkHiTemps       ; set stepper motor to position $87 before leaving loop

                    ldb       #$01                ; not $87, so move 1 more step
                    stb       iacMotorStepCount   ; store 1
                    bra       .LD053              ; branch back to move stepper motor 1 more step

.checkHiTemps       lda       bits_2047
                    anda      #$7F                ; clr bits_2047.7 (controls timer in stepper mtr routine)
                    sta       bits_2047
; -----------------------------------------
; If ECT and EFT sensors indicate very hot
; turn on the condenser fan timer
; -----------------------------------------
                    lda       coolantTempCount    ; load ECT sensor count
                    cmpa      hotCoolantThreshold  ; value from XC1EF ($14 = 102 deg C)
                    bcc       .shutdownRamChk     ; branch ahead if eng temp is cooler than this

                    lda       fuelTempCount       ; engine is very hot, load EFT sensor count (fuel tmep)
                    cmpa      hotFuelThreshold    ; value from XC1F0 ($34 = 70 deg C)
                    bcc       .shutdownRamChk     ; branch ahead if underhood temp is cooler than this

                    lda       port1data           ; Port P13 is condensor fan timer (high = OFF)
                    anda      #$F7                ; ground condenser fan timer to run fans for ~10 minutes
                    sta       port1data
; -----------------------------------------
; Update checksum for battery area
; -----------------------------------------
.shutdownRamChk     jsr       calcBatteryBackedChecksum  ; update the checksum for battery-backed RAM
                    sta       ramChecksum         ; store it in the last location (X0053)

.LD09C              ldb       #$80                ; set Standby Pwr bit to indicate RAM OK
                    stb       ramControl          ; and clear RAM Enable bit (RAME) to disable access
                    sei                           ; set interrupt mask again (a subroutine cleared it??)

; -----------------------------------------
; Loop and wait for shutdown, or restart
; if voltage returns.
; ------------------------------------------------------------------------------
.LD0A1              lda       #$80                ; <-- Start Loop
                    sta       AdcControlReg1      ; trigger ADC to measure Inertia Switch voltage

.LD0A6              lda       port1data           ; Start Inner Loop (to wait for result)
                    eora      #$80                ; Toggle P1.7 (stay alive)
                    sta       port1data
                    ldb       AdcStsDataHigh      ; load status reg
                    bitb      #$40                ; test ADC busy flag
                    bne       .LD0A6              ; branch back if ADC conversion not done

                    lda       AdcDataLow          ; read ADC result (low 8 bits only)
                    cmpa      #$2A                ; compare with $2A
                    bcc       .LD0BD              ; branch to restart if voltage is > $2A
                    jmp       .LD0A1              ; <-- End Loop (loop back and wait for shutdown)

; ------------------------------------------------------------------------------
.LD0BD              jmp       .LCFBA              ; jump to restart

; ------------------------------------------------------------------------------
