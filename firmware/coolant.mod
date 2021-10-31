; ------------------------------------------------------------------------------
; 14CUX Firmware Rebuild Project

; File Date: 14-Nov-2013

; Description:
; ADC Routine - Coolant temperature - Channel 4 (8-bit conversion)

; ADC service routines are entered with the newly measured ADC value in
; X00C8/C9 (only X00C9 for 8-bit readings). The A accumulator also contains
; the 8-bit reading.

; Location X2079 is zeroed at startup and should remain zero as long as
; coolant sensor works OK. If coolant sensor is bad, the default value of
; $70 is used 19 times out of 20 and the actual sensor value is used the
; 20th time.

; When checking the range of the ECT counts, the addition of $04 ($08 for
; Griff) checks for exceeded limits at both ends of the sensor. For example,
; adding $04 and checking for a minimum of $08 checks for a low count
; minimum of $04 but it also checks for a high count maximum of $FC which
; is -4 in two's complement, since the value would wrap and look like a
; small positive number.

; From Land Rover Docs:

; The ECTS is a resistor based sensor. As coolant temperature increases,
; sensor resistance decreases. The ECM uses this information for hot and
; cold start strategies that require additional fuel delivery. It also uses
; this information to help determine when to enter closed loop operation.
; A diagnostic trouble code (14) is stored when the signal is out of range
; (0.15V to 4.9V) for longer than 160 milliseconds. The MIL will illuminate
; and the ECM will substitute a default value of 36 degrees C (97 F).

; ------------------------------------------------------------------------------

adcRoutine4         tab                           ; xfer ECT reading from A to B

                    #ifdef    BUILD_R3360_AND_LATER
                    addb      #$04                ; add 4 (desensitized value)
                    cmpb      #$08                ; compare with 8 (desensitized value)
                    #else
                    addb      #$08                ; add 8 (original value)
                    cmpb      #$10                ; compare with 16 (original value)
                    #endif

                    bhi       .LD116              ; branch ahead if ECT count is OK

                    lda       $C0CD               ; for R3526, this value is $70
                    jsr       setTempTPFaults     ; <-- Set Fault Code 14 (eng. coolant temp)
                    ldb       #$14                ; reset counter to 20 decimal
                    stb       ectFaultCounter     ; ECT fault down-counter (only used in this routine)

.LD116              ldb       ectFaultCounter     ; load counter
                    beq       .LD122              ; branch ahead if counter is zero (ECT sensor is OK)

                    decb                          ; X2079 is non-zero so decrement it
                    stb       ectFaultCounter     ; store it
                    lda       $C0CD               ; and use default value ($70)

.LD122              sta       coolantTempCount    ; store ECT count
                    ldb       bits_2047
                    orb       #$10                ; set bits_2047.4
                    stb       bits_2047
; --------------------------------------------------------------------
; Calculate 'coolantTempAdjust'

; 'coolantTempAdjust' is added into the fuel calculation in the
; ICI (a.k.a. spark interrupt). It is the fueling component that
; slowly reduces as the engine warms (think choke).

; The value is calculated using the 3 row by 8 column data table.
; The default (limp home) table is at XC0B5. The fuel map specific
; table is at offset $E2 from the fuel map base ponter.

; Example for map 5: $C6AF + $E2 = $C791
; --------------------------------------------------------------------
                    ldx       #$C0B5              ; load address of limp home data table
                    ldb       fuelMapNumber       ; load fuel map number
                    beq       .LD13A              ; branch ahead if it's zero

                    ldx       fuelMapPtr          ; else, load fuel map base pointer
                    ldb       #$E2                ; load $E2
                    abx                           ; add B to X to create table address

.LD13A              ldb       #$08                ; this is the table width (columns)
                    jsr       indexIntoTable      ; index into table based on ECT counts (A is preserved)
                    suba      $00,x               ; subtract 1st row value
                    ldb       $10,x               ; load 3rd row value from table
                    mul                           ; multiply A * B
                    asld                          ; mpy by 2
                    asld                          ; mpy by 2
                    adda      $08,x               ; add 2nd row value
                    sta       coolantTempAdjust   ; and store the result

; ----------------------------------------------------------
; this is the only call to this subroutine
                    jsr       LF4C1               ; it uses the 'lambdaReading' and adjusts
; X201B and X201C (added to O2 reference value)
; ----------------------------------------------------------
; This calls the main purge valve timer subroutine
; ----------------------------------------------------------
                    sei                           ; set interrupt mask
                    lda       $0085               ; load bit value
                    bita      #$10                ; test X0085.4 (init to 1, 0 means ADC list finished at least once))
                    bne       .LD157              ; if set, branch to skip the purge valve subroutine
                    jsr       purgeValve          ; this is the only place this subroutine is called
.LD157              cli                           ; clear interrupt mask

; ----------------------------------------------------------
; If engine is running, clear a couple of bits and return
; ----------------------------------------------------------
                    ldb       $0085               ; load this bits value again
                    lda       port1data           ; load mpu port 1
                    bita      #$40                ; test P1.6 (fuel pump relay)
                    bne       .LD191              ; branch ahead if high (fuel pump OFF)

                    lda       ignPeriodFiltered   ; load MSB of filtered ignition period
                    cmpa      #ignPeriodEngStart  ; compare with $3A (505 RPM) or $4E (375 RPM) for cold weather chip
                    bcc       .LD16E              ; branch ahead if eng RPM is lower than this

; <-- eng is running
.LD166              andb      #$7E                ; clr X0085.7 and X0085.0 (eng spd GT 505 or 375)
                    stb       $0085
                    clr       ectCounter          ; clear up-counter
                    rts                           ; and return

; ----------------------------------------------------------
; This code stops executing once engine starts and RPM
; exceeds 505 (or 375 for CWC)
; ----------------------------------------------------------
.LD16E              bitb      #$01                ; test X0085.0
                    beq       .LD175              ; branch ahead if 0085.0 is zero
                    jmp       .LD1F5              ; jump if 0085.0 is set

; code gets here when eng RPM is LT 505 and 0085.0 is clr
.LD175              cmpa      #$94                ; compare ignition pulse MSB with $94 (198 RPM)
                    bcs       .LD166              ; branch up RPM > 198 (to clr 0085 bits and return)

                    lda       ectCounter          ; RPM < 198, load upcounter
                    inc       ectCounter          ; increment the upcounter
                    cmpa      #$FF
                    bcs       .LD18C              ; branch ahead if counter is LT $FF

                    lda       bits_2047
                    anda      #$DF                ; clr bits_2047.5 (to indicate RPM < 350)
                    sta       bits_2047
                    bra       .LD1F5

.LD18C              andb      #$7F                ; clr 0085.7 (eng spd GT 505 or 375)
                    stb       $0085
                    rts

; ----------------------------------------------------------
; Code branches here when fuel pump is OFF
; ----------------------------------------------------------
.LD191              lda       bits_2047
                    anda      #$DF                ; clr bits_2047.5 (indicates eng RPM > 350 RPM)
                    sta       bits_2047
                    lda       $0087
                    bita      #$04                ; test X0087.2 (usually set)
                    beq       .LD1A2
                    jsr       reInitVars          ; a memory init routine
; ----------------------------------------------------------
; Stepper Motor Code
; ----------------------------------------------------------
.LD1A2              lda       bits_2059
                    bita      #$08                ; test bits_2059.3
                    beq       .LD1F3              ; if zero, branch down to skip stepper motor code

                    lda       $C17E               ; inside coolant temp table (value is $23 or 87 C)
                    adda      #$05                ; $23 + 5 = $28 (82 degrees C)
                    cmpa      coolantTempCount    ; compare with actual coolant temperature
                    bcc       .LD1F3              ; branch if coolant temp is hotter

                    lda       bits_2059
                    anda      #$F7                ; clr bits_2059.3
                    sta       bits_2059
                    lda       iacPosition         ; stepper motor position (0 = open, 180 = closed)
                    adda      #$14

                    sei                           ; set interrupt mask
                    sta       iacMotorStepCount   ; abs value of stepper mtr adjustment
                    lda       $008A
                    anda      #$FE                ; clr X008A.0 (stepper mtr direction bit, 0 = open)
                    sta       $008A
                    lda       bits_2047
                    ora       #$80                ; set bits_2047.7
                    sta       bits_2047

;*** Start Loop ***
.LD1CF              jsr       driveIacMotor       ; stepper motor routine
                    jsr       keepAlive           ; Toggle P17 stay alive
                    lda       iacMotorStepCount   ; abs value of stepper mtr adjustment
                    bne       .LD1CF              ;*** End Loop ***

                    ldd       #$8001
                    std       stepperMtrCounter   ; reset stepperMtrCounter to $8001
                    sta       iacvVariable        ; reset iacvVariable to $80 (zero point)
                    sta       iacvValue1          ; reset iacvValue1 to $80
                    ldd       #$0000
                    std       faultCode26Counter  ; reset road speed counter (lean mixture)
                    lda       bits_2047
                    anda      #$7F                ; clear bits_2047.7
                    sta       bits_2047
                    cli                           ; clear interrupt mask
; ----------------------------------------------------------
; Engine not running
; (code branches here to skip stepper motor section)
; ----------------------------------------------------------
.LD1F3              ldb       $0085
; code jumps here if RPM < 505 and X0085.0 is set
.LD1F5              orb       #$81                ; set X0085.7 and X0085.0
                    andb      #$9F                ; clr X0085.6 and X0085.5
                    stb       $0085               ; (X0085.6 is the engine started flag)
                    lda       $008A
                    ora       #$40                ; set X008A.6 (cleared after table value timeout)
                    sta       $008A
                    clrb
                    stb       idleSpeedDelta      ; reset idle speed adjustment to zero
; ----------------------------------------------------------
; Use coolant temperature measured at time of ECU power-on
; to initialize X009B and 'startupFuelTime' using the
; 3 row x 12 column data table.
; Map 0 address = XC0D0
; Map 1-5 address = base ptr + $BE

; 2nd row in table is cranking fuel value
; 3rd row in table is the time based fuel (1Hz countdown)
; ----------------------------------------------------------
                    ldx       #$C0D0              ; addr of default 3 x 12 data table
                    ldb       fuelMapNumber       ; load fuel map number
                    beq       .LD212              ; branch ahead if map num is zero
                    ldx       fuelMapPtr          ; load base ptr to fuel map
                    ldb       #$BE                ; load fuel map offset
                    abx                           ; add B to X (example: $C6AF + $BE = $C76D)

.LD212              ldb       #$0C                ; 12 values per row in table
                    lda       coolantTempCount    ; ECT sensor count
                    jsr       indexIntoTable      ; using ECT count, index into table
                    ldb       $18,x               ; load B with 3rd row value
                    lda       $0C,x               ; load A with 2nd row value
                    std       $009B               ; store both bytes (B into X009B, A into startupFuelTime)
                    rts                           ; return
