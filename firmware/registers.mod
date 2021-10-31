; ------------------------------------------------------------------------------
; 14CUX Firmware Rebuild Project

; File Date: 14-Nov-2013

; Description:
; Contains equates for hardware registers including MPU, ADC and PAL.

; ------------------------------------------------------------------------------

; 6803U4 registers are from $0000 through $001F

port1ddr            equ       $00
port2ddr            equ       $01
port1data           equ       $02
port2data           equ       $03
port3ddr            equ       $04
port4ddr            equ       $05
port3data           equ       $06
port4data           equ       $07

timerCSR            equ       $08
counterHigh         equ       $09
counterLow          equ       $0A
ocr1High            equ       $0B
ocr1Low             equ       $0C
icrHigh             equ       $0D
icrLow              equ       $0E
port3csr            equ       $0F

sciModeControl      equ       $10
sciTRCS             equ       $11
sciRxData           equ       $12
sciTxData           equ       $13
ramControl          equ       $14
altCounterHigh      equ       $15
altCounterLow       equ       $16
timerCntrlReg1      equ       $17

timerCntrlReg2      equ       $18
timerStsReg         equ       $19
ocr2high            equ       $1A
ocr2low             equ       $1B
ocr3high            equ       $1C
ocr3low             equ       $1D
icr2high            equ       $1E
icr2low             equ       $1F

; PAL register (2 of 4 discrete outputs are used for I2C)

i2cPort             equ       $4004

; Hitachi Analog-to-Digital Converter (HD46508)

AdcControlReg0      equ       $6000
AdcControlReg1      equ       $6001
AdcStsDataHigh      equ       $6002
AdcDataLow          equ       $6003
AdcPcDataReg        equ       $6004
