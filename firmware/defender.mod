; ------------------------------------------------------------------------------
; 14CUX Firmware Rebuild Project

; File Date: 06-Jan-2014

; Description:
; This code is specific to R3365 (Defender). It is an abbreviated version
; of the comparator test. The triggering of the comparator measurement is
; done with in-line code. This saves 6 uSec by triggering the ADC before the
; "jump to subroutine" operation.

; ------------------------------------------------------------------------------

LFA46               lda       $008B               ; bits value
                    brn       LFA4A               ; branch never

LFA4A               ldb       AdcStsDataHigh
                    bitb      #$40                ; test ADC busy flag
                    bne       LFA4A               ; branch back if busy
                    bitb      #$20                ; test comparator flag
                    beq       LFA5B               ; 0 means Vin < Vp, 1 means Vin > Vp

                    ora       #$80
                    sta       $008B               ; set 008B.7
                    bra       LFA71

LFA5B               bita      #$80
                    beq       LFA71
                    anda      #$7F                ; clear 008B.7
                    sta       $008B
                    inc       vssStateCounter
                    ldd       faultCode26Counter  ; increm in RS comp s/r (ramp 0 to FFFF)
                    addd      #$0001
                    bcs       LFA71               ; ...but stop at $FFFF
                    std       faultCode26Counter
LFA71               rts
