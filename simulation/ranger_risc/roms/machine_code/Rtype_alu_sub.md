# RType_sub_pos
Sub 5 - 2 

Flags: ----

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

x3 should = 0x00000003

```
    rd  rs1 imm
lb  x1, x4, 0

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000000000   00100   000     00001    0000011   = 0x00020083

    rd  rs1 imm
lb  x2, x4, BA:0x08 = 2*4

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000001000   00100   000     00010    0000011   = 0x00820103

     rd  rs1-rs2
sub  x3, x1, x2

   func7   |  rs2  |  rs1  | funct3 |   rd  |  opcode
  0100000    00010   00001    000     00011    0110011 = 0x402081B3
```

## Memory layout
```
@0 00000002
@1 00020083     <-- lb  x1, x4, 0
@2 00820103     <-- lb  x2, x4, 2
@3 402081B3     <-- sub x3, x1, x2
@4 00000008     
@5 0000000A     
...
@A 00000005     <-- data for x1
@B 00000000
@C 00000002     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_sub_eq
Sub 5 - 5 

Flags: ---Z

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

x3 should = 0x00000000

## Memory layout
```
@0 00000002
@1 00020083     <-- lb  x1, x4, 0
@2 00820103     <-- lb  x2, x4, 2
@3 402081B3     <-- sub x3, x1, x2
@4 00000008     
@5 0000000A     
...
@A 00000005     <-- data for x1
@B 00000000
@C 00000005     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_sub_neg
Sub 5 - 7 

Flags: NC-

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

x3 should = 0x00000000

## Memory layout
```
@0 00000002
@1 00020083     <-- lb  x1, x4, 0
@2 00820103     <-- lb  x2, x4, 2
@3 402081B3     <-- sub x3, x1, x2
@4 00000008     
@5 0000000A     
...
@A 00000005     <-- data for x1
@B 00000000
@C 00000007     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_sub_neg_2
Sub 5 - (-2)   -2 = 0xFE

Flags: --C-

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

x3 should = 0x00000000

## Memory layout
```
@0 00000002
@1 00020083     <-- lb  x1, x4, 0
@2 00820103     <-- lb  x2, x4, 2
@3 402081B3     <-- sub x3, x1, x2
@4 00000008     
@5 0000000A     
...
@A 00000005     <-- data for x1
@B 00000000
@C 000000FE     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_sub_lw_neg
Sub 2 - 0x7FFFFFFF

Flags: -NC-

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

x3 should = 0x00000003

```
    rd  rs1 imm
lw  x1, x4, 0

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000000000   00100   010     00001    0000011   = 0x00022083

    rd  rs1 imm
lw  x2, x4, BA:0x08 = 2*4

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000001000   00100   010     00010    0000011   = 0x00822103

     rd  rs1-rs2
sub  x3, x1, x2

   func7   |  rs2  |  rs1  | funct3 |   rd  |  opcode
  0100000    00010   00001    000     00011    0110011 = 0x402081B3
```

## Memory layout
```
@0 00000002
@1 00022083     <-- lw  x1, x4, 0
@2 00822103     <-- lw  x2, x4, 2
@3 402081B3     <-- sub x3, x1, x2
@4 00000008     
@5 0000000A     
...
@A 00000002     <-- data for x1
@B 00000000
@C 7FFFFFFF     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```


---------------------------
Unsigned
---------------------------

# RType_cmp_bltu
NOTE: this test only checks the flags. There is a separate test for the actual *bltu* instruction.

rs1 < rs2 = **true**. Check if  C==1
```
    rs1          rs2
+4,294,967,295 > +1

    x1           x2
Sub 0xFFFFFFFF - 1        ==> 0xFFFFFFFE

Flags: -N--
If we swap @A and @C then
1 - 0xFFFFFFFF 
Flags: --C-

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

x3 should = 0x00000000

    rd  rs1 rs2
sub x3, x1, x2      rs1 - rs2  == x1 - x2

```

## Memory layout
```
@0 00000002
@1 00020083     <-- lb  x1, x4, 0
@2 00820103     <-- lb  x2, x4, 2
@3 402081B3     <-- sub x3, x1, x2
@4 00000008     
@5 0000000A     
...
@A FFFFFFFF     <-- data for x1
@B 00000000
@C 00000001     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```


```
If unsigned:

x1  x2
0 -  1 = 15 (bad)  -NC-
0 + 15 = 15 (good)
7 +  1 =  8 (good)
15 + 1 =  0 (bad)

if signed:

0 -  1 = -1 (good)
0 + -1 = -1 (good)
7 +  1 = -8 (bad)
-1 + 1 = 0 (good)
```