;*******************************************************************************
; Subroutine called from end of ICI
;
; Called only at end of ICI (before partial reset)
; Alters values at 008E/8F, 0090/91

LF018               proc
                    sei
                    lda       bits_0089
                    anda      #$03                ;test bits_0089.1 and bits_0089.0
                    beq       Done@@              ;return if both bits are zero
                    ldx       $0094               ;X0094/95 looks like a small signed number
                    bmi       _1@@                ;(ldx affects negative flag, this is the only way to F026)

                    dex                           ;if it's not negative, decrement it, store it and rtn
                    bra       _4@@
                                                  ; if here, X0094.7 is set
_1@@                ldx       #$008E              ;X008E/8F is used for lean condition
                    ldd       ,x                  ;loads X008E/8F or X0094/95
                    bne       _2@@
                    lda       bits_0089
                    anda      #$FE                ;clr bits_0089.0
                    sta       bits_0089

_2@@                jsr       LEE29               ;adds (or subtracts) 1 to/from X008E/8F
                    ldx       #$0090              ;X0090/91 is used for rich condition
                    ldd       ,x                  ;load X0090/91
                    bne       _3@@
                    lda       bits_0089
                    anda      #$FD                ;clr bits_0089.1
                    sta       bits_0089

_3@@                jsr       LEE29               ;adds (or subtracts) 1 to/from X0090/91
                    ldx       $C09E               ;val is $0002 ($FF9E is in some builds by mistake)

_4@@                stx       $0094               ;decrements value or stores #$0002

Done@@              cli
                    rts
