@echo off
rem If you don't have a Borland compatible MAKE, use this build method
asm11 main -s+ -l+ -fq+ -dR2967_55 -br2967_55.s
asm11 main -s+ -l+ -fq+ -dR2967_5B -br2967_5b.s
asm11 main -s+ -l+ -fq+ -dR2967_9B -br2967_9b.s
asm11 main -s+ -l+ -fq+ -dR2967_E0 -br2967_e0.s
asm11 main -s+ -l+ -fq+ -dR3116 -br3116.s
asm11 main -s+ -l+ -fq+ -dR3360 -br3360.s
asm11 main -s+ -l+ -fq+ -dR3361 -br3361.s
asm11 main -s+ -l+ -fq+ -dR3365 -br3365.s
asm11 main -s+ -l+ -fq+ -dR3383 -br3383.s
asm11 main -s+ -l+ -fq+ -dR3526 -br3526.s
asm11 main -s+ -l+ -fq+ -dR3652 -br3652.s
..\utils\lua53 ../utils/exbin.lua *.s
