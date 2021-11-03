; ------------------------------------------------------------------------------
; 14CUX Firmware Rebuild Project
;
; File Date: 07-Jan-2014
;
; Description: R2967_E0 Data and build flags (Chimaera 450)
;
; This file includes the the 2K byte data section of the R2967_E0 ROM
; which is from $0000 through $3FFF (mapped to $C000 through $C7FF in board).
; The file also contains build flags which control how the code is assembled
; or modified.
;
; Unfortunately, different versions of TVR code have the same R2967 tune
; number, which is why we add the checksum fixer byte to uniquely identify
; a TVR tune.
; ------------------------------------------------------------------------------

; ZERO                   ;used for convenient code deletion

; ----------------------------------------------------------
; These flags control how the code section is built
; This section should not be altered.
; ----------------------------------------------------------
; BUILD_R3365
; BUILD_R3383
; BUILD_R3652
; BUILD_R3360_AND_LATER
BUILD_TVR_CODE
; NEW_STYLE_AC_CODE
; NEW_STYLE_FAULT_SCAN
; NEW_STYLE_FAULT_DELAY
; NEW_STYLE_MIL_CODE

; ----------------------------------------------------------
; This section recreates the data at the end of the ROM
; (just before the vectors). The only thing here that
; affects the code is the checksum fixer.
; ----------------------------------------------------------
CRC16               =         $D2AA               ;addr FFE0/E1
TUNE_NUMBER         =         $2967               ;addr FFE9/EA
CHECKSUM_FIXER      =         $E0                 ;addr FFEB
TUNE_IDENT          =         $1A17               ;addr FFEC/ED

; ----------------------------------------------------------
; These two flags control the bytes at addresses C7C1 and
; C7C2 (near the end of this file). It appears that the
; original developers meant for these two bytes to be
; options, but this has not been fully tested.
; ----------------------------------------------------------
NAS_FUEL_MAP_5_LOCK =         0
MIL_DELAY           =         0

; ----------------------------------------------------------
; This section contains code development flags

; OBSOLETE_CODE
; This flag is used to include or exclude a number of code
; blocks that are obsolete or unneeded. Obsolete code should
; be included when attempting a byte for byte rebuild.

; USE_4004_BIT4_FOR_ICI
; This option toggles the signal from pin 34 on the Plessey
; MVA5033 (PAL) to allow time profiling of the spark interrupt.
; This pin is not otherwise used in the standard software.

; SIMULATION_MODE
; This is a bench test feature that requires a special
; hardware setup. This flag should normally be set to zero.

; ----------------------------------------------------------
OBSOLETE_CODE       =         1
USE_4004_BIT4_FOR_ICI =         0
; SIMULATION_MODE

SIM_CONTROL_BYTE    equ       $55

; ----------------------------------------------------------
; These values can differ from one tune version to the
; next, so they are defined here.
; ----------------------------------------------------------
initialRpmLimit     =         $0523               ;used in reset.asm (5703 RPM)
initialRpmMargin    =         $0F                 ;used in reset.asm
ignPeriodEngStart   =         $3A                 ;used in several files (MSB = 505 RPM)
startupDelayCount   =         $04                 ;used in ignitionInt.asm (usually $04 but $02 for cold weather chip)
coldStartupFactor   =         $0A                 ;used in ignitionInt.asm (value is $12 for cold weather chip)
highRoadSpeed_ON    =         $C4                 ;196 KPH (122 MPH)
highRoadSpeed_OFF   =         $FC                 ;minus 4 (196 - 4 = 192 KPH)
highSpeedIndByte    =         $AA                 ;the high road speed indicator byte (normally $AA)

dtc17_tpsMinimum    =         $0010               ;used in throttlePot.asm (78mV, this is 39mV for R3526 and R3652)
dtc18_tpsMaximum    =         $0133               ;used in ignitionInt.asm (1.5V, changed to 4V in later code)
dtc68_minimumRPM    =         $0E                 ;used in roadSpeed.asm (MSB = 2100 RPM)
dtc69_rpmMinimum    =         $0E                 ;used in ignitionInt.asm (MSB = 2100 RPM)

; ----------------------------------------------------------
; Constant values used inline (i.e. not from the data section)
; ----------------------------------------------------------
ignPeriodHiSpeed    =         $07                 ;4185 RPM (to switch in hi-speed ADC mux table)
pwRpmComputeLimit   =         $0E                 ;2092 RPM (beyond this, the actual RPM is not computed because it's math intensive)
compRpmMaxConst     =         $079E               ;1950 RPM (used when the engine speed exceeds pwRpmComputeLimit)
throttlePotDefault  =         $0076               ;576mV
mapMultiplierOffset =         $80
mapRpmLimitOffset   =         $8C
mapAdcMuxTableOffset =         $7A

; ----------------------------------------------------------
; Start of Data
; ----------------------------------------------------------
                    org       $C000
romStart            =         *
limpHomeMap         db        $21,$21,$21,$21,$1F,$1D,$1A,$19,$19,$19,$19,$19,$18,$14,$14,$14
                    db        $3F,$3E,$3D,$3B,$3A,$39,$39,$39,$3B,$3C,$3B,$39,$35,$30,$30,$30
                    db        $5D,$5C,$5B,$5C,$5D,$60,$5E,$5E,$5E,$5F,$5D,$5C,$53,$4A,$4A,$4A
                    db        $8E,$8E,$8C,$8C,$88,$8C,$8C,$84,$84,$80,$81,$81,$75,$69,$69,$69
                    db        $B2,$AF,$B0,$B0,$B1,$AC,$A6,$A6,$A6,$A6,$A4,$A3,$93,$8A,$8A,$8A
                    db        $FF,$FF,$D1,$D1,$D1,$D4,$D7,$D8,$E1,$D7,$D2,$D2,$CD,$CD,$B9,$C3
                    db        $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA,$DC,$E6,$E6,$E6,$E4,$F0
                    db        $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FB,$FA,$FA,$FA,$FD,$FD

                    dw        21725               ;fuel map multiplier

                    db        $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$8E,$FA,$FA  ;ADC mux table

                    dw        8000                ;Used for cond B in ICI
                    dw        8000                ;Used for cond A in ICI
                    db        $40                 ;Used for cond A in ICI
                    db        $04                 ;Used in cond A and B in ICI
                    db        $00                 ;Used in ICI
                    db        $00                 ;Used in ICI
                    dw        -2000               ;Used in ICI
                    dw        2000                ;Used in ICI
                    dw        $0002               ;Location X0094 is set to this value
                    db        $80                 ;Used in ICI and other places

                    db        $01,$08,$FC,$80     ;(unused?)
                    db        $51                 ;Used to init location X2010
                    db        $D7                 ;Used for comparison with throttle pot value
                    db        $08,$9D             ;Used for comparison with engine ignition period (3400 RPM)
                    db        $01                 ;Used as a multiplication factor
                    db        $1B,$58             ;(possibly unused values)
tpFastOpenThreshold db        $00,$18
                    db        $02                 ;Used in fuel temp thermistor routine
                    db        $32                 ;Used in fuel temp thermistor routine
                    db        $00,$02             ;Used in main loop
                    db        $07,$80             ;Used in fuel temp thermistor routine
hiFuelTempThreshold db        $65

LC0B5               db        $00,$24,$38,$91,$AB,$C2,$E0,$EE  ;Data table used in coolant temp routine
                    db        $26,$26,$29,$2C,$32,$38,$43,$4E
                    db        $00,$09,$02,$0E,$10,$17,$32,$14

                    db        $70                 ;Fault code & default coolant sensor value
rsFaultSlowdownThreshold
                    dw        $0800               ;Road Speed Sensor Fault registers after this many counts

                    db        $00,$12,$1B,$25,$47,$75,$99,$B0,$C8,$DA,$E4,$E8  ;Table referenced in coolant temp routine
                    db        $0B,$0A,$07,$0D,$1A,$1C,$31,$46,$4E,$59,$6D,$75  ;Offset = 12
                    db        $1C,$0D,$06,$0A,$10,$12,$1E,$26,$2C,$31,$39,$44  ;Offset = 24

                    db        $FF                 ;used in 1 Hz coundown routines
                    db        $0C                 ;maybe unused
                    db        $19                 ;used in ICI (TP multiplier)
                    db        $0A                 ;used in ICI (TP compare value)

                    db        $18,$31,$5A,$73,$89,$99,$B3,$CC,$DD,$EA  ;Table used in ICI
                    db        $05,$06,$08,$0A,$10,$1C,$23,$28,$30,$30
                    db        $04,$06,$07,$08,$08,$00,$00,$00,$00,$00
                    db        $2D,$32,$3C,$50,$64,$FF,$FF,$FF,$FF,$FF
                    db        $1C,$18,$10,$0C,$0B,$14,$14,$19,$19,$19
                    db        $24,$18,$10,$0C,$0B,$1E,$1E,$1E,$1E,$1E

                    db        $64                 ;Used during initialization
                    db        $04,$00             ;Used in ICI
                    db        $10                 ;ICI, compared with upper byte of filtered ign. period
                    db        $14                 ;Used in ICI
                    db        $17                 ;Used in ICI
                    db        $25                 ;Used during initialization
                    db        $14                 ;Used in throttle pot and ICI
                    db        $6E                 ;-> X200E (default fuel map value)
                    db        200                 ;multiplier for purge valve timer
                    db        $64                 ;possibly unused
                    db        60                  ;multiplier for purge valve timer
                    db        $14,$82             ;Related to purge valve timer
                    db        $06,$B8             ;Used in main loop S/R (1720 RPM, used in purge valve routine)
                    db        $0A                 ;Used in ICI
                    db        $2E,$E0             ;Used in ICI and main loop S/R
                    db        $00,$52             ;Used in CT S/R
                    db        $00,$00             ;Used in ICI
                    db        $00,$64             ;Used in ICI
                    db        $00,$8C             ;Used in ICI
                    db        $05                 ;Used in main loop S/R
                    db        $2D                 ;Used in main loop S/R
                    db        $16,$00             ;Used in main loop S/R
                    db        $1C                 ;Used in main loop S/R
                    db        $28                 ;Used in Trottle Pot routine
                    db        $32                 ;Used in main loop S/R
                    db        $28                 ;Used in main loop S/R
                    db        $1A                 ;Used in main loop S/R
                    db        $05                 ;Used by main loop S/R
idleAdjForNeutral   db        $00,$64             ;Value is 100 (idle setting increase when in neutral)
idleAdjForAC        db        $00,$32             ;Value is 50 (idle setting increase for A/C)
                    db        $1A                 ;Used by main loop S/R
                    db        $0A                 ;Used in ICI
                    db        $A0,$00             ;Used in ICI
                    db        $0A                 ;Used in Throttle Pot and main loop S/R
                    db        $05,$DC             ;Used in Throttle Pot routine
                    db        $06                 ;Used by main loop S/R
                    db        $14                 ;Used by main loop S/R
                    db        $0C                 ;Used by main loop S/R
                    dw        $04B0               ;eng RPM reference (1200) used in TP routine
                    db        $1E,$0E,$AD,$14,$18,$18  ;Used by main loop S/R
                    db        $53                 ;Used by main loop S/R (may be upper byte of rev limit, 53FF/4 = 5375 RPM)
                    db        $27                 ;Used in ICI
                    db        $00,$3C             ;Used in ICI (this limits the value in B5/B6 to 60 minus 1)
                    db        $00,$0E             ;Used by main loop S/R
                    db        $02                 ;Used by main loop S/R
baseIdleSetting     dw        $0302               ;Base idle setting (770 RPM)
                    db        $50,$00,$D1         ;Used in ICI

                    db        $00,$0B,$1C,$23,$48,$51,$88,$E4,$F2  ;Coolant temp table -- 9 values
                    db        $78,$78,$A0,$A0,$88,$85,$72,$50,$1E  ;Offset 9
                    db        $00,$97,$00,$2A,$15,$16,$18,$E5,$08  ;Offset 18

LC196               db        $59,$5C,$5E,$60,$62,$65,$67,$69  ;(C196 is referenced in ICI)
                    db        $F4,$E3,$D2,$C1,$AF,$9E,$8E,$7B
                    db        $00,$00,$00,$00,$00,$00,$00,$00

                    db        $01                 ;Used in Input Capture Interrupt
                    dw        $043D               ;subtracted from sum of air flow values in ICI
                    db        $15                 ;compared with counter value in 0094 or 0095 in ICI
                    dw        $0100               ;subtracted from air flow sum in ICI

engDataA            dw        $0065               ;Values for X9x00 (Type 5) Use this for R3526
engDataB            dw        $0067
engDataC            dw        $005d

engInitDataA        db        $00                 ;Init value for X9000
engInitDataB        db        $00                 ;Init value for X9100
engInitDataC        db        $04                 ;Init value for X9200

                    dw        $000A               ;During init, added to stored TPmin after use
                    db        $00                 ;unused
                    db        $08                 ;used in TP (added to TPMin)
                    db        $00                 ;unused
                    db        $10                 ;used in TP (subtracted from TPMin)
                    dw        $225D               ;Used in ICI
                    dw        $09C0               ;Used in ICI
                    dw        $001E               ;Used in ICI
                    db        $B2                 ;Init value for X200A

; 3 x 8 table for air flow in ICI
                    db        $00,$60,$6C,$7C,$84,$8E,$9A,$A8  ;row 0 is compared & subtracted from air flow sum
                    db        $36,$36,$36,$36,$3C,$48,$63,$94  ;row 1 is added to final value
                    db        $00,$00,$00,$30,$4C,$90,$E0,$00  ;row 2 is multiplied by remainder

                    db        $FF
                    dw        $FFEC               ;This inits the value in idleControlValue to minus 20
                    db        44                  ;This inits the value in acDownCounter
                    db        44                  ;This inits the value in acDownCounter (alt. code path)
                    dw        $0200               ;value used in ICI only
idleAdjForHeatedScreen
                    dw        $0000               ;Value zero (idle setting adjustment for heated screen)
                    db        $08
                    db        $02                 ;Used in ICI
                    db        $04                 ;Used in ICI
                    db        $0C                 ;Misfire fault threshold?
hotCoolantThreshold db        $14                 ;If either the coolant or fuel temps exceeds their threshold, the
hotFuelThreshold    db        $34                 ;condenser fan timer will be set to run the fans at shutdown
                    db        $56                 ;Compared with left short term trim in ICI
                    db        $30                 ;Compared with left and right short term trim in ICI (fault code related?)
                    db        $E0                 ;Compared with left and right short term trim in ICI (fault code related?)
                    dw        $0023               ;Subtracted from throttle pot value in ICI
                    dw        $0000               ;Subtracted from throttle pot value in ICI
                    db        $99                 ;compared with coolant temp in ICI
                    db        $C3,$02,02          ;C1F9 TO C1FB unused
                    dw        200                 ;Inits O2 sample counters??
                    db        $10                 ;O2 sensors are ignored for this many seconds after startup
                    db        $03                 ;startup timer value (conditionally loaded into 2020 and 2021)
                    dw        $0004               ;Related to purge valve timer??
                    dw        $0C00               ;Value is stored in X2024/25
wideThrottleThreshold
                    dw        $02CD

accelPumpTable      db        $00,$14,$28,$32,$3F,$52,$66,$7E,$AC,$AD,$C3,$D0  ;XC206: Used by TP routine (coolant temp, 12 values)
                    db        $0C,$0C,$0E,$12,$13,$14,$16,$18,$1E,$1E,$1E,$1E  ;XC212: Offset of 12 from cooland temp table

                    db        $07,$25,$22

                    db        $47                 ;for fuel map 0, 4 and 5
                    db        $1E
                    dw        $1000
                    db        $24
                    dw        $0E00

                    db        $47                 ;for fuel map 1, 2 and 3
                    db        $1E
                    dw        $1000
                    db        $24
                    dw        $0E00

LC22F               db        $03
                    db        $06

hiRPMAdcMux         db        $87,$02,$87,$86,$87,$02,$87
                    db        $87,$87,$87,$87,$87,$87,$F7

; ------------------------------------------------------------------------------
; Note: Variables between here and fuel map 1 are not in R2419
; ------------------------------------------------------------------------------

                    db        $1E
                    dw        $0032
                    db        $6C                 ;Used to init 'stprMtrSavedValue'
                    db        $25
                    dw        $4720
                    db        $1C
                    db        $23
                    db        $23
                    dw        $0096
                    dw        $0096
                    db        $3A
                    db        $C6
                    dw        $3E80               ;used by ignition sense subroutine
                    db        $71                 ;used by ignition sense subroutine
                    db        $4E                 ;used by ignition sense subroutine
                    dw        $113B               ;ign pulse period (1670 RPM) used by stepper motor routine
                    dw        $01F9               ;used by ignition sense subroutine
                    db        $0F
                    db        $0A                 ;used by road speed routine
                    db        $50
                    db        $02                 ;used by CalcIacvVariable
                    db        $02                 ;used by CalcIacvVariable
                    db        $06
                    dw        $0258               ;used by input capture interrupt
                    dw        $03E6               ;used by input capture interrupt
                    db        $53
                    dw        $7FB9               ;used by CalcIacvVariable
                    dw        $80B4               ;used by CalcIacvVariable
                    db        $28                 ;used by ignition sense subroutine

; ------------------------------------------------------------------------------
fuelMap1            db        $23,$23,$23,$21,$1E,$1E,$1E,$1E,$1E,$1E,$1F,$1F,$1E,$1E,$1E,$1F
                    db        $3E,$3E,$3C,$3C,$3A,$38,$36,$36,$36,$36,$36,$37,$36,$36,$36,$36
                    db        $5C,$5B,$58,$57,$57,$55,$55,$54,$53,$52,$50,$4E,$4E,$4D,$4D,$4E
                    db        $84,$84,$82,$7D,$7A,$76,$76,$75,$6E,$6E,$6D,$6C,$6B,$69,$67,$6A
                    db        $A6,$A6,$A6,$A6,$A6,$A4,$9C,$9B,$9A,$8F,$8B,$87,$86,$84,$82,$84
                    db        $DD,$DD,$DD,$D2,$CD,$C8,$C8,$CD,$CD,$C1,$B4,$B2,$B0,$AF,$AD,$AF
                    db        $EC,$EC,$EC,$EC,$EC,$EF,$E8,$FC,$F5,$EE,$D3,$CD,$CD,$CB,$CB,$D0
                    db        $EC,$EC,$EC,$EC,$EC,$EF,$EC,$FC,$FF,$EE,$EC,$F0,$F0,$EE,$EE,$EE

                    dw        $5DBE               ;fuel map multiplier

                    db        $18,$21,$31,$5A,$7C,$99,$B3,$CC,$DD,$EA
                    db        $04,$08,$0A,$0D,$12,$1C,$2B,$30,$33,$33
                    db        $04,$03,$04,$04,$04,$00,$00,$00,$00,$00
                    db        $28,$32,$3C,$64,$96,$FF,$FF,$FF,$FF,$FF
                    db        $14,$28,$28,$1E,$19,$1E,$1E,$1E,$19,$19
                    db        $0F,$14,$14,$14,$14,$1E,$1E,$1E,$1E,$1E

                    db        $00,$12,$1B,$25,$47,$75,$99,$B0,$C8,$DA,$E4,$E8
                    db        $0C,$0A,$08,$0D,$19,$2B,$3B,$46,$4E,$59,$69,$75
                    db        $1E,$10,$07,$0F,$13,$17,$1E,$26,$2C,$31,$39,$44

                    db        $00,$29,$50,$91,$AB,$C2,$E0,$EE
                    db        $26,$26,$2A,$2E,$34,$38,$43,$4E
                    db        $00,$06,$03,$0E,$0B,$17,$32,$14

                    db        $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$09,$8E,$FA  ;ADC mux table
                    db        $B2,$1B,$03,$6C,$24,$23,$68
                    db        $3C

; ------------------------------------------------------------------------------
fuelMap2            db        $23,$23,$23,$21,$1E,$1E,$1E,$1E,$1E,$1E,$1F,$1F,$1E,$1E,$1E,$1F
                    db        $3E,$3E,$3C,$3C,$3A,$38,$36,$36,$36,$36,$36,$37,$36,$36,$36,$36
                    db        $5C,$5B,$58,$57,$57,$55,$55,$54,$53,$52,$50,$4E,$4E,$4D,$4D,$4E
                    db        $84,$84,$82,$7D,$7A,$76,$76,$75,$6E,$6E,$6D,$6C,$6B,$69,$67,$6A
                    db        $A6,$A6,$A6,$A6,$A6,$A4,$9C,$9B,$9A,$8F,$8B,$87,$86,$84,$82,$84
                    db        $DD,$DD,$DD,$D2,$CD,$C8,$C8,$CD,$CD,$C1,$B4,$B2,$B0,$AF,$AD,$AF
                    db        $EC,$EC,$EC,$EC,$EC,$EF,$E8,$FC,$F5,$EE,$D3,$CD,$CD,$CB,$CB,$D0
                    db        $EC,$EC,$EC,$EC,$EC,$EF,$EC,$FC,$FF,$EE,$EC,$F0,$F0,$EE,$EE,$EE

                    dw        $5DBE               ;fuel map multiplier

LC3FB               db        $18,$21,$31,$5A,$7C,$99,$B3,$CC,$DD,$EA
                    db        $04,$08,$0A,$0D,$12,$1C,$2B,$30,$33,$33
LC40F               db        $04,$03,$04,$04,$04,$00,$00,$00,$00,$00
                    db        $28,$32,$3C,$64,$96,$FF,$FF,$FF,$FF,$FF
LC423               db        $14,$28,$28,$1E,$19,$1E,$1E,$1E,$19,$19
                    db        $0F,$14,$14,$14,$14,$1E,$1E,$1E,$1E,$1E

LC437               db        $00,$12,$1B,$25,$47,$75,$99,$B0,$C8,$DA,$E4,$E8
LC443               db        $0C,$0A,$08,$0D,$19,$2B,$3B,$46,$4E,$59,$69,$75
                    db        $1E,$10,$07,$0F,$13,$17,$1E,$26,$2C,$31,$39,$44

LC45B               db        $00,$29,$50,$91,$AB,$C2,$E0,$EE
LC463               db        $26,$26,$2A,$2E,$34,$38,$43,$4E
LC46B               db        $00,$06,$03,$0E,$0B,$17,$32,$14

LC473               db        $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$09,$8E,$FA  ;ADC mux table

LC483               db        $B2,$1B,$03,$6C,$24,$23,$68
LC48A               db        $3C

; ------------------------------------------------------------------------------
fuelMap3            db        $23,$23,$23,$21,$1E,$1E,$1E,$1E,$1E,$1E,$1F,$1F,$1E,$1E,$1E,$1F
                    db        $3E,$3E,$3C,$3C,$3A,$38,$36,$36,$36,$36,$36,$37,$36,$36,$36,$36
                    db        $5C,$5B,$58,$57,$57,$55,$55,$54,$53,$52,$50,$4E,$4E,$4D,$4D,$4E
                    db        $84,$84,$82,$7D,$7A,$76,$76,$75,$6E,$6E,$6D,$6C,$6B,$69,$67,$6A
                    db        $A6,$A6,$A6,$A6,$A6,$A4,$9C,$9B,$9A,$8F,$8B,$87,$86,$84,$82,$84
                    db        $DD,$DD,$DD,$D2,$CD,$C8,$C8,$CD,$CD,$C1,$B4,$B2,$B0,$AF,$AD,$AF
                    db        $EC,$EC,$EC,$EC,$EC,$EF,$E8,$FC,$F5,$EE,$D3,$CD,$CD,$CB,$CB,$D0
                    db        $EC,$EC,$EC,$EC,$EC,$EF,$EC,$FC,$FF,$EE,$EC,$F0,$F0,$EE,$EE,$EE

                    dw        $5DBE               ;fuel map multiplier

LC50D               db        $18,$21,$31,$5A,$7C,$99,$B3,$CC,$DD,$EA
                    db        $04,$08,$0A,$0D,$12,$1C,$2B,$30,$33,$33
                    db        $04,$03,$04,$04,$04,$00,$00,$00,$00,$00
LC52B               db        $28,$32,$3C,$64,$96,$FF,$FF,$FF,$FF,$FF
LC535               db        $14,$28,$28,$1E,$19,$1E,$1E,$1E,$19,$19
                    db        $0F,$14,$14,$14,$14,$1E,$1E,$1E,$1E,$1E

                    db        $00,$12,$1B,$25,$47,$75,$99,$B0,$C8,$DA,$E4,$E8
LC555               db        $0C,$0A,$08,$0D,$19,$2B,$3B,$46,$4E,$59,$69,$75
                    db        $1E,$10,$07,$0F,$13,$17,$1E,$26,$2C,$31,$39,$44

LC56C               db        $00,$29,$50,$91,$AB,$C2,$E0,$EE
LC575               db        $26,$26,$2A,$2E,$34,$38,$43,$4E
LC57D               db        $00,$06,$03,$0E,$0B,$17,$32,$14

LC585               db        $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$09,$8E,$FA  ;ADC mux table

LC595               db        $B2,$1B,$03,$6C,$24,$23,$68
LC59C               db        $3C

; ------------------------------------------------------------------------------
fuelMap4            db        $21,$21,$21,$22,$21,$20,$1D,$1C,$17,$17,$17,$17,$17,$17,$17,$17
                    db        $36,$36,$35,$35,$33,$30,$30,$32,$31,$31,$31,$31,$31,$31,$31,$31
                    db        $4D,$4D,$4B,$4B,$48,$4F,$4F,$4A,$4A,$46,$46,$50,$51,$51,$51,$51
                    db        $6D,$6D,$68,$68,$68,$68,$68,$68,$68,$63,$61,$61,$61,$61,$61,$61
                    db        $87,$87,$86,$86,$86,$84,$7D,$7D,$7D,$87,$84,$85,$87,$8D,$8D,$90
                    db        $A4,$A4,$A3,$A3,$A3,$A3,$A3,$A0,$A0,$A0,$A1,$A1,$A0,$A0,$A2,$A2
                    db        $B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$B9,$C4,$C4,$C2,$C5,$C5,$CC,$DC
                    db        $FF,$FF,$FF,$FF,$FF,$FF,$FF,$F7,$FA,$F1,$EB,$ED,$F4,$F7,$F1,$FD

LC61D               dw        $6590               ;fuel map factor

LC61F               db        $18,$21,$31,$5A,$7C,$99,$B3,$CC,$DD,$EA
                    db        $04,$08,$0A,$0C,$0E,$1C,$23,$28,$30,$30
                    db        $02,$04,$06,$08,$08,$00,$00,$00,$00,$00
                    db        $3C,$3C,$46,$50,$64,$FF,$FF,$FF,$FF,$FF
                    db        $50,$46,$32,$19,$0C,$14,$14,$19,$19,$19
                    db        $14,$14,$12,$12,$12,$1E,$1E,$1E,$1E,$1E

                    db        $00,$12,$1B,$25,$47,$75,$99,$B0,$C8,$DA,$E4,$E8
LC667               db        $0C,$0A,$07,$0D,$18,$27,$3B,$46,$4E,$59,$6D,$75
                    db        $1E,$0B,$04,$0F,$10,$11,$1E,$26,$2C,$31,$39,$44

                    db        $00,$29,$50,$91,$AB,$C2,$E0,$EE
LC687               db        $26,$26,$2A,$2C,$34,$38,$43,$4E
LC68F               db        $00,$06,$01,$13,$0B,$17,$32,$14

LC697               db        $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$8E,$FA,$FA  ;ADC mux table

                    db        $B9                 ;value stored in X200A, used to calc the fuel map load based row index
                    db        $0F                 ;value stored in X200B, RPM safety delta (7500000/(1315+15) = 5639 RPM)
                    dw        $0523               ;value stored in X200C/0D RPM safety limit (7500000/1315 = 5703 RPM)
                    db        $6E                 ;value stored in X200E (yet another fuel map value)
                    db        $2C                 ;value stored in X200F (a coolant temperature threshold)
                    db        $5C                 ;value stored in X2010 (todo)
                    db        $64                 ;value stored in X2011 (multiplied by abs of throttle delta)

; ------------------------------------------------------------------------------

; Fuel Map 5 for TVR Chimaera 500 (R2967_9B)

fuelMap5            db        $1C,$1C,$1C,$1B,$1B,$1B,$1B,$19,$19,$19,$18,$15,$14,$13,$13,$13
                    db        $36,$36,$36,$38,$39,$39,$39,$39,$38,$37,$36,$35,$34,$33,$33,$32
                    db        $54,$54,$54,$55,$55,$55,$55,$56,$56,$57,$57,$53,$50,$4F,$4F,$4F
                    db        $84,$84,$84,$77,$78,$7A,$7A,$7B,$7B,$7A,$7B,$7C,$7C,$7A,$78,$76
                    db        $9B,$96,$96,$96,$97,$96,$98,$9B,$9B,$9E,$9E,$9E,$9E,$9D,$9C,$9C
                    db        $D9,$D9,$D9,$D9,$D8,$D8,$D8,$D8,$D8,$D0,$D0,$CA,$CA,$CA,$CC,$CC
                    db        $EE,$E4,$E4,$DC,$DC,$FA,$FA,$FA,$F5,$F0,$EB,$EB,$ED,$EB,$E4,$E0
                    db        $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FF,$FF,$FF,$FF,$F5,$FD

                    dw        $6978               ;fuel map multiplier

; this 6 x 10 table is used to calc the throttle pot direction & rate (the 1st derivative)
; the resultant value is offset by adding 1024, stored at 0x005D/5E and ultimately used
; to dynamically adjust the fueling
; (added note: if CT count is $23 for example, the 2nd col would be used, not the 1st)

LC731               db        $18,$31,$5A,$73,$89,$99,$B3,$CC,$DD,$EA  ;<-- coolant temp sensor reading (low is hot, high is cold)
LC73B               db        $05,$06,$08,$0A,$10,$1C,$23,$28,$30,$30  ;<-- throttle opening (compare value or limit)
LC745               db        $04,$06,$07,$08,$08,$00,$00,$00,$00,$00  ;<-- throttle closing (compare value or limit)
LC74F               db        $2D,$32,$3C,$50,$64,$FF,$FF,$FF,$FF,$FF  ;<-- throttle opening (multiplier)
LC759               db        $1C,$18,$10,$0C,$0B,$14,$14,$19,$19,$19  ;<-- throttle opening (multiplier)
LC763               db        $24,$18,$10,$0C,$0B,$1E,$1E,$1E,$1E,$1E  ;<-- throttle closing (multiplier)

; this 3 x 12 table is used by the coolant temperature routine
LC76D               db        $00,$12,$1B,$25,$47,$75,$99,$B0,$C8,$DA,$E4,$E8  ;<-- coolant temp sensor reading (low is hot, high is cold)
LC779               db        $0B,$0A,$07,$0D,$1A,$1C,$31,$46,$4E,$59,$6D,$75  ;<-- cranking fueling value above zero deg F (stored in X009B)
LC785               db        $1C,$0D,$06,$0A,$10,$12,$1E,$26,$2C,$31,$39,$44  ;<-- time fueling component, 1 Hz countdown (stored in X009C)

; this 3 x 8 table calculates an adjustment factor based on engine temperature
LC791               db        $00,$24,$38,$91,$AB,$C2,$E0,$EE  ;(C791) used by CT routine (8 values)
LC799               db        $26,$26,$29,$2C,$32,$38,$43,$4E  ;offset = 8
LC7A1               db        $00,$09,$02,$0E,$10,$17,$32,$14  ;offset = 16

; this is the round robin ADC control list, F in upper nibble terminates list
LC7A9               db        $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$8E,$FA,$FA  ;ADC mux values

LC7B9               db        $91                 ;value stored in X200A, used to calc the fuel map load based row index
                    db        $0F                 ;value stored in X200B, RPM safety delta (7500000/(1212+15) = 6112 RPM)
                    dw        $04BC               ;value stored in X200C/0D RPM safety limit (7500000/1212 = 6188 RPM)
LC7BD               db        $6A                 ;value stored in X200E (yet another fuel map value)
LC7BE               db        $27                 ;value stored in X200F (a coolant temperature threshold)
LC7BF               db        $5A                 ;value stored in X2010 (todo)
LC7C0               db        $64                 ;value stored in X2011 (multiplied by abs of throttle delta)
; ------------------------------------------------------------------------------

; This byte must be $00 for the tune resistor fuel map selection to work.
; In NAS Land Rovers, it's set to $FF to lock the ECU into fuel map 5 only.
                    #ifdef    NAS_FUEL_MAP_5_LOCK
fuelMapLock         db        $FF
                    #else
fuelMapLock         db        $00
                    #endif

                    #ifdef    MIL_DELAY
                    db        $FF
                    #else
                    db        $00
                    #endif

voltageMultA        db        $64
voltageMultB        db        $BD
voltageOffset       dw        $6408

LC7C7               db        $27
LC7C8               dw        $EA60               ;stored in 'throttlePotCounter' (60000 init value used by TP routine)
LC7CA               dw        $10D6               ;value subtracted in TP Routine
LC7CC               dw        $0001               ;value subtracted in TP Routine
LC7CE               db        $0A                 ;comparison value in TP Routine
LC7CF               db        $01                 ;(unused?)
LC7D0               db        $0A                 ;comparison value in A/C service routine

LC7D1               dw        4000                ;ICI: used for lean condition check (alt value to 8000 in C092) added to X008E
LC7D3               dw        4000                ;ICI: used for rich condition check (alt value to 8000 in C094) added to X0090

LC7D5               db        $40                 ;ICI: used in rich condition code
LC7D6               db        $36                 ;ICI: used in lean condition code
LC7D7               db        $00                 ;ICI: used for code control (zero vs non-zero)
LC7D8               dw        $0064               ;used as eng speed delta (100 RPM)
LC7DA               db        $18                 ;idle speed adjustment
LC7DB               dw        1500                ;subtract from short term trim in s/r (bank related adjustment)

; ------------------------------------------------------------------------------
; Data ends here for Griff but there are 7 more bytes in later LR code.
; Also, LR code is padded to end of data section with value $FF while this
; code is padded with 5A, A5 and A7.
; ------------------------------------------------------------------------------

                    db        $5A                 ;$0F in R3526 (A/C servic routine)
                    db        $A5                 ;$01 in R3526 (A/C service routine)
                    db        $5A                 ;$0C in R3526 (A/C service routine, 1 Hz countdown)
                    db        $A5                 ;$65 in R3526 (coolant temp threshold in ICI)
                    dw        $5AA5               ;$00C8 in R3526 (idle spd value used in stepper mtr fault test))
                    db        $5A                 ;$40 in R3526 (used in stepper motor fault test)

                    db        $A5,$5A,$A5,$5A,$A5,$5A,$A5,$5A  ;unused (FF in NAS data)
                    db        $A5,$5A,$A5,$5A,$A5,$5A,$A5,$5A
                    db        $A5,$5A,$A5,$5A,$A5,$5A,$A5,$5A
                    db        $A7,$5A,$A7

                    db        $1A                 ;unknown

; ------------------------------------------------------------------------------
; RPM Table
; This table sets up the RPM brackets for the fuel map. Ignition period is
; measured by the microprocessor and stored as a 16-bit number. The period
; is measured in 1 uSec increments but is divided by 2 and stored in 2 uSec
; units. The first two columns in the table are the 16-bit ignition period
; brackets and the right two columns tell the software how to interpolate
; the remainder.
;
; If editing this table, it's important to make sure that the interpolation
; values are correct for a smoothly changing curve.
; ------------------------------------------------------------------------------

                    org       $C800

rpmTable            long      $05534000           ;5502 RPM
                    long      $062A0013           ;4753 RPM
                    long      $07250010           ;4100 RPM
                    long      $07D00018           ;3750 RPM
                    long      $0973809C           ;3100 RPM
                    long      $0AD980B7           ;2700 RPM
                    long      $0EA68043           ;2000 RPM
                    long      $10BD807A           ;1750 RPM
                    long      $14ED803D           ;1400 RPM
                    long      $1AA2802C           ;1100 RPM
                    long      $208D802B           ;900 RPM
                    long      $258F8033           ;780 RPM
                    long      $29DA803B           ;700 RPM
                    long      $2F40802F           ;620 RPM
                    long      $3D098012           ;480 RPM
                    long      $927C402F           ;200 RPM
