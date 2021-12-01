;*******************************************************************************
; 14CUX Firmware Rebuild Project
;
; File Date: 14-Nov-2013
;
; Description:    16-Bit Multiply Routine
;
; The MPU has an 8-bit multiply instruction (mul) which multiplies the
; accumulators (A and B) into a 16-bit value (AB) but software often needs
; to multiply 16-bit numbers. This multiplies the 16-bits stored at AB with
; the 16-bits stored at general purpose memory locations X00CA/CB. Only the
; top 16-bits of the 32-bit result is returned in AB.
;
; In the standard code build, this routine is found immediatley after the
; RPM table and before the reset entry point.
;*******************************************************************************

mpy16               proc
                    ldx       #$00C8
                    std       ,x                  ;store double at X00C8/C9
                    ldb       3,x                 ;load 00CA into B
                    mul
                    std       4,x                 ;store double at X00CC/CD
                    ldd       1,x                 ;load double from 00C9/CA
                    mul
                    addb      5,x                 ;add value from 00CD
                    adca      #0
                    sta       5,x                 ;store at 00CD
                    lda       ,x                  ;load from 00C8
                    ldb       2,x                 ;load from 00CA
                    mul
                    addb      4,x                 ;add from 00CC
                    adca      #0
                    addb      5,x                 ;add from 00CD
                    adca      #0
                    rts
