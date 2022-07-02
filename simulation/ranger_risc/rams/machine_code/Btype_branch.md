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

To test "not" taken branch change either @A or @C to a value different than the other.

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  00020083   lw  x1, 0x0(x4)    <-- x4 preloaded with 0x28
    @2 0x08  00820103   lw  x2, 0x8(x4)
    @3 0x0C  00209663   bne x1, x2, @offset
    @4 0x10  01022283   lw  x5, 0x10(x4)   <-- not taken path
    @5 0x14  00100073   ebreak
offset:
    @6 0x18  00C22283   lw  x5, 0x0C(x4)   <-- taken path
    @7 0x1C  00100073   ebreak
    ...
    @A 0x28  00000005   data for x1
    @B 0x2C  00000000
    @C 0x30  00000005   data for x2
    @D 0x34  00000A0A   data for x5   <-- branch taken
    @E 0x38  00000B0B   data for x5   <-- branch not taken
    @F 0x3C  00100073   ebreak
    @10 0x40 00000004   -- Reset vector
    @11 0x44 00000000
```

# BType_blt

Description:
    if (rs1 < rs2) PC += imm

x1 = 4

x2 = 5

offset = 3*4 = 12 = 0x0C

produced    = 0b0000000 01100

instruction = 0b0000 0000 1100 = 0x00C

Flags: -NC-

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
    rs1<rs1   imm
blt  x1, x2,  offset = 12 = C

imm[12]|imm[10:5] | rs2 | rs1 | funct3 | imm[4:1]|imm[11] | opcode
    0000000        00010 00001    100         01100         1100011

0000 0000 0010 0000 1100 0110 0110 0011 = 0x0020C663
```

To test "not" taken branch make @A > @C

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  00020083   lw  x1, x4, 0
    @2 0x08  00820103   lw  x2, x4, 8
    @3 0x0C  0020C663   blt x1, x2, @offset
    @4 0x10  01022283   lw  x5, x4, 0x10   <-- not taken path
    @5 0x14  00100073   ebreak
offset:
    @6 0x18  00C22283   lw  x5, x4, 0x0C   <-- taken path
    ...
    @A 0x28  00000004   data for x1
    @B 0x2C  00000000
    @C 0x30  00000005   data for x2
    @D 0x34  00000A0A   data for x5   <-- branch taken
    @E 0x38  00000B0B   data for x5   <-- branch not taken
    @F 0x3C  00100073   ebreak
    @10 0x40 00000004   Reset vector
    @11 0x44 00000000
```

# BType_bge

Description:
    if (rs1 >= rs2) PC += imm

x1 = 4

x2 = 5

offset = 3*4 = 12 = 0x0C

produced    = 0b1100

instruction = 0b0000 0000 1100 0 = 0x00C

Flags: -NC-

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
    rs1>=rs1   imm
bge  x1, x2,  offset = 12 = C

imm[12]|imm[10:5] | rs2 | rs1 | funct3 | imm[4:1]|imm[11] | opcode
    0000000        00010 00001    101         01100         1100011

0000 0000 0010 0000 1101 0110 0110 0011 = 0x0020D663
```

To test "not" taken branch make @A < @C

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  00020083   lw  x1, x4, 0
    @2 0x08  00820103   lw  x2, x4, 8
    @3 0x0C  0020D663   bge x1, x2, @offset
    @4 0x10  01022283   lw  x5, x4, 0x10   <-- not taken path
    @5 0x14  00100073   ebreak
offset:
    @6 0x18  00C22283   lw  x5, x4, 0x0C   <-- taken path
    ...
    @A 0x28  00000005   data for x1
    @B 0x2C  00000000
    @C 0x30  00000005   data for x2
    @D 0x34  00000A0A   data for x5   <-- branch taken
    @E 0x38  00000B0B   data for x5   <-- branch not taken
    @F 0x3C  00100073   ebreak
    @10 0x40 00000004   Reset vector
    @11 0x44 00000000
```

# BType_bltu

Description:
    if (rs1 <u rs2) PC += imm

Note:

if considered signed then x1 > x2
if considered unsigned then x1 < x2

x1 = 5

x2 = 0xFFFFFFFE

Flags: --C-     5 < FE

Flags: -N--     FE < 5

offset = 3*4 = 12 = 0x0C

produced    = 0b1100

instruction = 0b0000 0000 1100 0 = 0x00C

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
000000001100   00100   110     00101    0000011

000000001100   00100   110     00101    0000011 = 0x00C22283
------------------------------------------------------------------
      rs1<rs1   imm
bltu  x1, x2,  offset = 12 = C

imm[12]|imm[10:5] | rs2 | rs1 | funct3 | imm[4:1]|imm[11] | opcode
    0000000        00010 00001    110         01100         1100011

0000 0000 0010 0000 1110 0110 0110 0011 = 0x0020E663
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  00020083   lw   x1, x4, 0
    @2 0x08  00820103   lw   x2, x4, 8
    @3 0x0C  0020E663   bltu x1, x2, @offset
    @4 0x10  01022283   lw   x5, x4, 0x10   <-- not taken path
    @5 0x14  00100073   ebreak
offset:
    @6 0x18  00C22283   lw   x5, x4, 0x0C   <-- taken path
    ...
    @A 0x28  00000005   data for x1
    @B 0x2C  00000000
    @C 0x30  FFFFFFFE   data for x2
    @D 0x34  00000A0A   data for x5   <-- branch taken
    @E 0x38  00000B0B   data for x5   <-- branch not taken
    @F 0x3C  00100073   ebreak
    @10 0x40 00000004   Reset vector
    @11 0x44 00000000
```

# BType_bgeu

Description:
    if (rs1 >=u rs2) PC += imm

Note:

x1 = 0xFFFFFFFE

x2 = 5

Flags: -N--     FE >= 5  <-- C=0

offset = 3*4 = 12 = 0x0C

produced    = 0b1100

instruction = 0b0000 0000 1100 0 = 0x00C

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
      rs1<rs1   imm
bgeu  x1, x2,  offset = 12 = C

imm[12]|imm[10:5] | rs2 | rs1 | funct3 | imm[4:1]|imm[11] | opcode
    0000000        00010 00001    111         01100         1100011

0000 0000 0010 0000 1111 0110 0110 0011 = 0x0020F663
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  00020083   lw   x1, x4, 0
    @2 0x08  00820103   lw   x2, x4, 8
    @3 0x0C  0020F663   bgeu x1, x2, @offset
    @4 0x10  01022283   lw   x5, x4, 0x10   <-- not taken path
    @5 0x14  00100073   ebreak
offset:
    @6 0x18  00C22283   lw   x5, x4, 0x0C   <-- taken path
    ...
    @A 0x28  FFFFFFFE   data for x1
    @B 0x2C  00000000
    @C 0x30  00000005   data for x2
    @D 0x34  00000A0A   data for x5   <-- branch taken
    @E 0x38  00000B0B   data for x5   <-- branch not taken
    @F 0x3C  00100073   ebreak
    @10 0x40 00000004   Reset vector
    @11 0x44 00000000
```

