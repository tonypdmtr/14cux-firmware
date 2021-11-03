; ------------------------------------------------------------------------------
; 14CUX Firmware Rebuild Project

; File Date: 14-Nov-2013

; Description:
; The 14CUX ECU talks to the On-Board Diagnostic Display (OBDD) through
; a Philips Inter-Integrated Circuit protocol (usually called IIC or I2C and
; pronounced "eye-squared-see"). This is a very simple, synchronous serial
; protocol that can be implemented in software by toggling the lines going
; to to OBDD. This is often called a "bit bang" interface.

; The discrete lines that are used for this interface come through an output
; port at address X4004 in the PAL (MVA5033).

; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; I2C routine (below) branches here if fault code is zero
; ------------------------------------------------------------------------------
.faultCodeIs00      lda       #$FF
                    sta       $00CD
                    sta       $00CC               ;set data digits to $FFFF
                    lda       #$20
                    sta       tmpFaultCodeStorage  ;fault code - set X0067 to $20
                    jmp       .sendI2CStart

; ------------------------------------------------------------------------------
; I2C routine (below) branches here if fault code is $20
; ------------------------------------------------------------------------------
.faultCodeIs20      lda       #$00
                    sta       $00CD
                    sta       $00CC               ;set data digits to $0000
                    lda       tmpFaultCodeStorage
                    anda      #$DF
                    sta       tmpFaultCodeStorage  ;fault code - clr X0067.5
                    jmp       .sendI2CStart

; ------------------------------------------------------------------------------
; This routine is called twice (one for each digit) during startup.
; This is the I2C routine for the OBDD (7-segment display, part number SAA1064)
; The I2C port is at X4004.

; X00C8 - 00 (counter, not transmitted)

; These are transmitted (msb first):
; X00C9 - 70 (slave addr, lsb zero means wrt to slave)
; X00CA - 00 (instruction byte, start wrt at control reg)
; X00CB - 26 (control byte, 6 ma output, blank other digit)
; X00CC - 8-bit, 7-segment code for low  nibble of fault code
; X00CD - 8-bit, 7-segment code for high nibble of fault code

; 40-Pin          PLCC44
; ------------------------------------------
; 30 (pink)         11 (non-invert)   Clk
; 38 (brwn/pnk)     10 (invert)       Data

; TODO: PLC44 pin numbers may be incorrect!!

; ------------------------------------------------------------------------------

i2c                 sei                           ;set interrupt mask
                    ldd       #$0500              ;disables SCI xmt and rcv
                    std       sciModeControl
                    clr       $00C8               ;used as counter
                    lda       #$70                ;I2C slave address
                    sta       $00C9               ;#$70 = 1st byte to xmt (address)
                    clr       $00CA               ;#$00 = 2nd byte to xmt (instruction)
                    lda       #$26
                    sta       $00CB               ;#$26 = 3rd byte to xmt (control)
                    ldb       tmpFaultCodeStorage  ;load fault code
                    beq       .faultCodeIs00      ;branch up if zero
                    cmpb      #$20
                    beq       .faultCodeIs20      ;branch up if $20
                    andb      #$0F                ;isolate low nibble
                    ldx       #.displayCodes      ;Addr of 7-segment codes
                    abx
                    ldb       $00,x               ;get code from table
                    stb       $00CC               ;store code for low nibble
                    ldb       tmpFaultCodeStorage  ;load fault code again
                    lsrb
                    lsrb
                    lsrb
                    lsrb                          ;isolate high nibble
                    ldx       #.displayCodes
                    abx
                    ldb       $00,x
                    stb       $00CD               ;store code for high nibble
; ------------------------------------------------------------------------------
; send start condition (data goes low while clk is high)
; ------------------------------------------------------------------------------
.sendI2CStart       lda       i2cPort
                    ora       #$20                ;4004.5 high (data high to start)
                    anda      #$BF                ;4004.6 low (inverted clk high)
                    sta       i2cPort             ;wrt (data high, clk high)
                    nop
                    anda      #$DF                ;4004.5 low (data low for start cond.)
                    sta       i2cPort
; ------------------------------------------------------------------------------
; transmit loop
; ------------------------------------------------------------------------------
.i2cXmit            nop
                    lda       i2cPort
                    ora       #$40                ;4004.6 high (what is this??)
                    sta       i2cPort

                    lda       $00C8               ;load counter
                    inca                          ;increment counter
                    sta       $00C8               ;store counter

                    cmpa      #$09
                    beq       .i2cAckClk          ;clk ack after 1st byte
                    cmpa      #$11
                    beq       .i2cAckClk          ;clk ack after 2nd byte
                    cmpa      #$19
                    beq       .i2cAckClk          ;clk ack after 3rd byte
                    cmpa      #$21
                    beq       .i2cAckClk          ;clk ack after 5th byte
                    cmpa      #$29
                    beq       .sendI2CStop        ;leave loop
; ------------------------------------------------------------------------------
; ACK code returns here
; ------------------------------------------------------------------------------
.LF2C4              clc                           ;clr carry
                    rol       $00CD               ;rol involves the carry bit so this
                    rol       $00CC               ;is acting like a 40-bit rotation
                    rol       $00CB
                    rol       $00CA
                    rol       $00C9
                    bcs       .LF2E0              ;bit to xmt is in carry

                    lda       i2cPort             ;xmt a zero
                    anda      #$DF                ;4004.5 low
                    sta       i2cPort
                    bra       .LF2E8

.LF2E0              lda       i2cPort             ;xmt a one
                    ora       #$20                ;4004.5 high
                    sta       i2cPort

.LF2E8              nop
                    anda      #$BF
                    sta       i2cPort             ;4004.5 low, 4004.4 low
                    nop
                    bra       .i2cXmit

; ------------------------------------------------------------------------------
; send stop condition (data transitions high while clk is high)
; ------------------------------------------------------------------------------
.sendI2CStop        lda       i2cPort
                    ora       #$20                ;4004.5 high
                    nop
                    anda      #$BF                ;4004.6 low
                    sta       i2cPort
                    nop
                    ora       #$40                ;4004.6 high
                    sta       i2cPort
                    nop
                    anda      #$DF                ;4004.5 low
                    sta       i2cPort
                    nop
                    ora       #$40                ;4004.6 high
                    nop                           ;NOT WRITTEN!!
                    anda      #$BF                ;4004.6 low
                    sta       i2cPort
                    nop
                    ora       #$20                ;4004.5 high
                    sta       i2cPort
                    nop
                    rts

; ------------------------------------------------------------------------------
; ;I2C ack (clk the slave's active low ack, probably not read)
; ------------------------------------------------------------------------------
.i2cAckClk          lda       i2cPort
                    ora       #$20                ;4004.5 high (to release data bus)
                    nop
                    anda      #$BF                ;4004.6 low (inv clk high)
                    sta       i2cPort             ;wrt to port
                    nop
                    ora       #$40                ;4004.6 high (inv clk low)
                    sta       i2cPort             ;write to port
                    jmp       .LF2C4

; ------------------------------------------------------------------------------
; This data table consists of the codes to send to the OBDD to illuminate
; the 7-segment display. The table is 16 bytes long since it contains the
; codes for hexadecimal characters. The hex part is unused.
; ------------------------------------------------------------------------------

; 0  1  2  3  4  5  6  7  8  9                    <-- the digit to display
; FC 60 DA F2 66 B6 BE E0 FE E6 EE 3E 9C 7A 9E 8E  <-- corresponding 7-segment code

; ------------------------------------------------------------------------------
.displayCodes       db        $FC,$60,$DA,$F2
                    db        $66,$B6,$BE,$E0
                    db        $FE,$E6,$EE,$3E
                    db        $9C,$7A,$9E,$8E
