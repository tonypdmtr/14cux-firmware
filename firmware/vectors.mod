; ------------------------------------------------------------------------------
; 14CUX Firmware Rebuild Project

; File Date: 14-Nov-2013

; Description:    6803U4 Vectors and Other End-of-PROM Data

; This file contains the microprocessor's vector table, the tune number and
; the checksum fixer byte. In addition, some now unused values are stored
; here (CRC16 and TUNE_IDENT). The unused area between the end of active
; code and the beginning of this data is filled using the DS psuedo-op.

; ------------------------------------------------------------------------------

                    org       $FFE0               ; The positions of the data/vectors at the
; end of the ROM are fixed, so set the PC
; explicitly here.

                    dw        CRC16               ; unused, no need to update

                    dw        $FFFF,$FFFF,$FFFF

                    org       $FFE8               ; this location is important

                    db        $00                 ; unknown; usually $00
                    dw        TUNE_NUMBER
                    db        CHECKSUM_FIXER
                    dw        TUNE_IDENT
                    dw        reset               ; unused vector?

                    dw        purgeValveInt
                    dw        purgeValveInt
                    dw        purgeValveInt
                    dw        inputCapInt

                    dw        nmiInterrupt
                    dw        purgeValveInt
                    dw        nmiInterrupt
                    dw        reset
