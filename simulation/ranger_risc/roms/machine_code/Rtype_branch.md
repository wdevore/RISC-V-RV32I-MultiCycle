## Branching instructions

# BType_beq

Description:
    if (rs1 == rs2) PC += imm

x1 = 5
x2 = 5
offset = 3*4 = 12 = 0x0C

produced    = 0b0000000 01100
instruction = 0b0000 0000 1100 = 0x00C

Flags: ---Z

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
    rs1==rs1   imm
beq  x1, x2,  offset = 12 = C

imm[12]|imm[10:5] | rs2 | rs1 | funct3 | imm[4:1]|imm[11] | opcode
    0000000        00010 00001    000         01100         1100011

0000 0000 0010 0000 1000 0110 0110 0011 = 0x00208663
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  00020083     lb  x1, x4, 0
    @2 0x08  00820103     lb  x2, x4, 8
    @3 0x0C  00208663     beg x1, x2, offset
    @4 0x10  01022283     lw  x5, x4, 0x10   <-- not taken path
    @5 0x14  00000000
offset:
    @6 0x18  00C22283     lw  x5, x4, 0x0C   <-- taken path
    ...
    @A 0x28  00000005     data for x1
    @B 0x2C  00000000
    @C 0x30  00000005     data for x2
    @D 0x34  00000A0A     data for x5   <-- branch taken
    @E 0x38  00000B0B     data for x5   <-- branch not taken
    ...
    @10 0x40 00000004     Reset vector
    @11 0x44 00000000
```

