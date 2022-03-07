## Jump and Link instructions

# jal

Description:
    rd = PC+4; PC += imm

    jal rd, offset

x1 = 5

x2 = 5

produced    = 0000 0000 0000 0011 0100 = 0x00034

instruction = 0000 0011 0100 0000 0000

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
    rd  rs1 imm
lw  x5, x4, 0x10

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000010000   00100   010     00101    0000011

0000 0001 0000 0010 0010 0010 1000 0011 = 0x01022283
------------------------------------------------------------------

    rd  rs1 imm
lw  x5, x4, 0x0C

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000001100   00100   010     00101    0000011

0000 0000 1100 0010 0010 0010 1000 0011 = 0x00C22283
------------------------------------------------------------------

    rs1  imm
jal  x1, offset = 12 = C

  imm[20|10:1|11|19:12]   |  rd   | opcode
  00000011010000000000      00001   1101111

0000 0011 0100 0000 0000 0000 1110 1111 = 0x034000EF
```

## Memory layout
```
    WA BA
    @00 0x00  00A20113
    @01 0x04  00020083   lw  x1, x4, 0
    @02 0x08  034000EF   jal x1, jumpto
    @03 0x0C  00000000   nothing here because we aren't returning.
    @04 0x10  01022283   lw  x5, x4, 0x10   <-- failed to jump
    @05 0x14  00000099
    @06 0x18  00000000  
    @07 0x1C  00000000  
    @08 0x20  00000000  
    @09 0x24  00000000  
    @0A 0x28  00000000
    @0B 0x2C  00000000
    @0C 0x30  00000005
    @0D 0x34  00000A0A   data for x5   <-- jump taken
    @0E 0x38  00000B0B   data for x5   <-- jump not taken
jumpto:
    @0F 0x3C  00C22283   lw  x5, x4, 0x0C   <-- jump to
    @10 0x40  00000004   Reset vector
    @11 0x44  00000000
```

# jal_back

Description:
    rd = PC+4; PC += imm

    jal rd, offset

x1 = 5

x2 = 5

produced    = 0000 0000 0000 0011 0100 = 0x00034

instruction = 0000 0011 0100 0000 0000

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
    rd  rs1 imm
lw  x5, x4, 0x10

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000010000   00100   010     00101    0000011

0000 0001 0000 0010 0010 0010 1000 0011 = 0x01022283
------------------------------------------------------------------

    rd  rs1 imm
lw  x5, x4, 0x0C

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000001100   00100   010     00101    0000011

0000 0000 1100 0010 0010 0010 1000 0011 = 0x00C22283
------------------------------------------------------------------

    rs1  imm
jal  x1, offset = 12 = C

  imm[20|10:1|11|19:12]   |  rd   | opcode
  00000011010000000000      00001   1101111

0000 0011 0100 0000 0000 0000 1110 1111 = 0x034000EF
```

## Memory layout
```
    WA BA
    @00 0x00  90909090
    @01 0x04  00020083   lw  x1, x4, 0
    @02 0x08  034000EF   jal x1, jumpto
    @03 0x0C  00000000   nothing here because we aren't returning.
    @04 0x10  01022283   lw  x5, x4, 0x10   <-- failed to jump
    @05 0x14  00000099
    @06 0x18  00000000  
    @07 0x1C  00000000  
    @08 0x20  00000000  
    @09 0x24  00000000  
    @0A 0x28  00000000
    @0B 0x2C  00000000
    @0C 0x30  00000005
    @0D 0x34  00000A0A   data for x5   <-- jump taken
    @0E 0x38  00000B0B   data for x5   <-- jump not taken
jumpto:
    @0F 0x3C  00C22283   lw  x5, x4, 0x0C   <-- jump to
    @10 0x40  00000004   Reset vector
    @11 0x44  00000000
```

