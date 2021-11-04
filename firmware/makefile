################################################################################
# Borland compatible makefile				     <tonyp@acm.org>
################################################################################

!ifdef TEST
ASM = @asm11 main -s- -l- -fq+
!else
ASM = @asm11 main -s+ -l+ -fq+
!endif

EXBIN = @../utils/lua53 ../utils/exbin.lua

################################################################################
# Implicit rules
################################################################################

.s.bin:
 $(EXBIN) $<

################################################################################

help:
  @echo +===========================================================+
  @echo | Possible targets and description (to be added):
  @echo +===========================================================+
  @echo | R2967_55  --
  @echo | R2967_5B  --
  @echo | R2967_9B  --
  @echo | R2967_E0  --
  @echo | R3116     --
  @echo | R3360     --
  @echo | R3361     --
  @echo | R3365     --
  @echo | R3383     --
  @echo | R3526     --
  @echo | R3652     --
  @echo +===========================================================+

################################################################################

all: r2967_55 \
     r2967_5b \
     r2967_9b \
     r2967_e0 \
     r3116 \
     r3360 \
     r3361 \
     r3365 \
     r3383 \
     r3526 \
     r3652

bin: r2967_55.bin \
     r2967_5b.bin \
     r2967_9b.bin \
     r2967_e0.bin \
     r3116.bin \
     r3360.bin \
     r3361.bin \
     r3365.bin \
     r3383.bin \
     r3526.bin \
     r3652.bin

################################################################################

r2967_55: r2967_55.s
r2967_5b: r2967_5b.s
r2967_9b: r2967_9b.s
r2967_e0: r2967_e0.s
r3116: r3116.s
r3360: r3360.s
r3361: r3361.s
r3365: r3365.s
r3383: r3383.s
r3526: r3526.s
r3652: r3652.s

################################################################################
# Dependencies
################################################################################

FL = main.asm \
     adcVectors.mod \
     airCond.mod \
     airCond2.mod \
     airMass.mod \
     coldStart.mod \
     coolant.mod \
     data.mod \
     data_R2967_55.mod \
     data_R2967_5B.mod \
     data_R2967_9B.mod \
     data_R2967_E0.mod \
     data_R3116.mod \
     data_R3360.mod \
     data_R3361.mod \
     data_R3365.mod \
     data_R3383.mod \
     data_R3526.mod \
     data_R3652.mod \
     defender.mod \
     diagPlug.mod \
     faults.mod \
     fuelTemp.mod \
     heatedScreen.mod \
     i2c.mod \
     idleControl.mod \
     ignitionInt.mod \
     mafTrim.mod \
     mainLoop.mod \
     mainRelay.mod \
     misc1.mod \
     misc2.mod \
     misc3.mod \
     miscRoutines.mod \
     mpy16.mod \
     neutralSwitch.mod \
     o2Ref.mod \
     purgeInt.mod \
     purgeValve.mod \
     purgeValve2.mod \
     ramLocations.mod \
     registers.mod \
     reset.mod \
     roadSpeed.mod \
     serialPort.mod \
     shutDown.mod \
     simulator.mod \
     stepperMtr2.mod \
     throttlePot.mod \
     tuneResistor.mod \
     vectors.mod

################################################################################

r2967_55.s: $(FL)
 $(ASM) -dR2967_55 -b$@

r2967_5b.s: $(FL)
 $(ASM) -dR2967_5B -b$@

r2967_9b.s: $(FL)
 $(ASM) -dR2967_9B -b$@

r2967_e0.s: $(FL)
 $(ASM) -dR2967_E0 -b$@

r3116.s: $(FL)
 $(ASM) -dR3116 -b$@

r3360.s: $(FL)
 $(ASM) -dR3360 -b$@

r3361.s: $(FL)
 $(ASM) -dR3361 -b$@

r3365.s: $(FL)
 $(ASM) -dR3365 -b$@

r3383.s: $(FL)
 $(ASM) -dR3383 -b$@

r3526.s: $(FL)
 $(ASM) -dR3526 -b$@

r3652.s: $(FL)
 $(ASM) -dR3652 -b$@

################################################################################
