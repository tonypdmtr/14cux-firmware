; ------------------------------------------------------------------------------
; 14CUX Firmware Rebuild Project

; File Date: 14-Nov-2013

; Description:
; This file contains miscellaneous routines.

; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; This sets fault bits in faultBits_4A or faultBits_4D according to the value
; in A accumulator.
; $76 = Fault Code 17 (TP sensor)
; $70 = Fault Code 14 (ECT sensor)
; $71 = Fault Code 15 (EFT sensor)
; $01 = Fault Code 18 (TP GT $0332 or 4.0 volts under certain conditions)
; ------------------------------------------------------------------------------

                    #ifdef    BUILD_R3360_AND_LATER
; ---------------------------------------------------------------------------------
setTempTPFaults     psha
                    ldd       faultSlowDownCount
                    beq       .okToSetFaults
                    addd      #$0001
                    std       faultSlowDownCount
                    pula
                    rts

.okToSetFaults      pula
                    cmpa      #$76
                    beq       .setTPFault17
                    cmpa      $C0CD               ; data value is $70
                    beq       .setCTFault14
                    cmpa      #$71
                    beq       .setFTFault15
                    cmpa      #$01
                    beq       .setTPFault18
                    rts

; ---------------------------------------------------------------------------------
                    #else                         ; Griffith
; ---------------------------------------------------------------------------------
setTempTPFaults     ldb       $00D1
                    beq       .okToSetFaults
                    incb
                    stb       $00D1
                    rts

.okToSetFaults      cmpa      #$76
                    beq       .setTPFault17
                    cmpa      $C0CD               ; data value is $70
                    beq       .setCTFault14
                    cmpa      #$FF
                    beq       .setMafFaultFF      ; MAF fault (replaced by DTC 12)
                    cmpa      #$71
                    beq       .setFTFault15
                    cmpa      #$01
                    beq       .setTPFault18
                    cmpa      #$02
                    beq       .setTPFault19       ; branch to TP Fault Code 19
                    rts

; ---------------------------------------------------------------------------------
                    #endif

.setTPFault17       ldb       faultBits_4A
                    orb       #$10                ; Set TP Sensor Fault Code 17
                    stb       faultBits_4A
                    rts

.setCTFault14       ldb       faultBits_4A
                    orb       #$08                ; Set ECT Sensor Fault Code 14
                    stb       faultBits_4A
                    rts

                    #ifdef    BUILD_R3360_AND_LATER
; nothing
                    #else

.setMafFaultFF      ldb       faultBits_49
                    orb       #$40                ; set MAF fault bit
                    stb       faultBits_49
                    ldb       $0087
                    orb       #$02                ; set MAF fault bit
                    stb       $0087
                    rts

                    #endif

.setFTFault15       ldb       faultBits_4D
                    orb       #$20                ; Set EFT Sensor Fault Code 15
                    stb       faultBits_4D
                    rts

.setTPFault18       ldb       faultBits_4A
                    orb       #$20                ; Set TP Sensor Fault Code 18
                    stb       faultBits_4A
                    rts

                    #ifdef    BUILD_R3360_AND_LATER
; nothing
                    #else

.setTPFault19       ldb       faultBits_4A        ; value 02 (fault code 19?)
                    orb       #$40                ; removed from R3526 code
                    stb       faultBits_4A
                    rts

                    #endif

; ---------------------------------------------------------------------------------
; Stepper Motor Subroutine

; This is called from both a main loop subroutine and the throttle pot routine.
; ---------------------------------------------------------------------------------

LEE12               ldb       iacMotorStepCount   ; absolute value of stepper mtr adjustment
                    bne       .LEE28              ; return if iacMotorStepCount is not zero

                    ldb       iacvValue2
                    beq       .LEE28              ; return if iacvValue2 is zero

                    stb       iacMotorStepCount   ; store iacvValue2 as iacMotorStepCount
                    ldb       $008A
                    orb       #$01                ; set X008A.0 (stepper mtr direction, 1 = close)
                    stb       $008A
                    clr       iacvValue2          ; and clr iacvValue2
                    inc       idleSpeedDelta      ; idle speed adjustment

.LEE28              rts

; ------------------------------------------------------------------------------
; This is called from two places in a subroutine One with X = X008E and the
; other with X = X0090.
; The routine adds or subtracts 0001 to/from X008E/8F or X0090/91

; ------------------------------------------------------------------------------
LEE29               ldd       $00,x
                    beq       .LEE39              ; return if indexed double value is zero
                    bmi       .LEE34
                    subd      #$0001              ; subtract 1 if value is positive
                    bra       .LEE37

.LEE34              addd      #$0001              ; add 1 if value is negative
.LEE37              std       $00,x
.LEE39              rts

; ------------------------------------------------------------------------------
