## Load upper immediate

# lui

Description:
    rd = imm << 12

    lui rd, imm

```
------ imm --------------------- rd --- opcode
    00001010000010100101       00010    0110111
```

## Memory layout
```
    WA BA
    @00 0x00  00000000
    @01 0x04  0A0A5137   lui x2, 0x0a0a5
    @02 0x08  00100073   ebreak
    @03 0x0C  00000000
    @04 0x10  00000000
    @05 0x14  00000000
    @06 0x18  00000000  
    @07 0x1C  00000000  
    @08 0x20  00000000  
    @09 0x24  00000000  
    @0A 0x28  00000000
    @0B 0x2C  00000000
    @0C 0x30  00000000
    @0D 0x34  00000000
    @0E 0x38  00000000
    @0F 0x3C  00000000
    @10 0x40  00000004   Reset vector
    @11 0x44  00000000
```

## Auipc

RISC-V Instruction Formats slides.pdf - pg54 Corner case

# auipc

Description:
    rd = PC + (imm << 12)

    auipc x3, 0x0000DEAD

```
------ imm ----------------------    rd   --- opcode
    00001101111010101101           00011      0010111
Nibbles: 0000 1101 1110 1010 1101 0001 1001 0111
Machine Code:  0x0DEAD197

```

## Memory layout
```
    WA BA
    @00 0x00  00000000
    @01 0x04  0DEAD197   auipc x3, 0x0000DEAD
    @02 0x08  00100073   ebreak
    @03 0x0C  00000000
    @04 0x10  00000000
    @05 0x14  00000000
    @06 0x18  00000000  
    @07 0x1C  00000000  
    @08 0x20  00000000  
    @09 0x24  00000000  
    @0A 0x28  00000000
    @0B 0x2C  00000000
    @0C 0x30  00000000
    @0D 0x34  00000000
    @0E 0x38  00000000
    @0F 0x3C  00000000
    @10 0x40  00000004   Reset vector
    @11 0x44  00000000
```
