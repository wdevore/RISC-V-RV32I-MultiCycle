## sll, srl, sra, slt, sltu


# RType_sll
Description:
          value  shift-by
     rd = rs1 << rs2

  32'b0111 0000 0000 0011 1100 0000 1001 0000 x1 = 0x7003C090
  32'b0000 0000 0000 0000 0000 0000 0000 0010 x2 = 2
-------------
  32'b1100 0000 0000 1111 0000 0010 0100 0000 x3 = 0xC00F0240

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
     rd  rs1&rs2
sll  x3, x1, x2

   func7   |  rs2  |  rs1  | funct3 |   rd  |  opcode
  0000000    00010   00001    001     00011    0110011 = 0x002091B3

```

## Memory layout
```
@0 00000002
@1 00022083     <-- lw  x1, x4, 0
@2 00820103     <-- lb  x2, x4, 8
@3 002091B3     <-- sll x3, x1, x2
@4 00000008     
@5 0000000A     
...
@A 7003C090     <-- data for x1
@B 00000000
@C 00000002     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_srl
Description:
          value  shift-by
     rd = rs1 >> rs2

  32'b0111 0000 0000 0011 1100 0000 1001 0000 x1 = 0x7003C090
  32'b0000 0000 0000 0000 0000 0000 0000 0010 x2 = 2
-------------
  32'b0001 1100 0000 0000 1111 0000 0010 0100 x3 = 0x1C00F024

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
     rd  rs1&rs2
srl  x3, x1, x2

   func7   |  rs2  |  rs1  | funct3 |   rd  |  opcode
  0000000    00010   00001    101     00011    0110011 = 0x0020D1B3

```

## Memory layout
```
@0 00000002
@1 00022083     <-- lw  x1, x4, 0
@2 00820103     <-- lb  x2, x4, 8
@3 0020D1B3     <-- sll x3, x1, x2
@4 00000008     
@5 0000000A     
...
@A 7003C090     <-- data for x1
@B 00000000
@C 00000002     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_sra
Description:
          value  shift-by
     rd = rs1 >> rs2

  32'b1001 0000 0000 0011 1100 0000 1001 0000 x1 = 0x9003C090
  32'b0000 0000 0000 0000 0000 0000 0000 0010 x2 = 2
-------------
  32'b1110 0100 0000 0000 1111 0000 0010 0100 x3 = 0xE400F024

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
     rd  rs1&rs2
sra  x3, x1, x2

   func7   |  rs2  |  rs1  | funct3 |   rd  |  opcode
  0100000    00010   00001    101     00011    0110011 = 0x4020D1B3

```

## Memory layout
```
@0 00000002
@1 00022083     <-- lw  x1, x4, 0
@2 00820103     <-- lb  x2, x4, 8
@3 4020D1B3     <-- sll x3, x1, x2
@4 00000008     
@5 0000000A     
...
@A 9003C090     <-- data for x1
@B 00000000
@C 00000002     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_slt_1
Description:
          value  shift-by
     rd = (rs1 < rs2)?1:0

x1 = 0x09
x2 = 0x0A
x3 = 0x00000001
x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
     rd  rs1<rs2
slt  x3, x1, x2

   func7   |  rs2  |  rs1  | funct3 |   rd  |  opcode
  0000000    00010   00001    010     00011    0110011 = 0x0020A1B3

```

## Memory layout
```
@0 00000002
@1 00022083     <-- lw  x1, x4, 0
@2 00820103     <-- lb  x2, x4, 8
@3 0020A1B3     <-- slt x3, x1, x2
@4 00000008     
@5 0000000A     
...
@A 00000009     <-- data for x1
@B 00000000
@C 0000000A     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_slt_2
Description:
          value  shift-by
     rd = (rs1 < rs2)?1:0

x1 = 0x0A
x2 = 0x09
x3 = 0x00000000
x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
     rd  rs1<rs2
slt  x3, x1, x2

   func7   |  rs2  |  rs1  | funct3 |   rd  |  opcode
  0000000    00010   00001    010     00011    0110011 = 0x0020A1B3

```

## Memory layout
```
@0 00000002
@1 00022083     <-- lw  x1, x4, 0
@2 00820103     <-- lb  x2, x4, 8
@3 0020A1B3     <-- slt x3, x1, x2
@4 00000008     
@5 0000000A     
...
@A 0000000A     <-- data for x1
@B 00000000
@C 00000009     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_slt_3
Description:
          value  shift-by
     rd = (rs1 < rs2)?1:0

x1 = 0xFFFFFFFE  = -2
x2 = 0x09
x3 = 0x00000001
x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
     rd  rs1<rs2
slt  x3, x1, x2

   func7   |  rs2  |  rs1  | funct3 |   rd  |  opcode
  0000000    00010   00001    010     00011    0110011 = 0x0020A1B3

```

## Memory layout
```
@0 00000002
@1 00022083     <-- lw  x1, x4, 0
@2 00820103     <-- lb  x2, x4, 8
@3 0020A1B3     <-- slt x3, x1, x2
@4 00000008     
@5 0000000A     
...
@A FFFFFFFE     <-- data for x1
@B 00000000
@C 00000009     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_sltu_1
Description:
          value  shift-by
     rd = (rs1 < rs2)?1:0

x1 = 0xFFFFFFFE
x2 = 0x09
x3 = 0x00000000
x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
      rd  rs1<rs2
sltu  x3, x1, x2

   func7   |  rs2  |  rs1  | funct3 |   rd  |  opcode
  0000000    00010   00001    011     00011    0110011 = 0x0020B1B3
0000 0000 0010 0000 1011 0001 1011 0011
```

## Memory layout
```
@0 00000002
@1 00022083     <-- lw   x1, x4, 0
@2 00820103     <-- lb   x2, x4, 8
@3 0020B1B3     <-- sltu x3, x1, x2
@4 00000008     
@5 0000000A     
...
@A FFFFFFFE     <-- data for x1
@B 00000000
@C 00000009     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```
