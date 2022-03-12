```
--------------------------------------------
All operands are consider Signed
--------------------------------------------
0 + -1 = -1 (good)
(Max-1) +  1 = -8 (bad=overflow)
-1 + 1 = 0 (good)

```

# add_1
Load x1 with byte from word-address **0x0000000A**

Load x2 with byte from word-address **0x0000000B**

Flags: ----

## Description
rd = rs1 + rs2

## rd = x1
Base = x0
```
    rd  rs1 imm
lb  x1, x0, 0x0A     imm = (0x0A)*4 = 0x28

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101000   00000   000     00001    0000011
      |
      \----- = 0x028
0000 0010 1000 0000 0000 0000 1000 0011 = 0x02800083
```

## rd = x2
```
    rd  rs1 imm
lb  x2, x0, 0x0B     imm = (0x0B)*4 = 0x2C

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101100   00000   000     00010    0000011
      |
      \----- = 0x02C
0000 0010 1100 0000 0000 0001 0000 0011 = 0x02C00103
```

## add
```
     rd  rs1 rs2
add  x3, x1, x2

   func7   |  rs2  |  rs1  | funct3 |   rd  |  opcode
  0000000    00010   00001    000     00011    0110011 = 0x002081B3
```

x3 should end up with a value of 0x0000000B

## Memory layout
```
@0 00000002
@1 02800083  lb  x1, 0x0A(x0)
@2 02C00103  lb  x2, 0x0B(x0)
@3 002081B3  add x3, x1, x2
@4 00100073  ebreak
@5 0000000A     
@6 00000000     
@7 00000000     
@8 00000000     
@9 00000000     
@A 00000005  <-- data for x1
@B 00000006  <-- data for x2
...
@10 00000004  Reset vector
@11 00000000
```

```
-----------------------------------------------
--
-----------------------------------------------
```

# add_2
Add 5 + (-7) 

Load x1 with byte from word-address **0x0000000A**

Load x2 with byte from word-address **0x0000000B**

x3 should = 0xFFFFFFFE = -2

Flags: -N--

## Memory layout
```
@0 00000002
@1 02800083  lb  x1, x0, 0x0A
@2 02C00103  lb  x2, x0, 0x0B
@3 002081B3  add x3, x1, x2
@4 00100073  ebreak
@5 0000000A     
...
@A 00000005  data for x1   +5
@B 000000F9  data for x2   -7
...
@10 00000004 Reset vector
@11 00000000
```

```
-----------------------------------------------
--
-----------------------------------------------
```

# add_carry
Add 0xFFFFFFFF + 1   == -1 + 1
Flags: --CZ

x3 should = 0x00

## Memory layout
```
@0 00000002
@1 00022083  lw  x1, x4, 0
@2 00822103  lw  x2, x4, 2
@3 002081B3  add x3, x1, x2
@4 00100073  ebreak
@5 0000000A     
...
@A FFFFFFFF     <-- data for x1
@B 00000000
@C 00000001     <-- data for x2
...
@10 00000004  Reset vector
@11 00000000
```

```
-----------------------------------------------
--
-----------------------------------------------
```

# add_overflow
Add 0x7FFFFFFF + 1
Flags: VN--

x3 should = 0x00

## Memory layout
```
@0 00000002
@1 00022083  lw  x1, x4, 0
@2 00822103  lw  x2, x4, 2
@3 002081B3  add x3, x1, x2
@4 00100073  ebreak
@5 0000000A     
...
@A 7FFFFFFF     <-- data for x1
@B 00000000
@C 00000001     <-- data for x2
...
@10 00000004  Reset vector
@11 00000000
```

```
-----------------------------------------------
--
-----------------------------------------------
```

# add_neg
Add 0xFFFFFFFF + 0
Flags: -N--

x3 should = 0x00

## Memory layout
```
@0 00000002
@1 00022083  lw  x1, x4, 0
@2 00822103  lw  x2, x4, 2
@3 002081B3  add x3, x1, x2
@4 00100073  ebreak
@5 0000000A     
...
@A FFFFFFFF     <-- data for x1
@B 00000000
@C 00000000     <-- data for x2
...
@10 00000004  Reset vector
@11 00000000
```

```
-----------------------------------------------
--
-----------------------------------------------
```

# add_neg_2
Add 0xFFFFFFF8 + 8
Flags: -N--

x3 should = 0x00

## Memory layout
```
@0 00000002
@1 00022083  lw  x1, x4, 0
@2 00822103  lw  x2, x4, 2
@3 002081B3  add x3, x1, x2
@4 00100073  ebreak
@5 0000000A     
...
@A FFFFFFF8     <-- data for x1
@B 00000000
@C 00000008     <-- data for x2
...
@10 00000004  Reset vector
@11 00000000
```

