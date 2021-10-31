; ------------------------------------------------------------------------------
; 14CUX Firmware Rebuild Project

; File Date: 07-Jan-2014

; Description: R3361 Data and build flags (94 RRC 4.2 NAS)

; This file includes the the 2K byte data section of the R3361 ROM which
; is from $0000 through $3FFF (mapped to $C000 through $C7FF in board). The
; file also contains build flags which control how the code is assembled and
; or modified.

; ------------------------------------------------------------------------------

; cpu 6803                ; tell assembler to output 6803 code
; output SCODE            ; output Motorola S code format (srec2bin will be used)

; ZERO                   ; used for convenient code deletion

; ----------------------------------------------------------
; These flags control how the code section is built
; This section should not be altered.
; ----------------------------------------------------------
; BUILD_R3365
; BUILD_R3383
; BUILD_R3652
BUILD_R3360_AND_LATER

; BUILD_TVR_CODE
NEW_STYLE_AC_CODE
NEW_STYLE_FAULT_SCAN

NEW_STYLE_FAULT_DELAY

NEW_STYLE_MIL_CODE

; ----------------------------------------------------------
; This section recreates the data at the end of the ROM
; (just before the vectors). The only thing here that
; affects the code is the checksum fixer.
; ----------------------------------------------------------
CRC16               =         $0ABE               ; addr FFE0/E1
TUNE_NUMBER         =         $3361               ; addr FFE9/EA
CHECKSUM_FIXER      =         $0D                 ; addr FFEB
TUNE_IDENT          =         $1A20               ; addr FFEC/ED

; ----------------------------------------------------------
; These two flags control the bytes at addresses C7C1 and
; C7C2 (near the end of this file). It appears that the
; original developers meant for these two bytes to be
; options, but this has not been fully tested.
; ----------------------------------------------------------
NAS_FUEL_MAP_5_LOCK =         1
MIL_DELAY           =         1

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
initialRpmLimit     =         $056C               ; used in reset.asm (5403 RPM)
initialRpmMargin    =         $1B                 ; used in reset.asm (LSB = 100 RPM)
ignPeriodEngStart   =         $3A                 ; used in several files (MSB = 505 RPM)
startupDelayCount   =         $04                 ; used in ignitionInt.asm (usually $04 but $02 for cold weather chip)
coldStartupFactor   =         $0A                 ; used in ignitionInt.asm (value is $12 for cold weather chip)
highRoadSpeed_ON    =         $C4                 ; 196 KPH (122 MPH)
highRoadSpeed_OFF   =         $FC                 ; minus 4 (196 - 4 = 192 KPH)
highSpeedIndByte    =         $AA                 ; the high road speed indicator byte (normally $AA)

dtc17_tpsMinimum    =         $0008               ; used in throttlePot.asm (78mV, this is 39mV for R3526 and R3652)
dtc18_tpsMaximum    =         $0332               ; used in ignitionInt.asm (4 Volts, was 1.5 V in earlier code)
dtc68_minimumRPM    =         $0D                 ; used in roadSpeed.asm (MSB = 2250 RPM)
dtc69_rpmMinimum    =         $10                 ; used in ignitionInt.asm (MSB = 1831 RPM)

; ----------------------------------------------------------
; Constant values used inline (i.e. not from the data section)
; ----------------------------------------------------------
ignPeriodHiSpeed    =         $07                 ; 4185 RPM (to switch in hi-speed ADC mux table)
pwRpmComputeLimit   =         $0E                 ; 2092 RPM (beyond this, the actual RPM is not computed because it's math intensive)
compRpmMaxConst     =         $079E               ; 1950 RPM (used when the engine speed exceeds pwRpmComputeLimit)
throttlePotDefault  =         $0076               ; 576mV
mapMultiplierOffset =         $80
mapRpmLimitOffset   =         $8C
mapAdcMuxTableOffset =         $7A

; ----------------------------------------------------------
; Start of Data
; ----------------------------------------------------------
                    org       $C000
romStart            =         *
limpHomeMap         db        $15,$19,$19,$19,$19,$19,$19,$18,$17,$15,$15,$15,$14,$14,$11,$11
                    db        $2D,$31,$31,$31,$2F,$2E,$2D,$2E,$2E,$30,$2F,$2E,$2F,$2B,$2B,$2B
                    db        $48,$4D,$4D,$4C,$4D,$4D,$4D,$4B,$4A,$4A,$4A,$4A,$4A,$46,$46,$46
                    db        $6C,$6A,$6A,$69,$6A,$6A,$6A,$68,$65,$65,$65,$66,$63,$61,$61,$61
                    db        $91,$91,$8C,$8C,$8A,$88,$85,$85,$85,$83,$84,$85,$87,$8D,$8D,$90
                    db        $DC,$DC,$D7,$D7,$C1,$C1,$AD,$A5,$A3,$A1,$A1,$A5,$A5,$A5,$A2,$A2
                    db        $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$EB,$D2,$D2,$D7,$EB,$F0,$EB,$E1
                    db        $FF,$FF,$FF,$FF,$FF,$FF,$FF,$F7,$FA,$EE,$EB,$EB,$F0,$F5,$E6,$DC

                    dw        $6590               ; fuel map multiplier

                    db        $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$8E,$FA,$FA  ; ADC mux table

                    dw        $1F40               ; Used for cond B in ICI (8000 dec)
                    dw        $1F40               ; Used for cond A in ICI (8000 dec)
                    db        $44                 ; Used for cond A in ICI
                    db        $04                 ; Used in cond A and B in ICI
                    db        $00                 ; Used in ICI
                    db        $00                 ; Used in ICI
                    dw        $F830               ; Used in ICI (-2000d)
                    dw        $07D0               ; Used in ICI (+2000d)
                    dw        $0002               ; Location X0094 is set to this value
                    db        $80                 ; Used in ICI and other places
                    db        $01,$08,$FC,$80     ; (unused?)
                    db        $23                 ; Used to init location X2010
                    db        $EA                 ; Used for comparison with throttle pot value
                    db        $08,$9D             ; Used for comparison with engine ignition period (3400 RPM)
                    db        $01                 ; Used as a multiplication factor
                    db        $1B,$58             ; (possibly unused values)
tpFastOpenThreshold db        $00,$18
                    db        $02                 ; Used in fuel temp thermistor routine
                    db        $32                 ; Used in fuel temp thermistor routine
                    db        $00,$02             ; Used in main loop
                    db        $07,$80             ; Used in fuel temp thermistor routine
hiFuelTempThreshold db        $65

LC0B5               db        $00,$24,$38,$67,$AB,$C2,$D7,$EE  ; Data table used in coolant temp routine
                    db        $26,$26,$26,$2A,$2C,$31,$3A,$44
                    db        $00,$00,$05,$01,$0D,$1B,$1B,$12

                    db        $70                 ; Fault code & default coolant sensor value
rsFaultSlowdownThreshold
                    dw        $0800               ; Road Speed Sensor Fault registers after this many counts

; this table is different for the cold weather chip
                    db        $00,$12,$1B,$25,$47,$75,$94,$B0,$C8,$DA,$E4,$E8  ; Table referenced in coolant temp routine
                    db        $0B,$0A,$07,$0D,$1A,$2A,$3C,$46,$53,$55,$64,$6B  ; Offset = 12
                    db        $1C,$0D,$06,$0A,$16,$1E,$25,$2B,$31,$31,$39,$44  ; Offset = 24

                    db        $96                 ; used in 1 Hz coundown routines
                    db        $0C                 ; maybe unused
                    db        $19                 ; used in ICI (TP multiplier)
                    db        $0A                 ; used in ICI (TP compare value)

                    db        $18,$31,$5A,$73,$89,$99,$B3,$CC,$DD,$EA  ; Table used in ICI
                    db        $04,$06,$0A,$0E,$12,$1C,$23,$23,$2B,$2B
                    db        $06,$05,$06,$05,$05,$00,$00,$00,$00,$00
                    db        $2D,$32,$3C,$50,$64,$FF,$FF,$FF,$FF,$FF
                    db        $1C,$1E,$1E,$32,$28,$28,$1E,$1E,$1E,$1E
                    db        $2D,$22,$19,$19,$19,$1E,$1E,$1E,$1E,$1E

                    db        $64                 ; Used during initialization
                    db        $04,$00             ; Used in ICI
                    db        $10                 ; ICI, compared with upper byte of filtered ign. period
                    db        $14                 ; Used in ICI
                    db        $17                 ; Used in ICI
                    db        $25                 ; Used during initialization
                    db        $14                 ; Used in throttle pot and ICI
                    db        $7A                 ; -> X200E (default fuel map value)
                    db        $C8                 ; 200 dec, multiplier for purge valve timer
                    db        $64                 ; possibly unused
                    db        $3C                 ; 60 dec, multiplier for purge valve timer
                    db        $14,$82             ; Related to purge valve timer
                    db        $06,$B8             ; Used in main loop S/R (1720 RPM, used in purge valve routine)
                    db        $0A                 ; Used in ICI
                    db        $2E,$E0             ; Used in ICI and main loop S/R
                    db        $00,$52             ; Used in CT S/R
                    db        $00,$00             ; Used in ICI
                    db        $00,$64             ; Used in ICI
                    db        $00,$8C             ; Used in ICI
                    db        $05                 ; Used in main loop S/R
                    db        $2D                 ; Used in main loop S/R
                    db        $32,$00             ; Used in main loop S/R
                    db        $1C                 ; Used in main loop S/R
                    db        $28                 ; Used in Trottle Pot routine
                    db        $AF                 ; Used in main loop S/R
                    db        $28                 ; Used in main loop S/R
                    db        $1A                 ; Used in main loop S/R
                    db        $05                 ; Used by main loop S/R
idleAdjForNeutral   db        $00,$64             ; Value is 100 (idle setting increase when in neutral)
idleAdjForAC        db        $00,$32             ; Value is 50 (idle setting increase for A/C)
                    db        $28                 ; Used by main loop S/R
                    db        $0A                 ; Used in ICI
                    db        $A0,$00             ; Used in ICI
                    db        $0A                 ; Used in Throttle Pot and main loop S/R
                    db        $05,$DC             ; Used in Throttle Pot routine
                    db        $06                 ; Used by main loop S/R
                    db        $14                 ; Used by main loop S/R
                    db        $0C                 ; Used by main loop S/R
                    dw        $04B0               ; eng RPM reference (1200) used in TP routine
                    db        $14,$0E,$AD,$14,$18,$18  ; Used by main loop S/R
                    db        $53                 ; Used by main loop S/R (may be upper byte of rev limit, 53FF/4 = 5375 RPM)
                    db        $27                 ; Used in ICI
                    db        $00,$3C             ; Used in ICI (this limits the value in B5/B6 to 60 minus 1)
                    db        $00,$0E             ; Used by main loop S/R
                    db        $01                 ; Used by main loop S/R
baseIdleSetting     dw        $0258               ; Base idle setting (600 RPM)
                    db        $50,$00,$D1         ; Used in ICI

                    db        $00,$0B,$1C,$23,$48,$51,$88,$E4,$F2  ; Coolant temp table -- 9 values
                    db        $78,$78,$A0,$A0,$88,$85,$72,$48,$1E  ; Offset 9
                    db        $00,$97,$00,$2A,$15,$16,$1E,$C0,$00  ; Offset 18

LC196               db        $59,$5C,$5E,$60,$62,$65,$67,$69  ; (C196 is referenced in ICI)
                    db        $F4,$E3,$D2,$C1,$AF,$9E,$8E,$7B
                    db        $00,$00,$00,$00,$00,$00,$00,$00

                    db        $01                 ; Used in Input Capture Interrupt
                    dw        $043D               ; subtracted from sum of air flow values in ICI
                    db        $15                 ; compared with counter value in 0094 or 0095 in ICI
                    dw        $0100               ; subtracted from air flow sum in ICI

engDataA            dw        $0065               ; Values for X9x00 (Type 5) Use this for R3526
engDataB            dw        $005B
engDataC            dw        $005C

engInitDataA        db        $00                 ; Init value for X9000
engInitDataB        db        $00                 ; Init value for X9100
engInitDataC        db        $00                 ; Init value for X9200

                    dw        $000A               ; During init, added to stored TPmin after use
                    db        $00                 ; unused
                    db        $08                 ; used in TP (added to TPMin)
                    db        $00                 ; unused
                    db        $10                 ; used in TP (subtracted from TPMin)
                    dw        $225D               ; Used in ICI
                    dw        $09C0               ; Used in ICI
                    dw        $001E               ; Used in ICI
                    db        $B2                 ; Init value for X200A

; 3 x 8 table for air flow in ICI
                    db        $00,$60,$6C,$7C,$84,$8E,$9A,$A8  ; row 0 is compared & subtracted from air flow sum
                    db        $36,$36,$36,$36,$3C,$48,$63,$94  ; row 1 is added to final value
                    db        $00,$00,$00,$30,$4C,$90,$E0,$00  ; row 2 is multiplied by remainder

                    db        $FF
                    dw        $FFEC               ; This inits the value in idleControlValue to minus 20
                    db        $2C                 ; This inits the value in acDownCounter to 44 dec
                    db        $2C                 ; This inits the value in acDownCounter to 44 dec (alt. code path)
                    dw        $0200               ; value used in ICI only
idleAdjForHeatedScreen
                    dw        $0000               ; Value zero (idle setting adjustment for heated screen)
                    db        $08
                    db        $01                 ; Used in ICI
                    db        $02                 ; Used in ICI
                    db        $0C                 ; Misfire fault threshold?
hotCoolantThreshold db        $14                 ; If either the coolant or fuel temps exceeds their threshold, the
hotFuelThreshold    db        $34                 ; condenser fan timer will be set to run the fans at shutdown
                    db        $56                 ; Compared with left short term trim in ICI
                    db        $30                 ; Compared with left and right short term trim in ICI (fault code related?)
                    db        $E0                 ; Compared with left and right short term trim in ICI (fault code related?)
                    dw        $0023               ; Subtracted from throttle pot value in ICI
                    dw        $0000               ; Subtracted from throttle pot value in ICI
                    dw        $CED7               ; CE is compared with coolant temp in ICI (XC1F9 is unused)
                    dw        $0202               ; C1FA is used, C1FB is unused
                    dw        $00C8               ; Inits O2 sample counters?? value is 200 dec
                    db        $10                 ; O2 sensors are ignored for this many seconds after startup
                    db        $03                 ; startup timer value (conditionally loaded into 2020 and 2021)
                    dw        $0004               ; Related to purge valve timer??
                    dw        $0C00               ; Value is stored in X2024/25
wideThrottleThreshold
                    dw        $02CD

accelPumpTable      db        $00,$14,$28,$32,$3F,$52,$66,$7E,$8F,$AD,$C3,$D7  ; XC206: Used by TP routine (coolant temp, 12 values)
                    db        $0C,$0C,$0E,$12,$13,$19,$1C,$28,$28,$28,$19,$19  ; XC212: Offset of 12 from cooland temp table

                    db        $07,$25,$22

                    db        $47                 ; for fuel map 0, 4 and 5
                    db        $1E
                    dw        $1000
                    db        $24
                    dw        $0E00

                    db        $47                 ; for fuel map 1, 2 and 3
                    db        $1E
                    dw        $1000
                    db        $24
                    dw        $0E00

LC22F               db        $01
                    db        $02

hiRPMAdcMux         db        $87,$02,$87,$86,$87,$02,$87
                    db        $87,$87,$87,$87,$87,$87,$F7

; ------------------------------------------------------------------------------
; Note: Variables between here and fuel map 1 are not in R2419
; ------------------------------------------------------------------------------

                    db        $1E
                    dw        $0032
                    db        $6C                 ; Used to init 'stprMtrSavedValue'
                    db        $25
                    dw        $4720
                    db        $1C
                    db        $23
                    db        $23
                    dw        $0096
                    dw        $0096
                    db        $3A
                    db        $C6
                    dw        $3E80               ; used by ignition sense subroutine
                    db        $71                 ; used by ignition sense subroutine
                    db        $4E                 ; used by ignition sense subroutine
                    dw        $118B               ; ign pulse period (1670 RPM) used by stepper motor routine
                    dw        $01F9               ; used by ignition sense subroutine
                    db        $0F
                    db        $0A                 ; used by road speed routine
                    db        $50
                    db        $02                 ; used by CalcIacvVariable
                    db        $02                 ; used by CalcIacvVariable
                    db        $08
                    dw        $0258               ; used by input capture interrupt
                    dw        $03F6               ; used by input capture interrupt
                    db        $53
                    dw        $7FB9               ; used by CalcIacvVariable
                    dw        $80B4               ; used by CalcIacvVariable
                    db        $28                 ; used by ignition sense subroutine

; ------------------------------------------------------------------------------
fuelMap1            db        $23,$23,$23,$21,$1E,$1E,$1E,$1E,$1E,$1E,$1F,$1F,$1E,$1E,$1E,$1F
                    db        $3E,$3E,$3C,$3C,$3A,$38,$36,$36,$36,$36,$36,$37,$36,$36,$36,$36
                    db        $5C,$5B,$58,$57,$57,$55,$55,$54,$53,$52,$50,$4E,$4E,$4D,$4D,$4E
                    db        $84,$84,$82,$7D,$7A,$76,$76,$75,$6E,$6E,$6D,$6C,$6B,$69,$67,$6A
                    db        $A6,$A6,$A6,$A6,$A6,$A4,$9C,$9B,$9A,$8F,$8B,$87,$86,$84,$82,$84
                    db        $DD,$DD,$DD,$D2,$CD,$C8,$C8,$CD,$CD,$C1,$B4,$B2,$B0,$AF,$AD,$AF
                    db        $EC,$EC,$EC,$EC,$EC,$EF,$E8,$FC,$F5,$EE,$D3,$CD,$CD,$CB,$CB,$D0
                    db        $EC,$EC,$EC,$EC,$EC,$EF,$EC,$FC,$FF,$EE,$EC,$F0,$F0,$EE,$EE,$EE

                    dw        $5DBE               ; fuel map multiplier

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

                    db        $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$09,$8E,$FA  ; ADC mux table
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

                    dw        $5DBE               ; fuel map multiplier

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

LC473               db        $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$09,$8E,$FA  ; ADC mux table

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

                    dw        $5DBE               ; fuel map multiplier

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

LC585               db        $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$09,$8E,$FA  ; ADC mux table

LC595               db        $B2,$1B,$03,$6C,$24,$23,$68
LC59C               db        $3C

; ------------------------------------------------------------------------------
fuelMap4            db        $21,$21,$21,$22,$21,$20,$1F,$1F,$1E,$1E,$1D,$1C,$1A,$19,$19,$19
                    db        $41,$41,$40,$3F,$3E,$3E,$3D,$3C,$3B,$3C,$3E,$3F,$3C,$34,$34,$34
                    db        $60,$5E,$5D,$5D,$5B,$5A,$5A,$5D,$5D,$5E,$61,$62,$57,$4E,$4E,$4E
                    db        $84,$84,$82,$82,$83,$83,$80,$7C,$7D,$83,$84,$85,$78,$6C,$6C,$6C
                    db        $B4,$AF,$A5,$A5,$A0,$A0,$A0,$A0,$A1,$A3,$A6,$A7,$96,$8C,$8C,$8C
                    db        $FF,$FF,$D2,$D2,$D2,$CD,$CD,$CD,$CB,$CB,$CE,$CE,$B2,$B2,$B4,$C3
                    db        $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F5,$EF,$D6,$D7,$D7,$DE,$DE
                    db        $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA,$FA,$FF,$FF,$FD,$FD

LC61D               dw        $56CC               ; fuel map factor

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

LC697               db        $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$8E,$FA,$FA  ; ADC mux table
LC6A7               db        $B9,$1B,$05,$6C,$6E,$2C,$5C
LC6AE               db        $64

; ------------------------------------------------------------------------------
fuelMap5            db        $15,$19,$19,$19,$19,$19,$19,$18,$17,$15,$15,$15,$14,$14,$11,$11
                    db        $2D,$31,$31,$31,$2F,$2E,$2D,$2E,$2E,$30,$2F,$2E,$2F,$2B,$2B,$2B
                    db        $48,$4D,$4D,$4C,$4D,$4D,$4D,$4B,$4B,$4A,$4A,$4A,$4A,$46,$46,$46
                    db        $6C,$6A,$6A,$69,$6A,$6A,$6A,$68,$65,$65,$65,$66,$63,$61,$61,$61
                    db        $91,$91,$8C,$8C,$8A,$88,$85,$85,$85,$83,$84,$85,$87,$8D,$8D,$90
                    db        $DC,$DC,$D7,$D7,$C1,$C1,$AD,$A5,$A3,$A1,$A1,$A5,$A5,$A5,$A2,$A2
                    db        $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$EB,$D2,$D2,$D7,$EB,$F0,$EB,$E1
                    db        $FF,$FF,$FF,$FF,$FF,$FF,$FF,$F7,$FA,$EE,$EB,$EB,$F0,$F5,$E6,$DC

                    dw        $6590               ; fuel map multiplier

LC731               db        $18,$31,$5A,$73,$89,$99,$B3,$CC,$DD,$EA  ; (C731) used by Input Capture Interrupt (10 coolant temp values)
LC73B               db        $04,$06,$0A,$0E,$12,$1C,$23,$23,$2B,$2B  ; index offsets are 0A, 14, 1E and ($0A + $28)
LC745               db        $06,$05,$06,$05,$05,$00,$00,$00,$00,$00
LC74F               db        $2D,$32,$3C,$50,$64,$FF,$FF,$FF,$FF,$FF
LC759               db        $1C,$1E,$1E,$32,$28,$28,$1E,$1E,$1E,$1E
LC763               db        $2D,$22,$19,$19,$19,$1E,$1E,$1E,$1E,$1E

; this table is different for the cold weather chip
LC76D               db        $00,$12,$1B,$25,$47,$75,$94,$B0,$C8,$DA,$E4,$E8  ; (C76D) used by coolant temp routine
LC779               db        $0B,$0A,$07,$0D,$1A,$2A,$3C,$46,$53,$55,$64,$6B  ; in X009B (cranking fueling value above zero F)
LC785               db        $1C,$0D,$06,$0A,$16,$1E,$25,$2B,$31,$31,$39,$44  ; in X009C (time fueling component, 1 Hz countdown)

LC791               db        $00,$24,$38,$67,$AB,$C2,$D7,$EE  ; (C791) used by CT routine (8 values)
LC799               db        $26,$26,$26,$2A,$2C,$31,$3A,$44  ; offset = 8
LC7A1               db        $00,$00,$05,$01,$0D,$1B,$1B,$12  ; offset = 16

LC7A9               db        $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$8E,$FA,$FA  ; ADC mux values
; (see notes below)

LC7B9               db        $B2                 ; -> X200A (used in ICI to calc FM load value row index)
                    db        $1B                 ; RPM safety delta
                    dw        $056C               ; RPM limit
LC7BD               db        $7A                 ; -> X200E (fuel map value)
LC7BE               db        $2C                 ; -> X200F (a coolant temp threshold)
LC7BF               db        $23                 ; -> X2010 (todo)
LC7C0               db        $64                 ; -> X2011 (multiplied by abs of throttle delta)
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
LC7C8               dw        $EA60               ; TP: 'throttlePotCounter' (60000 init value used by TP routine)
LC7CA               dw        $10D6               ; TP: value subtracted in TP Routine
LC7CC               dw        $0001               ; TP: value subtracted in TP Routine
LC7CE               db        $0A                 ; TP: compare value in TP Routine
LC7CF               db        $01                 ; (unused?)
LC7D0               db        $0A                 ; $0A is compare value in Air Cond Load routine

LC7D1               dw        $0FA0               ; ICI: 4000 dec used for lean condition check (alt value to 8000 in C092) added to X008E
LC7D3               dw        $0FA0               ; ICI: 4000 dec used for rich condition check (alt value to 8000 in C094) added to X0090

LC7D5               db        $20                 ; ICI: used in rich condition code
LC7D6               db        $1B                 ; ICI: used in lean condition code
LC7D7               db        $00                 ; ICI: used for code control (zero vs non-zero)
LC7D8               dw        $0064               ; used as eng speed delta (100 RPM)
LC7DA               db        $18                 ; idle speed adjustment
LC7DB               dw        $05DC               ; (1500 dec) subtract from short term trim in s/r (bank related adjustment)

acCoolantTempThreshold
                    db        $0F
acCoolantTempDelta  db        $01
init1HzStartDownCount
                    db        $0C

LC7E0               db        $65                 ; ICI: Coolant Temperature threshold
LC7E1               dw        $00C8               ; SM fault test (200 dec)
LC7E3               db        $40                 ; SM fault test

LC7E4                                             ; DS $C800-*,$FF ; Fill with $FF until start of code (which normally begins with rpmTable)

; ------------------------------------------------------------------------------
; RPM Table
; This table sets up the RPM brackets for the fuel map. Ignition period is
; measured by the microprocessor and stored as a 16-bit number. The period
; is measured in 1 uSec increments but is divided by 2 and stored in 2 uSec
; units. The first two columns in the table are the 16-bit ignition period
; brackets and the right two columns tell the software how to interpolate
; the remainder.

; If editing this table, it's important to make sure that the interpolation
; values are correct for a smoothly changing curve.

; ------------------------------------------------------------------------------

                    org       $C800

rpmTable            db        $05,$53,$40,$00     ; 5502 RPM
                    db        $06,$2A,$00,$13     ; 4753 RPM
                    db        $07,$25,$00,$10     ; 4100 RPM
                    db        $07,$D0,$00,$18     ; 3750 RPM
                    db        $09,$73,$80,$9C     ; 3100 RPM
                    db        $0A,$D9,$80,$B7     ; 2700 RPM
                    db        $0E,$A6,$80,$43     ; 2000 RPM
                    db        $10,$BD,$80,$7A     ; 1750 RPM
                    db        $14,$ED,$80,$3D     ; 1400 RPM
                    db        $1A,$A2,$80,$2C     ; 1100 RPM
                    db        $20,$8D,$80,$2B     ; 900 RPM
                    db        $25,$8F,$80,$33     ; 780 RPM
                    db        $29,$DA,$80,$3B     ; 700 RPM
                    db        $2F,$40,$80,$2F     ; 620 RPM
                    db        $3D,$09,$80,$12     ; 480 RPM
                    db        $92,$7C,$40,$2F     ; 200 RPM
