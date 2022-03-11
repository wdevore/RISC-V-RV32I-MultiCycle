## ALU immediate instructions

# IType_addi

Description:
    rd = rs1 + imm  = 0x28 + 0xA = 0x32

x1 = 0x28

x4 = const = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
      rd  rs1+imm
addi  x2, x4, 0x0A

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000001010   00100   000     00010    0010011

0000 0000 1010 0010 0000 0001 0001 0011 = 0x00A20113
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  00A20113  addi x2, x4, 0x0A
    @2 0x08  00100073  ebreak
    @3 0x0C  00000004
    @4 0x10  00000005
    @5 0x14  00000006
    ...
    @A 0x28  0000000A
    @B 0x2C  00000000
    ...
    @10 0x40 00000004  Reset vector
    @11 0x44 00000000
```

# IType_addi_neg

Description:
    rd = rs1 + imm  = 0x28 + 0xFE = 0x28 + (-2) = 0x26

x1 = 0x28

x4 = const = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
      rd  rs1+imm
addi  x2, x4, -2

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
111111111110   00100   000     00010    0010011

1111 1111 1110 0010 0000 0001 0001 0011 = 0xFFE20113
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  FFE20113  addi x2, x4, -2
    @2 0x08  00100073  ebreak
    @3 0x0C  00000004
    @4 0x10  00000005
    @5 0x14  00000006
    ...
    @A 0x28  0000000A
    @B 0x2C  00000000
    ...
    @10 0x40 00000004  Reset vector
    @11 0x44 00000000
```

# IType_xori

Description:
    rd = rs1 ^ imm  = 0x0A ^ 0x05 = 0x0F

x1 = 0x0A

x4 = const = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
    rd  rs1 imm
lw  x1, x4, 0

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000000000   00100   010     00001    0000011 = 0x00022083

      rd  rs1^imm
xori  x2, x1, 0x05

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000000101   00001   100     00010    0010011

0000 0000 0101 0000 1100 0001 0001 0011 = 0x0050C113
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  00022083  lw   x1, x4, 0
    @2 0x08  0050C113  xori x2, x1, 0x05
    @3 0x0C  00100073  ebreak
    @4 0x10  00000005
    @5 0x14  00000006
    ...
    @A 0x28  0000000A  data for x1
    @B 0x2C  00000000
    ...
    @10 0x40 00000004  Reset vector
    @11 0x44 00000000
```

# IType_ori

Description:
    rd = rs1 ^ imm  = 0x0A | 0x05 = 0x0F

x1 = 0x0A

x4 = const = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
    rd  rs1 imm
lw  x1, x4, 0

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000000000   00100   010     00001    0000011 = 0x00022083

      rd  rs1|imm
ori   x2, x1, 0x05

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000000101   00001   110     00010    0010011

0000 0000 0101 0000 1110 0001 0001 0011 = 0x0050E113
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  00022083  lw   x1, x4, 0
    @2 0x08  0050E113  ori  x2, x1, 0x05
    @3 0x0C  00100073  ebreak
    @4 0x10  00000005
    @5 0x14  00000006
    ...
    @A 0x28  0000000A  data for x1
    @B 0x2C  00000000
    ...
    @10 0x40 00000004  Reset vector
    @11 0x44 00000000
```

# IType_andi

Description:
    rd = rs1 & imm  = 0x0A & 0x05 = 0x00

x1 = 0x0A

x4 = const = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
    rd  rs1 imm
lw  x1, x4, 0

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000000000   00100   010     00001    0000011 = 0x00022083

      rd  rs1|imm
andi   x2, x1, 0x05

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000000101   00001   111     00010    0010011

0000 0000 0101 0000 1111 0001 0001 0011 = 0x0050F113
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  00022083  lw   x1, x4, 0
    @2 0x08  0050F113  andi x2, x1, 0x05
    @3 0x0C  00100073  ebreak
    @4 0x10  00000005
    @5 0x14  00000006
    ...
    @A 0x28  0000000A  data for x1
    @B 0x2C  00000000
    ...
    @10 0x40 00000004  Reset vector
    @11 0x44 00000000
```

# IType_slli

Description:
    rd = rs1 & imm  = 0x0A & 0x05 = 0x00

32'b0111 0000 0000 0011 1100 0000 1001 0000 x1 = 0x7003C090

32'b0001 1100 0000 0000 1111 0000 0010 0100 x2 = 0x1C00F024

imm = 2

x4 = const = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
    rd  rs1<<imm
lw  x1, x4, 0

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000000000   00100   010     00001    0000011 = 0x00022083

      rd  rs1|imm
srli   x2, x1, 0x02

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000000010   00001   001     00010    0010011

0000 0000 0010 0000 1001 0001 0001 0011 = 0x00209113
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  00022083  lw   x1, x4, 0
    @2 0x08  00209113  slli x2, x1, 0x02
    @3 0x0C  00100073  ebreak
    @4 0x10  00000005
    @5 0x14  00000006
    ...
    @A 0x28  7003C090  data for x1
    @B 0x2C  00000000
    ...
    @10 0x40 00000004  Reset vector
    @11 0x44 00000000
```

# IType_srli

Description:
    rd = rs1 & imm  = 0x0A & 0x05 = 0x00

32'b0111 0000 0000 0011 1100 0000 1001 0000 x1 = 0x7003C090

32'b0001 1100 0000 0000 1111 0000 0010 0100 x2 = 0x1C00F024

imm = 2

x4 = const = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
    rd  rs1 imm
lw  x1, x4, 0

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000000000   00100   010     00001    0000011 = 0x00022083

      rd  rs1>>imm
srli  x2, x1, 0x02

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000000010   00001   101     00010    0010011

0000 0000 0010 0000 1101 0001 0001 0011 = 0x0020D113
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  00022083  lw   x1, x4, 0
    @2 0x08  0020D113  srli x2, x1, 0x02
    @3 0x0C  00100073  ebreak
    @4 0x10  00000005
    @5 0x14  00000006
    ...
    @A 0x28  7003C090  data for x1
    @B 0x2C  00000000
    ...
    @10 0x40 00000004  Reset vector
    @11 0x44 00000000
```

# IType_srai

Description:
    rd = rs1 & imm  = 0x0A & 0x05 = 0x00

32'b0111 0000 0000 0011 1100 0000 1001 0000 x1 = 0x7003C090

32'b1110 0100 0000 0000 1111 0000 0010 0100 x2 = 0xE400F024

imm = 2

x4 = const = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
    rd  rs1 imm
lw  x1, x4, 0

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000000000   00100   010     00001    0000011 = 0x00022083

      rd  rs1>>imm
srai  x2, x1, 0x02

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
010000000010   00001   101     00010    0010011

0100 0000 0010 0000 1101 0001 0001 0011 = 0x4020D113
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  00022083  lw   x1, x4, 0
    @2 0x08  4020D113  srai x2, x1, 0x02
    @3 0x0C  00100073  ebreak
    @4 0x10  00000005
    @5 0x14  00000006
    ...
    @A 0x28  9003C090  data for x1
    @B 0x2C  00000000
    ...
    @10 0x40 00000004  Reset vector
    @11 0x44 00000000
```

# IType_slti_gt

Description:
    rd = (rs1 < imm)?1:0  = 0x28 < 0xA = false

x4 = const = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
      rd  rs1<imm
slti  x2, x4, 0x0A

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000001010   00100   010     00010    0010011

0000 0000 1010 0010 0010 0001 0001 0011 = 0x00A22113
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  00A22113  slti x2, x4, 0x0A
    @2 0x08  00100073  ebreak
    @3 0x0C  00000004
    @4 0x10  00000005
    @5 0x14  00000006
    ...
    @A 0x28  0000000A  
    @B 0x2C  00000000
    ...
    @10 0x40 00000004  Reset vector
    @11 0x44 00000000
```

# IType_slti_lt

Description:
    rd = (rs1 < imm)?1:0  = 0x28 < 0x30 = true

x4 = const = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
      rd  rs1<imm
slti  x2, x4, 0x30

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000110000   00100   010     00010    0010011

0000 0011 0000 0010 0010 0001 0001 0011 = 0x03022113
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  03022113  slti x2, x4, 0x30
    @2 0x08  00100073  ebreak
    @3 0x0C  00000004
    @4 0x10  00000005
    @5 0x14  00000006
    ...
    @A 0x28  0000000A  
    @B 0x2C  00000000
    ...
    @10 0x40 00000004  Reset vector
    @11 0x44 00000000
```

# IType_slti_lt_neg

Description:
    rd = (rs1 < imm)?1:0  = 0x28 < -2 = false

x4 = const = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
      rd  rs1<imm
slti  x2, x4, -2

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
111111111110   00100   010     00010    0010011

1111 1111 1110 0010 0010 0001 0001 0011 = 0xFFE22113
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  FFE22113  slti x2, x4, -2
    @2 0x08  00100073  ebreak
    @3 0x0C  00000004
    @4 0x10  00000005
    @5 0x14  00000006
    ...
    @A 0x28  0000000A  
    @B 0x2C  00000000
    ...
    @10 0x40 00000004  Reset vector
    @11 0x44 00000000
```

# IType_sltiu

Description:
    rd = (rs1 < imm)?1:0  = 0x28 < 0xFFE = true

x4 = const = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
      rd  rs1<imm
slti  x2, x4, 0xFFE

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
111111111110   00100   011     00010    0010011

1111 1111 1110 0010 0011 0001 0001 0011 = 0xFFE23113
```

## Memory layout
```
    WA BA
    @0 0x00  00000002
    @1 0x04  FFE23113  slti x2, x4, -2
    @2 0x08  00100073  ebreak
    @3 0x0C  00000004
    @4 0x10  00000005
    @5 0x14  00000006
    ...
    @A 0x28  0000000A  
    @B 0x2C  00000000
    ...
    @10 0x40 00000004  Reset vector
    @11 0x44 00000000
```