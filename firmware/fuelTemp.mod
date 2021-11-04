;*******************************************************************************
; 14CUX Firmware Rebuild Project
;
; File Date: 14-Nov-2013
;
; Description:
; ADC Routine - Fuel Temp Thermistor - Channel 11 (8-bit conversion)
;
; ADC service routines are entered with the newly measured ADC value in
; X00C8/C9 (only X00C9 for 8-bit readings). The A accumulator also contains
; the 8-bit reading.
;
; Note that for both HO2 sensors the ADC service routine table points to
; the 'rts' (return from subroutine) at the end of this routine.
;
; From Land Rover Docs:
;
; Engine Fuel Temperature Sensor (EFTS)
; The fuel temperature sensor, mounted on the fuel rail, operates in the
; same manner as the ECTS. When the ECM receives a high fuel temperature
; input, it increases injector pulse during hot restarts. When fuel is hot,
; vaporization occurs in the fuel rail and bubbles may be found in the
; injectors. This can lead to hard starting. Increasing injector pulse time
; flushes the bubbles away and cools the fuel rail with fresh fuel from the
; tank. Since 1989, the EFTS has also been used by ECM to trigger operation
; of the radiator fans when under-hood temperatures become extreme.
; As with the engine coolant temperature sensor, a diagnostic trouble code
; (15 [14CUX only]) is stored when the signal is out of range (0.08V to 4.9V)
; for longer than 160 milliseconds. No default value is provided by the ECM,
; however the MIL will illuminate.
;
; Note about sensor limits.
; When checking the range of the EFT counts, the addition of $04
; checks for exceeded limits at both ends of the sensor. For example,
; adding $04 and checking for a minimum of $08 checks for a low count
; minimum of $04 but it also checks for a high count maximum of $FC which
; is -4 in two's complement, since the value would wrap and look like a
; small positive number.
;*******************************************************************************

adcRoutine11        proc
                    sta       fuelTempCount       ;EFT sensor count
                    tab                           ;xfr it to B accum
                    addb      #$04                ;add 4 (see note about sensot limits above)
                    cmpb      #$08                ;compare it to 8
                    bhi       _1@@                ;branch if value is > 8 (EFT reading is OK)

                    lda       #$71                ;$71 is code for fuel temp sensor fault (also default val)
                    jsr       setTempTPFaults     ;<-- Set Fault Code 15 (Fuel Temp)

_1@@                ldb       $0085               ;X0085.4 is cleared after mux list finishes at least once)
                    bitb      #$10                ;test X0085.4
                    beq       _4@@                ;branch ahead if X0085.4 is clr
                    suba      hiFuelTemperature   ;this is the temp saved in battery backed memory
                    bcs       _6@@                ;branch ahead if fuel temp is < hiFuelTemperature
          ;-------------------------------------- ;fall through or branch up from 1 place below
_2@@                lda       $008A               ;gets here normally when saved hot EFT is zero
                    ora       #$02                ;set X008A.1 (this is the only place this bit is set)
                    sta       $008A               ;store it
_3@@                rts                           ;return
          ;-------------------------------------- ;branches here if X0085.4 is clr
_4@@                lda       $008A
                    bita      #$02                ;test X008A.1
                    bne       _3@@                ;return if bit is 1

                    bitb      #$20                ;test X0085.5
                    beq       _3@@                ;rtn if bit is zero

                    lda       fuelTempCounter     ;a local down-counter
                    beq       _5@@                ;branch ahead if down-counter is zero

                    dec       fuelTempCounter     ;else decrement it and return
                    rts
          ;--------------------------------------
_5@@                lda       $C0AE               ;for R3526, value is $02
                    sta       fuelTempCounter     ;store it
                    ldx       hotFuelAdjustment   ;only written in this routine
                    beq       _2@@                ;branch up if zero
                    dex                           ;decrement 'hotFuelAdjustment'
                    stx       hotFuelAdjustment   ;store it
                    rts                           ;and return
          ;--------------------------------------
          ; code gets here if fuel temp is hotter than saved hot fuel temp
          ;--------------------------------------
_6@@                nega                          ;convert negative temp delta to positive
                    ldb       $C0AF               ;for R3526, value is $32 (48 dec)
                    mul                           ;48 * temp_delta
                    std       hotFuelAdjustment   ;store the 16-bit result
                    subd      $C0B2               ;for R3526, value is $0780 (1920 dec)
                    bcs       _7@@                ;branch if calculated value < $0780

                    ldd       $C0B2               ;else store $0780 (this sets a limit)
                    std       hotFuelAdjustment 

_7@@                lda       $C0AE               ;for R3526, value is $02
                    sta       fuelTempCounter     ;store it
;                   rts

;*******************************************************************************
; ADC Routine - O2 Sensors - Channels 12 and 15
; The O2 sensors are tested in the main code loop

o2sense             rts
