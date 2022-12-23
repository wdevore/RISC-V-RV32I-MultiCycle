Nihongo/Hardware/Risc-v/TopReference/risc-v-asm-manual.pdf

# PLLs
Folknology has an excellent page for describing how to use the <span style="color: blue;">*simple mode*</span> capability of the lattice iCE40 fpga: https://github.com/mystorm-org/BlackIce-II/wiki/PLLs

We need an ~18MHz clock because nextpnr has trouble routing anything faster. So we use *icepll* to generate our control parameters:

```icepll -i 25 - o 18```

This will generate:
```
F_PLLIN:    25.000 MHz (given)
F_PLLOUT:   18.000 MHz (requested)
F_PLLOUT:   17.969 MHz (achieved)

FEEDBACK: SIMPLE
F_PFD:   25.000 MHz
F_VCO:  575.000 MHz

DIVR:  0 (4'b0000)
DIVF: 22 (7'b0010110)
DIVQ:  5 (3'b101)

FILTER_RANGE: 2 (3'b010)
```

However, *icepll* can also generate example code too:

```icepll -i 25 -o 18 -m -f pll.v```
