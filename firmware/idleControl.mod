; ------------------------------------------------------------------------------
; 14CUX Firmware Rebuild Project

; File Date: 14-Nov-2013

; Description:
; Ther are 3 main subroutines in this file, all having to do with
; control of the stepper motor (Idle Air Control Valve).

; LD609 - Returns engine coolant temp based idle delta.

; LD613 - Large subroutine called by main loop.

; driveIacMotor - Stepper motor routine

; LDAD3 - Stepper motor drive subroutine called by driveIacMotor

; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; This routine is called from below to accumulate the engine idle target speed.
; It falls thru to the routine at LD609 but the results aren't used until D602
; is called immediately after D609.
; ------------------------------------------------------------------------------
.LD602              addd      $00CE
                    std       $00CE
                    std       targetIdleRPM

; ------------------------------------------------------------------------------
; Return Engine Coolant Temperature based idle delta.

; This is called from a couple of places in the Throttle Pot routine and
; from 1 place below. It returns the idle speed delta based on coolant temp.
; Range is about 300 cold to zero hot.

; if ECT < $27 (hot)  --> return 0x0000 in AB
; if ECT > $27 (cool) --> return 2 * (ECT - $27) in AB

; ECT of $27 is about 83 C or 181 F
; ------------------------------------------------------------------------------

LD609               ldb       coolantTempCount    ; load ECT sensor counts
                    subb      #$27                ; compare with $27
                    bcc       .LD610              ; branch ahead if ECT >= $27 (cooler than)
                    clrb                          ; return 0-0 (when ECT is hotter than $27)

; <-- cooler than $27
.LD610              clra                          ; clear A
                    asld                          ; return (2 * (ECT - $27))
                    rts

; ------------------------------------------------------------------------------

; This is an idle control subroutine

; This routine is called from 2 places:
; 1) Main loop when mux list ends
; 2) New AMR code (every 80th time thru)

; The interrupt mask is set before calling this and cleared after.

; ------------------------------------------------------------------------------

; ----------------------
; Calculate target idle
; ----------------------
idleControl         ldd       baseIdleSetting
                    std       $00CE               ; general purpose location
                    lda       $008A               ; bits
                    bita      #$08                ; test 008A.3 (A/C related, usually set in road tests)
                    bne       .LD623              ; branch ahead if bit is set (meaning A/C is off)
                    ldd       idleAdjForAC
                    bsr       .LD602              ; branch to subroutine above to write value

.LD623              ldb       $008A
                    bitb      #$20                ; test 008A.5 (0 = neutral or D90, 1 = drive for RR))
                    bne       .LD62E              ; branch ahead if bit is set
                    ldd       idleAdjForNeutral
                    bsr       .LD602              ; branch to subroutine above to add value and write

.LD62E              ldb       $00DD               ; bits value
                    bitb      #$04                ; test 00DD.2 (heated screen sense, 1=OFF, 0=ON)
                    bne       .LD639              ; branch ahead if bit is set
                    ldd       idleAdjForHeatedScreen
                    bsr       .LD602              ; branch to subroutine above to add value and write

.LD639              bsr       LD609               ; rtns coolant temp based idle delta (range zero to ~300)
                    bsr       .LD602              ; branch to sub (above) to add value and write

                    ldb       $C158               ; only referenced here, value is $05
                    stb       $00C9               ; see D717
; -----------------------------------------------------------
; Compare target idle against actual engine RPM
; ----------------------------------------------------------- ; *** start new code
                    lda       bits_2059
                    bita      #$10                ; test bits_2059.4 (stepper motor or idle related)
                    beq       .LD657              ; branch ahead if bit is low
                    ldd       $00CE               ; load current idle speed target
                    subd      engineRPM
                    bcs       .LD657              ; branch ahead if eng speed is GT idle target
; if here, idle is lower than target
                    subd      $C7D8               ; value is 100 decimal (subtract additional 100 from result)
                    bcs       .LD657              ; branch ahead if eng speed is LT target by less than 100
                    clr       idleSpeedDelta      ; clr idle speed delta if GT 100 RPM??
; -----------------------------------------------------------
; This is the calculation of 'iacvEctValue'. This is a
; coolant temperature based value that has something to do
; with idle control. This code is similar to the separate
; subroutine that was added later at XF9A1.
; -----------------------------------------------------------
.LD657              ldx       #$C17B              ; coolant temperature table
                    lda       coolantTempCount
                    ldb       #$09                ; data table length is 9
                    jsr       indexIntoTable      ; modifies index, A is preserved
                    suba      $00,x               ; subtract indexed value from A (coolant temperature)
                    pshb                          ; B is now $09 or less (but not less than zero)
                    ldb       $12,x               ; load B from 3rd row of data table
                    mul                           ; mpy remainder by 3rd row table value
                    asld
                    asld                          ; multiply by 4
                    pulb                          ; pul B (index), A is math result
                    cmpb      #$08                ; compare index with 08
                    bcs       .LD672              ; branch ahead if B LT 08
                    adda      $09,x               ; add value from 2nd row of data table
                    bra       .LD675              ; and branch ahead to store and return

.LD672              suba      $09,x               ; subtract value from 2nd row of data table
                    nega

.LD675              tab
                    stb       iacvEctValue        ; store calculated coolant temp related value
; -----------------------------------------------------------
; Check some things to see if idle control is needed.
; -----------------------------------------------------------
                    lda       $0085               ; bits value
                    bita      #$04                ; test 0085.2 (set and tested in IS routine)
                    bne       .LD690              ; rtn if 0085.2 is set
                    bita      #$80                ; test 0085.7 (may indicate low eng RPM)
                    beq       .LD691              ; branch ahead if 0085.7 is clr (engine running)
                    ldb       ignPeriod
                    cmpb      $C16F               ; for 3360 code, value is $53 (353 RPM)
                    bcs       .LD691              ; branch ahead & continue if engine PW is LT $5300 (RPM > 353)
                    ldb       coolantTempCount
                    cmpb      $C17E               ; inside coolant temp table (value is $23)
                    bcs       .LD691              ; branch ahead & continue if coolant temp is LT $23 (hotter than)

.LD690              rts

; ------------------------------------------------------------------------------
; There are 3 branches to here from above.
; Code gets here if eng is running (RPM > 353) and coolant temp is hotter than
; 35 decimal.
; ------------------------------------------------------------------------------
; only branches are from D680, D687 and D68E (just above)
.LD691              ldb       $0087
                    bitb      #$04                ; test 0087.2 (stays set for both RTs)
                    beq       .LD6BD              ; branch ahead if bit 2 is zero

                    bita      #$02
                    bne       .LD6BA              ; branch ahead to jmp if 0085.1 is set
                    ldb       ignPeriod
                    cmpb      $C16F               ; for 3360 code, value is $53 (353 RPM)
                    bcc       .LD690              ; branch up (to rts) if engine PW is GT $5300 (RPM < 353)
                    ora       #$02                ; set 0085.1 (isn't this unnecessary? already set)
                    sta       $0085
                    ldb       neutralSwitchVal
                    cmpb      #$4D                ; cmpr with $4D
                    bcs       .LD6B9              ; rtn if neutral switch is LT $4D (in drive for RR)
                    cmpb      #$B3                ; cmpr with $B3

                    #ifdef    BUILD_R3360_AND_LATER
                    bcc       .LD6B9              ; rtn if neutral switch is GT $B3 (in park for RR)
                    #else
                    bcc       .LD6B9A             ; rtn if neutral switch is GT $B3 (in park for RR)
                    #endif
                    ldb       bits_2004
                    orb       #$02                ; set 2004.1 when middle voltage at neutral switch (manual tranny?)
                    stb       bits_2004

                    #ifdef    BUILD_R3360_AND_LATER
.LD6B9              rts

                    #else
.LD6B9              lda       bits_201F
                    anda      #$DF                ; clear bits_201F.5
                    sta       bits_201F

.LD6B9A             rts

                    #endif

; ------------------------------------------------------------------------------
; the branch above (D699) is the only reference
.LD6BA              jmp       .LD73D              ; jump down to next section

; ------------------------------------------------------------------------------
; LD695 is the only way to get here (0087.2 must be zero)
; ------------------------------------------------------------------------------
; code above branches here if 0087.2 is zero
.LD6BD              lda       $008A
                    bita      #$02                ; test 008A.1 (set in fuel temp routine, always 1 per RR)
                    bne       .LD6D9              ; branch ahead if 008A.1 is set
                    bita      #$08                ; test 008A.3 (changes per RR)
                    bne       .LD6CE              ; branch ahead if 008A.3 is set
                    lda       coolantTempCount
                    cmpa      $C17E               ; inside coolant temp table (value is $23)
                    bcc       .LD6D9              ; branch ahead if coolant temp is GT (cooler than) $23

.LD6CE              ldx       $C0B0               ; for 3360, value is #0002
                    ldd       hotFuelAdjustmment

.LD6D3              dex
                    beq       .LD6DA              ; this loops and does one asld (it's probably zero anyway)
                    asld
                    bra       .LD6D3

.LD6D9              clra

.LD6DA              ldb       $008A
                    bitb      #$08                ; test 008A.3
                    beq       .LD6ED
                    ldb       coolantTempCount
                    cmpb      $C17D               ; coolant temp table value
                    bcs       .LD6ED
                    cmpa      #$0C
                    bcs       .LD6ED
                    lda       #$0C

.LD6ED              adda      $C15D               ; value is $20
                    sta       $00C8

                    lda       iacvEctValue        ; calc value based on coolant temp (100 -> 160)
                    ldb       stprMtrSavedValue   ; load battery backed value
                    bpl       .LD701              ; branch forward if stprMtrSavedValue.7 is zero
; stprMtrSavedValue is neg
                    andb      #$7F                ; clr bit 7
                    aba                           ; add B to A
                    bcc       .LD70A
                    lda       #$FF                ; limit value to $FF
                    bra       .LD70A

; stprMtrSavedValue is pos
.LD701              ldb       #$80
                    subb      stprMtrSavedValue
                    sba                           ; subtract B from A
                    bcc       .LD70A
                    lda       #$00

.LD70A              tab                           ; xfer A to B
                    subb      $00C8
                    bcc       .LD711
                    ldb       #$01

.LD711              lda       $008A
                    bita      #$20                ; test 008A.5
                    beq       .LD71D
                    subb      $00C9               ; value is still 5 ? (see D642)
                    bcc       .LD71D
                    ldb       #$01
; B is new stepper mtr target
.LD71D              subb      iacPosition
                    lda       $008A
                    bcc       .LD728              ; if carry clr, B was GT IAC position, close SM
;*** Open stepper motor ***
                    negb                          ; carry set, result is neg, open SM
                    anda      #$FE                ; clr 008A.0 (stepper mtr direction bit, 0 = open)
                    bra       .LD72A

;*** Close stepper motor ***
.LD728              ora       #$01                ; set 008A.0 (stepper mtr direction bit, 1 = close)

.LD72A              sta       $008A
                    stb       iacMotorStepCount
                    lda       $0087
                    ora       #$04                ; set 0087.2 (stays set for both RTs, probably for 1-time code)
                    sta       $0087
                    lda       bits_2059
                    ora       #$08                ; set bits_2059.3
                    sta       bits_2059

.LD73C              rts

; ------------------------------------------------------------------------------
; Only path here is jump at D6BA (above) (if 0085.1 is set)
; ------------------------------------------------------------------------------
; dest of a jmp above
.LD73D              lda       iacMotorStepCount
                    bne       .LD73C              ; return if not zero
                    ldb       iacvWorkingValue    ; (1 of 5) zero for D90, high & low (or signed) numbers for RR
                    lda       $00DD
                    bita      #$04                ; test 00DD.2 (related to heated screen?)
                    bne       .LD756
                    bita      #$02                ; test 00DD.1 (related to heated screen?)
                    bne       .LD761
                    ora       #$02                ; set 00DD.1
                    sta       $00DD
                    addb      $C1EB               ; value is $08, add to 'iacvWorkingValue'
                    bra       .LD761

.LD756              bita      #$02                ; test 00DD.1
                    bne       .LD761
                    ora       #$02                ; set 00DD.1
                    sta       $00DD
                    subb      $C1EB               ; value is $08, subtract from 'iacvWorkingValue'

.LD761              lda       $008A
                    bita      #$08                ; test 008A.3 (possibly A/C related)
                    bne       .LD774
                    bita      #$04
                    bne       .LD772
                    ora       #$04                ; set 008A.2
                    sta       $008A
                    subb      $C157               ; value is $1A (26d), subtract from 'iacvWorkingValue'

.LD772              bra       .LD77F

.LD774              bita      #$04                ; test 008A.2
                    bne       .LD77F
                    ora       #$04                ; set 008A.3
                    sta       $008A
                    addb      $C157               ; value is $1A (26d), 'add to iacvWorkingValue'

.LD77F              bita      #$20                ; test 008A.5 (neutral switch?)
                    bne       .LD78F
                    bita      #$10                ; test 008A.4 (neutral switch?)
                    bne       .LD78D
                    ora       #$10                ; set 008A.4
                    sta       $008A
                    addb      $00C9               ; value is still 5 ?

.LD78D              bra       .LD7A8

.LD78F              bita      #$10
                    bne       .LD7A8
                    ora       #$10                ; set 008A.4
                    sta       $008A
                    subb      $00C9               ; value is still 5 ?
                    psha
                    lda       $C7DA               ; val is $18 (24d)
                    sta       idleSpeedDelta
                    lda       bits_2059
                    anda      #$EF                ; clr bits_2059.4 (stepper mtr or idle related bit)
                    sta       bits_2059
                    pula

.LD7A8              stb       iacvWorkingValue    ; (2 of 5)
                    clrb
                    bita      #$08
                    bne       .LD7B2
                    addb      $C157               ; value is $1A (26d)

.LD7B2              bita      #$20
                    beq       .LD7B8
                    addb      $00C9               ; value is still 5 ?

.LD7B8              lda       $00DD
                    bita      #$04                ; test 00DD.2
                    beq       .LD7C1
                    addb      $C1EB               ; value is $08

.LD7C1              stb       iacvAdjustSteps     ; values 0, 5, 26 and 31 (only written here)
                    ldb       bits_2047
                    lda       ignPeriod
                    cmpa      $C16F               ; value is $53 (353 RPM)
                    bcc       .LD7D2              ; branch ahead if engine PW is GT $5300 (RPM < 353)
                    orb       #$20
                    stb       bits_2047           ; set bits_2047.5 (indicates eng RPM GT 350)

.LD7D2              lda       $0085               ; bits
                    bitb      #$20                ; test bits_2047.5 (indicates eng RPM GT 350)
                    beq       .LD805              ; branch down if eng RPM LT 350 (eng not running)
                    bita      #$20                ; test 0085.5
                    bne       .LD7F0

                    ora       #$20                ; set 0085.5
                    sta       $0085
                    lda       $0054               ; throttle pot min
                    sta       $0052               ; throttle pot min (battery saved)
                    lda       $0088
                    ora       #$04                ; set 0088.2
                    sta       $0088
                    lda       $C151               ; val is $32 (50 decimal)
                    sta       idleSpeedDelta
                    rts

; ------------------------------------------------------------------------------
; Only path here is LD7DA (above), iacMotorStepCount is zero to get here
; ------------------------------------------------------------------------------
; only branched to from D7DA above (0085 is in A)
.LD7F0              ldb       idleSpeedCounter    ; (1 of 3) load counter (often cycles 5 -> 0)
                    beq       .LD7F9
                    dec       idleSpeedCounter    ; (2 of 3) decrement counter
                    bra       .LD805

.LD7F9              ldb       idleSpeedDelta      ; <- when counter is zero
                    beq       .LD805
                    decb
                    stb       idleSpeedDelta      ; decrement
                    ldb       $C14F               ; val is $05
                    stb       idleSpeedCounter    ; (3 of 3) reset counter to 5

; only from D7D6, D7F7 or fall thru
.LD805              psha
                    lda       $008A
                    ldb       iacvWorkingValue    ; (3 of 5)
                    beq       .LD81B
                    bpl       .LD813
                    negb
                    anda      #$FE                ; clr 008A.0 (stepper mtr direction bit, 0 = open)
                    bra       .LD815

.LD813              ora       #$01                ; set 008A.0 (stepper mtr direction bit, 1 = close)

.LD815              sta       $008A
                    stb       iacMotorStepCount
                    pula
                    rts

; ------------------------------------------------------------------------------
; Only path here is LD80A (above) when 'iacvWorkingValue' is zero
; ------------------------------------------------------------------------------

.LD81B              pula                          ; pull value from 0085 (bits)
                    bita      #$20                ; test 0085.5
                    beq       .LD827              ; rtn if zero
                    ldb       $0086               ; bits value
                    bmi       .LD828              ; branch to next section if 0086.7 is one
                    clr       idleRelatedValue    ; else, clr 'idleRelatedValue' and rtn

.LD827              rts

; ------------------------------------------------------------------------------
; Only path here is D822 (above). Conditionally increments 'idleControlValue'
; ------------------------------------------------------------------------------

.LD828              clr       $00CC
                    lda       $0087
                    bita      #$40                ; test 0087.6 (eng RPM GT theshold)
                    beq       .LD83F              ; branch ahead to continue if 0087.6 is clear
                    lda       $008B
                    anda      #$01                ; isolate 008B.0 (road speed GT 4)
                    bne       .LD827              ; branch to return if road speed is GT 4
                    ldx       idleControlValue    ; starts at -20 and varies to +59
                    beq       .LD83F              ; branch to continue if idleControlValue is zero
                    inx                           ; else increment it and return
                    stx       idleControlValue
                    rts

; ------------------------------------------------------------------------------
; Two paths here:  D82F and D839 (above)
; ------------------------------------------------------------------------------

.LD83F              tst       idleSpeedDelta      ; idle speed adjustment (value is between zero and 40)
                    bne       .LD827              ; if non-zero, branch up to return
                    ldd       $00CE               ; still current idle speed target
                    subd      engineRPM
                    bcc       .LD88E              ; if RPM is LT target, branch down to other section
                    lda       iacvValue2          ; zero for D90, for RR: zero with 4s and 10s
                    beq       .LD866              ; if iacvValue2 is zero, branch ahead

                    lda       $C161               ; value is 0A
                    suba      $C164               ; value is 06
                    sta       iacvValue2          ; this is where the 4 comes from
                    jsr       LEE12               ; deals with iacvValue2 and iacMotorStepCount
                    clr       iacvValue2
                    lda       $C164               ; value is 06
                    sta       iacvValue0          ; occasionally init to 6 and decremented to zero ;
                    ldb       $C165               ; value is $14
                    bra       .LD880

.LD866              lda       iacvValue0
                    beq       .LD88E
                    ldb       $0087
                    bitb      #$40                ; test 0087.6 (eng RPM GT theshold)
                    bne       .LD883
                    deca
                    sta       iacvValue0
                    lda       $008A
                    ora       #$01                ; set 008A.0 (stepper mtr direction bit, 1 = close)
                    sta       $008A
                    lda       #$01
                    sta       iacMotorStepCount
                    ldb       $C166               ; value is 0x0C in 3360 code

.LD880              stb       idleSpeedDelta      ; idle speed adjustment

.LD882              rts

; ------------------------------------------------------------------------------
; Only path here is D86E above (eng RPM > threshold)
; ------------------------------------------------------------------------------

.LD883              sta       iacvValue2
                    jsr       LEE12               ; deals with iacvValue2 and iacMotorStepCount
                    clr       iacvValue0
                    jmp       .LD9D7

; ------------------------------------------------------------------------------

.LD88E              lda       $008B
                    anda      #$01                ; isolate 008B.0 (road speed GT 4)
                    bne       .LD882              ; branch up to rts if road speed is GT 4 KPH

                    lda       bits_0089           ; if here, road speed is low
                    bmi       .LD882              ; rtn if bits_0089.7 is set
                    ldd       ignPeriod
                    subd      $C253               ; for 3360 code, value is $118B (1670 RPM)
                    bcs       .LD882              ; branch up (to rts) if PW is LT $118B (RPM > 1670)

                    jsr       LF7F0               ; the only call to this s/r (may clear unused fault code 26)
                    lda       iacMotorStepCount
                    bne       .LD882              ; rtn if iacMotorStepCount is not zero

                    lda       bits_2047
                    bita      #$01                ; test bits_2047.0 (is this the idle mode bit??)
                    bne       .LD8FC              ; branch way down if bit is set
                    ora       #$01                ; else, set bit
                    sta       bits_2047

; -----------------------------------------------------------
; Calculate 16-bit 'mafVariable'

; (same as code near CC8A)
; this code executes once every time bits_2047.0 is set and
; has to do with idle air control fault
; -----------------------------------------------------------
                    lda       iacvVariable        ; initial (middle) value is 128
                    cmpa      #$80                ; iacvVariable may be for idle air control fault
                    bcc       .LD8DD

; -------------------------------------        ; the code below is similar to something seen elsewhere
                    lda       #$80                ; if iacvVariable is LT 128
                    suba      iacvVariable
                    ldb       $C25C               ; value is 08
                    mul
                    std       $00C8
                    #ifdef    BUILD_R3360_AND_LATER
                    subd      #$05AB
                    bcs       .LD8CE
                    ldd       #$05AB
                    #else
                    subd      #$0640
                    bcs       .LD8CE
                    ldd       #$0640
                    #endif
                    std       $00C8

.LD8CE              ldd       mafLinear
                    subd      $00C8
                    bcc       .LD8D8
                    ldd       #$0000

.LD8D8              std       mafVariable         ; write mafVariable (varies around 600 to 1400)
                    bra       .LD8FC

; -------------------------------------
; if iacvVariable is GTE 128
.LD8DD              suba      #$80
                    ldb       $C25C               ; value is 08
                    mul
                    std       $00C8
                    #ifdef    BUILD_R3360_AND_LATER
                    subd      #$05AB
                    bcs       .LD8EF
                    ldd       #$05AB
                    #else
                    subd      #$0640
                    bcs       .LD8EF
                    ldd       #$0640
                    #endif
                    std       $00C8

.LD8EF              ldd       mafLinear
                    addd      $00C8
                    bcc       .LD8F9
                    ldd       #$FFFF

.LD8F9              std       mafVariable         ; store mafVariable (varies around 600 to 1400)
; -------------------------------------
; end idle air control fault code
; -------------------------------------

.LD8FC              lda       bits_2059
                    bita      #$01                ; test bits_2059.0 (stepper mtr related??)
                    beq       .LD904              ; (bits_2059.0 may have stayed zero for RTs)
                    rts

; ------------------------------------------------------------------------------
; Only path here is D901 (just above)
; ------------------------------------------------------------------------------

.LD904              lda       $0088
                    ora       #$01                ; set 0088.0 (set near eng start and stays set)
                    sta       $0088
                    clra
                    sta       iacvValue2
                    sta       iacvValue0
                    ldd       $00CE               ; still current idle speed target
                    subd      engineRPM
                    bcc       .LD91B              ; branch if eng RPM is lower than target
                    inc       $00CC               ; cleared at D828, incremented to indicate RPM is GT target
                    jsr       absoluteValAB

.LD91B              clr       $00CD               ; AB now contains abs value of delta
; <-- start loop
.LD91E              subd      $C173               ; for 3360, value is #000E, subtract from abs value of idle delta
                    bcs       .LD928              ; branch if delta is LT 14
                    inc       $00CD               ; X00CD is incremented for every 14 counts of idle delta
                    bra       .LD91E              ; <-- end loop

; if here, idle delta is LT 14
.LD928              ldb       $00CD               ; load the (14 increment) counter into B
                    subb      $C175               ; for 3360, value is #01
                    bcc       .LD930
                    clrb                          ; in this case, B is zero anyway

.LD930              cmpb      $C169               ; for 3360 code, value is $14
                    bcs       .LD938
                    ldb       $C169               ; for 3360 code, value is $14

.LD938              stb       $00CD               ; store the 14 increm counter (minus 1) - this is iacMotorStepCount
                    stb       iacMotorStepCount
                    beq       .LD94B

                    clr       idleRelatedValue    ; if here, idle adjustment is needed
                    lda       bits_2059
                    anda      #$EF                ; clr bits_2059.4 (stepper mtr or idle related)
                    sta       bits_2059
                    bra       .LD999

.LD94B              ldb       idleRelatedValue
                    cmpb      $C155               ; for 3360, value is 0xAF
                    bcs       .LD996
                    lda       $C156               ; for 3360, value is 0x28
                    sta       idleSpeedDelta      ; idle speed adjustment
                    lda       bits_2059
                    ora       #$10                ; set bits_2059.4 (stepper mtr or idel related)
                    sta       bits_2059
                    lda       bits_0089
                    anda      #$03                ; isolate bits_0089.1 and bits_0089.0
                    bne       .LD97C              ; branch ahead if either bit is set
                    jsr       LF658               ; the only call to this s/r
                    ldb       bits_2047
                    lda       coolantTempCount
                    cmpa      $C17D               ; val is $1C
                    bcs       .LD977              ; branch ahead if CT is LT $1C (hotter than)
                    cmpa      $C17E               ; inside coolant temp table (value is $23)
                    bcs       .LD97C

.LD977              andb      #$BF                ; clr bits_2047.6 (normally 0)
                    stb       bits_2047

.LD97C              ldb       $00DC
                    bitb      #$08                ; test 00DC.3
                    bne       .LD995
                    orb       #$08                ; set 00DC.3
                    stb       $00DC
                    ldd       purgeValveTimer2    ; load down counter
                    bne       .LD995              ; branch to rtn if not zero
                    ldd       #$0020
                    std       purgeValveTimer2    ; zero, so reset counter to 32 dec
                    lda       bits_008D
                    ora       #$80                ; and set bits_008D.7 (bit went from 0 to 1 during both RTs)
                    sta       bits_008D

.LD995              rts

; ------------------------------------------------------------------------------
; Only path here is D950 (above)
; ------------------------------------------------------------------------------

.LD996              inc       idleRelatedValue

.LD999              lda       $00CC
                    beq       .LD9D1
                    lda       bits_2047
                    bita      #$04                ; test bits_2047.2 (VSS fail bit, normally 0)
                    beq       .LD9CB
                    lda       iacvEctValue        ; calc value based on coolant temp (100 -> 160)
                    adda      iacvObsolete        ; nothing changes this
                    cmpa      #$B4                ; $B4 = 180 dec
                    bcc       .LD9B2
                    adda      #$4B                ; $4B = 75 dec
                    cmpa      #$B5
                    bcs       .LD9B4

.LD9B2              lda       #$B4                ; $B4 = 180d

.LD9B4              suba      iacPosition
                    beq       .LD9C7
                    bcc       .LD9C2
                    lda       #$01
                    sta       $00CD
                    sta       iacMotorStepCount
                    bra       .LD9D1

.LD9C2              ldb       $00CD
                    cba
                    bcc       .LD9CB

.LD9C7              sta       $00CD
                    sta       iacMotorStepCount

.LD9CB              lda       $008A
                    ora       #$01                ; set 008A.0 (stepper mtr direction bit, 1 = close)
                    bra       .LD9D5

.LD9D1              lda       $008A
                    anda      #$FE                ; clr 008A.0 (stepper mtr direction bit, 0 = open)

.LD9D5              sta       $008A

.LD9D7              ldb       $C150               ; value is $2D
                    lda       iacMotorStepCount
                    mul
                    tsta
                    bne       .LD9E5
                    cmpb      $C153               ; value is $1C
                    bcs       .LD9E8

.LD9E5              ldb       $C153               ; value is $1C

.LD9E8              stb       idleSpeedDelta      ; idle speed adjustment
                    rts

; ------------------------------------------------------------------------------
; Stepper Motor Routine

; Active when: Road speed less than 3 mph; Throttle closed; Engine above 50 rpm
; Air valve open = 0 steps
; Air valve closed = 180 steps

; Called:
; 1) From end of main loop (if iacMotorStepCount is non-zero)
; 2) From Inertia Switch routine
; 3) From Coolant Temp routine (loops until iacMotorStepCount is zero)

; Note that 16-bit value 'stepperMotorTimer' is only used here
; ------------------------------------------------------------------------------
driveIacMotor       tpa                           ; xfer CCR to A
                    psha                          ; and push to stack
                    lda       iacMotorStepCount
                    beq       .LDA1D              ; if zero, branch to jmp to pop CCR and rtn
                    lda       bits_2047
                    bita      #$80                ; test bits_2047.7 (normally zero)
                    beq       .LD9FC              ; branch if bit is low
                    ldd       counterHigh         ; load counter value into A-B
                    bra       .LD9FF

.LD9FC              jsr       LF0D5               ; update timers (returns 16-bit counter value in A-B)

.LD9FF              std       $00C8               ; store counter in 00C8/C9
                    lda       $0085
                    bita      #$04                ; test 0085.2 (indicates extra eng load??, No, IS run-0nce bit)
                    beq       .LDA12              ; branch ahead if zero
                    ldd       $00C8
                    subd      stepperMotorTimer   ; counter subtract value
                    subd      #$0C35              ; subtract 3125 dec
                    bcs       .LDA2D              ; if carry set, branch to jump to pop CCR and rtn
                    bra       .LDA3D              ; carry clr, branch ahead

.LDA12              ldd       ignPeriod
                    subd      $C253               ; for 3360 code, value is $118B (1670 RPM)
                    bcs       .LDA1F              ; branch ahead if PW is LT $118B (RPM > 1670)
                    lda       $008B               ; RPM LT 1670
                    bita      #$40                ; test 008B.6 (1 = main voltage OK)

; code branches here if step count is zero
.LDA1D              beq       .LDA31              ; branch to jmp to pop CCR and rtn

.LDA1F              lda       bits_2038
                    bita      #$40                ; test bits_2038.6
                    bne       .LDA34
                    ldd       $00C8
                    subd      stepperMotorTimer   ; counter subtract value
                    subd      #$186A              ; subtract 6250 dec

.LDA2D              bcs       .LDA31              ; branch to jmp to pop CCR and rtn
                    bra       .LDA3D

.LDA31              jmp       .LDAD0              ; pop CCR and return

.LDA34              ldd       $00C8
                    subd      stepperMotorTimer   ; counter subtract value
                    subd      #$0C35              ; subtract 3125 dec
                    bcs       .LDA31

.LDA3D              lda       $008A               ; code gets here from 2 places if carry clr
                    eora      bits_2038           ; exclusive or the A reg with bits_2038
                    bita      #$01                ; test eor of 008A.0 and bits_2038.0 (stppr mtr direction)
                    bne       .LDAAF              ; branch ahead if only 1 of the 2 bits was set
                    dec       iacMotorStepCount
                    ldb       iacvDriveValue      ; load SM drive value into B
                    jsr       LDAD3               ; stepper motor sub-routine (below)
                    lda       $008A
                    bita      #$01                ; test 008A.0 (stepper mtr direction bit, 0 = open, 1 = close)
                    beq       .LDA5F
; close
                    tba                           ; xfer drive value from B into A
                    asld                          ; shift left twice to create next drive value in A
                    asld
                    clr       $00CE               ; set X00CE to zero
                    ldb       iacPosition
                    incb                          ; increment stepper mtr position
                    bra       .LDA6C

; open
.LDA5F              tba                           ; xfer drive value from B into A
                    lsrd                          ; shift right twice to create next drive value in B
                    lsrd
                    tba                           ; xfer drive value to A
                    ldb       #$FF
                    stb       $00CE               ; set X00CE to $FF
                    ldb       iacPosition
                    beq       .LDA6C              ; skip decrement if zero
                    decb                          ; decrement stepper mtr position

.LDA6C              sta       iacvDriveValue      ; SM drive value
                    anda      #$30                ; bits 5:4 are SM drive bits
                    sta       $00CA               ; store at 00CA
                    lda       port1data           ; P1.5 and P1.4 are SM drive signals
                    anda      #$CF                ; mask 5:4 to zero
                    ora       $00CA               ; OR in new drive bits
                    sta       port1data           ; <-- drive stepper mtr
                    cmpb      #$B4                ; compare IAC position with limit of 180 dec
                    bcs       .LDA80
                    ldb       #$B4                ; if over, clip value to 180

.LDA80              cmpb      #$00                ; compare IAC position with zero
                    bne       .LDA86
                    ldb       #$01                ; if zero, limit it to 1

.LDA86              stb       iacPosition
                    lda       iacvWorkingValue    ; (4 of 5)
                    beq       .LDA93
                    bmi       .LDA90
; ------------------------------------------------------------------------------
; Note:   This area presented a problem during original disassembly and the
; code can only be recreated by defining bytes.
; ------------------------------------------------------------------------------

; -------------------------------------
; When 'iacvWorkingValue' is Positive
; -------------------------------------
; deca                ; decrement A
; cmpa    #$4C        ; 4C op code is inca (cmpa result not used)
; -------------------------------------
; When 'iacvWorkingValue' is Negative
; -------------------------------------
; deca                ; need byte for alignment
; FCB    $81          ; ditto
; .LDA90:                     ; value $81 is not used
; inca                ; increment A
; -------------------------------------

                    db        $4A,$81

.LDA90              db        $4C

                    sta       iacvWorkingValue    ; (5 of 5)

.LDA93              clr       stepperMotorReSync  ; counter for direction change
                    lda       $00CE
                    beq       .LDAA4
                    ldd       stepperMtrCounter
                    subd      #$0001              ; decrement stepperMtrCounter
                    bcc       .LDAAC
                    bra       .LDAAF

.LDAA4              ldd       stepperMtrCounter
                    addd      #$0001              ; increment stepperMtrCounter
                    bcs       .LDAAF

.LDAAC              std       stepperMtrCounter

.LDAAF              ldd       $00C8
                    std       stepperMotorTimer   ; counter subtract value
                    ldb       stepperMotorReSync
                    incb                          ; increment re-sync counter
                    stb       stepperMotorReSync
                    cmpb      #$04
                    bne       .LDAD0              ; pop CCR and return
                    ldb       bits_2038
                    lda       $008A
                    bita      #$01                ; test 008A.0 (stepper mtr direction bit, 0 = open, 1 = close)
                    bne       .LDACB
                    andb      #$FE                ; clear bits_2038.0
                    bra       .LDACD

.LDACB              orb       #$01                ; set bits_2038.0

.LDACD              stb       bits_2038

.LDAD0              pula                          ; pop the CCR
                    tap                           ; and restore it
                    rts

; ------------------------------------------------------------------------------
; Branches here conditionally from DA4B only. B is loaded from 'iacvDriveValue'
; (the stepper motor drive value). If B is one of the following 4 values, the
; routine just returns, otherwise, the stepper motor bits are examined and one
; of the 4 values is returned accordingly.
; 1E -> 1E (00011110)
; 78 -> 78 (01111000)
; E1 -> E1 (11100001)
; 87 -> 87 (10000111)
; Stepper Motor 00 -> 87
; Stepper Motor 10 -> 1E
; Stepper Motor 20 -> E1
; Stepper Motor 30 -> 78
; ------------------------------------------------------------------------------

LDAD3               cmpb      #$1E
                    beq       .LDAF3
                    cmpb      #$78
                    beq       .LDAF3
                    cmpb      #$E1
                    beq       .LDAF3
                    cmpb      #$87
                    beq       .LDAF3
                    ldb       port1data           ; bits 5:4 are stepper motor state
                    andb      #$30
                    beq       .LDAF4
                    cmpb      #$10
                    beq       .LDAF7
                    cmpb      #$20
                    beq       .LDAFA
                    ldb       #$78

.LDAF3              rts

.LDAF4              ldb       #$87
                    rts

.LDAF7              ldb       #$1E
                    rts

.LDAFA              ldb       #$E1
                    rts

; ------------------------------------------------------------------------------
