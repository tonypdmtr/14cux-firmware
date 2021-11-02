;------------------------------------------------------------------------------
;   14CUX Firmware Rebuild Project
;
;   File Date: 03-Jan-2014
;
;   Description:
;       This is the file that is passed to ASM11 macro assembler.
;   The ordering of the files matches the original 14CUX code. This is to
;   enable a binary comparison with the original file in order to validate
;   our code rebuild.
;
;   29-Mar-2014     Relocated RPM table to end of data section file and
;                   deleted separate RPM table file.
;
;------------------------------------------------------------------------------
                    #CaseOn
                    #OptRelOff
codeErrorWord       equ       0                   ;never initialized and otherwise unused (to be deleted)
hiRpmAdcMux         equ       $C231               ; load address of special ADC table ($C231)
          ;--------------------------------------
?                   macro
          #ifb ~1~
                    mset      1,~text~
                    mset      #','
                    mdo
                    mswap     1,:mloop
            #ifdef ?
              #if :mloop = 1
                    #Hint     +--------------------------------------------
                    #Hint     | Available builds (for use with -D option)
                    #Hint     +--------------------------------------------
              #endif
                    #Hint     | ~1~
            #else ifdef ~1~
                    mexit
            #endif
                    mloop     :n
            #ifdef ?
                    #Hint     +--------------------------------------------
                    #Fatal    Run \@asm11 ~filename~ -dX\@ (where x is one of the above)
            #else
?
                    @@~0~
            #endif
          #endif
                    mset      #
          #if :index > 1
                    mset      0,~text~,
          #endif
                    mset      0,~text~~1~
                    endm

                    @?        R2967_55,R2967_5B,R2967_9B
                    @?        R2967_E0,R3116,R3360
                    @?        R3361,R3365,R3383
                    @?        R3526,R3652
                    @?                            ;check for any of the above
          ;--------------------------------------
                    #Uses     registers.mod
                    #Uses     data.mod            ; RPM table is now included in data section file
                    #Uses     ramLocations.mod
                    #Uses     mpy16.mod
                    #Uses     reset.mod
                    #Uses     mainLoop.mod
                    #Uses     throttlePot.mod
                    #Uses     shutDown.mod
                    #Uses     mainRelay.mod
                    #Uses     coolant.mod
                    #Uses     airMass.mod
                    #Uses     airCond.mod
                    #Uses     neutralSwitch.mod
                    #Uses     o2Ref.mod
                    #Uses     roadSpeed.mod
                    #Uses     fuelTemp.mod
                    #Uses     airCond2.mod
                    #Uses     diagPlug.mod
                    #Uses     heatedScreen.mod
                    #Uses     mafTrim.mod
                    #Uses     tuneResistor.mod
                    #Uses     adcVectors.mod
                    #Uses     idleControl.mod
                    #Uses     purgeInt.mod
                    #Uses     ignitionInt.mod
                    #Uses     miscRoutines.mod
                    #Uses     purgeValve.mod
                    #Uses     misc1.mod
                    #Uses     coldStart.mod
                    #Uses     misc2.mod
                    #Uses     i2c.mod
                    #Uses     faults.mod
                    #Uses     purgeValve2.mod
                    #Uses     misc3.mod
                    #Uses     stepperMtr2.mod
          #IFDEF BUILD_R3365
                    #Uses     defender.mod
          #ENDIF
                    #Uses     serialPort.mod
          #IFDEF SIMULATION_MODE
                    #Uses     simulator.mod
          #ENDIF
                    #Uses     vectors.mod
