;*******************************************************************************
; 14CUX Firmware Rebuild Project
;
; File Date: 14-Nov-2013
;
; Description:
; The A/C service routine can jump to this code block which is in a
; different location, outside of the branch range. There is no apparent
; reason why it was separated.
;
; Value (either $00 or $FF) is passed in A accumulator.
; If A is $00, bits_008C.7 is cleared.
; If A is $FF, bits_008C.7 is set.
;*******************************************************************************

LD49E               proc
                    ldb       bits_008C
                    tsta                          ;test bit 7 (pos or neg)
                    bmi       Minus@@             ;branch if minus (bit is set)
                    andb      #$7F                ;clr bits_008C.7
                    bra       Save@@

Minus@@             orb       #$80                ;set bits_008C.7
Save@@              stb       bits_008C           ;store value
                    rts                           ;and return to main loop
