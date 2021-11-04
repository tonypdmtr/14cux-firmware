;*******************************************************************************
; 14CUX Firmware Rebuild Project
;
; File Date: 14-Nov-2013
;
; Description:
; ADC Routine - Air flow sensor - Channel 9 (10-bit conversion)
;
; ADC service routines are entered with the newly measured ADC value in
; X00C8/C9 (only X00C9 for 8-bit readings). The A accumulator also contains
; the 8-bit reading.
;
; This ADC routine is only called by open loop fuel maps (1, 2 and 3). It
; measures the MAF CO trim voltage and stores the ADC count in the memory
; locations normally used by the long-term Lambda trim. It appears that
; nothing more is done with the data than provide a means for reading the
; trim voltage through the serial port.
;*******************************************************************************

adcRoutine9         proc
                    ldd       $00C8               ;load 10-bit value from X00C8/C9
                    asld:7                        ;shift MSB into carry
                    bcc       Save@@              ;return if MSB was low (normal cond.)

                    ldd       #-1                 ;bad value, store $FFFF instead

Save@@              std       longLambdaTrimR
                    std       longLambdaTrimL
                    rts
