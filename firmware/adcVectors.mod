; ------------------------------------------------------------------------------
; 14CUX Firmware Rebuild Project

; File Date: 14-Nov-2013

; Description:
; This is a vector table consisting of 16 pointers to service routines.
; They are indexed by the channel number in the ADC control list. The O2
; sensors are not in the ADC control list (even for closed loop) because they
; are measured in the ICI. The "o2sense" vector in this list simply points
; to an RTS instruction.

; ------------------------------------------------------------------------------

adcVectors          dw        adcRoutine0         ; Inertia switch
                    dw        adcRoutine1         ; Heated screen sense
                    dw        adcRoutine2         ; Air flow sensor (main signal)
                    dw        adcRoutine3         ; Throttle pot
                    dw        adcRoutine4         ; Coolant temp thermistor
                    dw        adcRoutine5         ; Auto neutral switch
                    dw        adcRoutine6         ; Air cond load input
                    dw        adcRoutine7         ; Road speed transducer
                    dw        adcRoutine8         ; Main relay voltage
                    dw        adcRoutine9         ; Air flow sensor (trim setting)
                    dw        adcRoutine10        ; Tune resistor
                    dw        adcRoutine11        ; Fuel temp thermistor
                    dw        o2sense             ; Right O2 sensor
                    dw        adcRoutine13        ; O2 Reference Voltage
                    dw        adcRoutine14        ; Diagnostic plug
                    dw        o2sense             ; Left O2 sensor
