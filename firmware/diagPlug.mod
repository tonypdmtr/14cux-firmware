;*******************************************************************************
; 14CUX Firmware Rebuild Project
;
; File Date: 14-Nov-2013
;
; Description:
; ADC Routine - Diagnostic plug - Channel 14 (8-bit conversion)
;
; ADC service routines are entered with the newly measured ADC value in
; X00C8/C9 (only X00C9 for 8-bit readings). The A accumulator also contains
; the 8-bit reading.
;
; This routine is used to clear the currently displayed fault to allow the
; next one to be shown. The fault code area is scanned during boot up and
; the code is sent to the display using two consecutive calls to a subroutine
; (each displays 1 digit on the 7-segment display).
;
; From L-R documentation:
;
; The following procedure displays the codes, and clears the fault memory:
; 1. Switch On ignition.
; 2. Disconnect serial link mating plug, wait 5 seconds, reconnect.
; 3. Switch OFF ignition, wait for main relay to drop out.
; 4. Switch ON ignition. The display should now reset. If no other faults
; exist, and the original fault has been rectified, the display will be
; blank.
; 5. If multiple faults exist repeat Steps 1 to 4. As each fault is cleared
; the code will change, until all faults are cleared. The display will
; now be blank.
;*******************************************************************************

adcRoutine14        proc
                    ldb       $0086
                    bitb      #$10                ;test X0086.4 (1 means diag display already updated)
                    bne       _1@@                ;return if high (already updated)

                    cmpa      #$80                ;cmpr ADC reading with $80
                    lda       $00DD               ;bits value (lda does not affect carry flag)
                    bcc       _2@@                ;branch ahead if reading GT $80 (meaning display present)

                    bita      #$01                ;test 00DD.0
                    bne       _5@@                ;if bit is set, branch to check for errors
                    clr       obddDelayCounter    ;clear up-counter (used for delay)

_1@@                rts                           ;code rtns from here if no display or display already updated
          ;-------------------------------------- ;branches here if display is present
_2@@                ldb       port1data
                    bitb      #$40                ;test P1.6 (fuel pump relay)
                    beq       _4@@                ;branch ahead if low (fuel pump ON)

                    ldb       obddDelayCounter
                    incb                          ;increment delay counter
                    beq       _3@@                ;branch ahead if counter wraps to zero

                    stb       obddDelayCounter
                    rts                           ;if here, delay is still active, so return
          ;-------------------------------------- ;branches here after delay (when counter wraps)
_3@@                ora       #$01
                    sta       $00DD               ;set X00DD.0
                    rts
          ;-------------------------------------- ;branch here when fuel pump is ON (or from below)
_4@@                ldb       $0086
                    orb       #$10                ;set X0086.4
                    stb       $0086
                    rts
          ;-------------------------------------- ;branches here if X00DD.0 is high
_5@@                clrb
                    ldx       #faultBits_49-1     ;this loop checks for fault bits
                                                  ;(scans the 6 fault bytes for non-zero values)
Loop@@              inx                           ;Start Loop *
                    lda       $00,x
                    bne       _6@@                ;branch ahead if fault found (non-zero)
                    incb
                    cmpb      #$06
                    bne       Loop@@              ;End Loop *
                    bra       _4@@                ;no faults found, branch up, set X0086.4 high and rtn
          ;-------------------------------------- ;Fault bit found!
_6@@                clrb                          ;B used as counter
          ;-------------------------------------- ;Start Loop* (right shift to get fault bit into carry)
_7@@                incb                          ;increment B
                    lsra                          ;shift LSB into carry (LSB is highest priority, code 29 is first)
                    bcc       _7@@                ;End Loop *

_8@@                asla                          ;Start Loop * Clear fault bit. (left shift loop to replace the 1 with a 0)
                    decb
                    bne       _8@@                ;End Loop *

                    sta       $00,x               ;store it back
                    bra       _4@@                ;branch to set X0086.4 and return
