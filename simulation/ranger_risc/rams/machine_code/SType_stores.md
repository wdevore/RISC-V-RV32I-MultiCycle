# SType_sb_1
Store x14's lowest byte "0xAD" to word-address d4 or byte address 0x00000010

Address 0x00000010 = 0x111111AD

First we load x14 with **0xBEEFDEAD** from address **@A**. 
x14 is already preloaded in a *initial* block. See RegisterFile.sv

M[rs1+imm][0:7] = rs2[0:7]

```
   rs2  imm   rs1
sb x14, 0x010(x0)
imm = WA:0x00000004 = BA:4*(4 bytes) = 0x00000010
--**--**--**--**--**--**--**--**--**--**--**--**--**
   imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
   0000000     01110  00000    000      10000     0100011

  0    0    E    0    0    8    2    3
0000 0000 1110 0000 0000 1000 0010 0011 = 0x00E00823
```

## Memory layout (big endian)
```
@00 0x00 00000002
@01 0x04 00E00823  sb x14, 0x010(x0)
@02 0x08 00100073  ebreak
@03 0x0C 00000006  
@04 0x10 11111111  x14's data merged here
@05 0x14 0000000A  
@06 0x18 00000000  
@07 0x1C 00000000  
@08 0x20 00000000  
@09 0x24 00000000  
@0A 0x28 00000000  
...          
@10 0x40 00000004 Reset vector
@11 0x44 00000000
```

# SType_sb_2
Store x14's lowest byte "0xAD" to word-address d4 byte = address 0x00000010 + 1 = 0x00000011

Byte Address [0x00000011] = 0x1111**AD**11

First we load x14 with **0xBEEFDEAD** from address **@A**. 
x14 is already preloaded in a *initial* block. See RegisterFile.sv

M[rs1+imm][0:7] = rs2[0:7]

```
   rs2    imm   rs1
sb x14, 0x010+1(x0)
imm = BA:4*(4 bytes)+1 = 0x00000011

--**--**--**--**--**--**--**--**--**--**--**--**--**
   imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
   0000000     01110  00000    000      10001     0100011

  0    0    E    0    0    8    A    3
0000 0000 1110 0000 0000 1000 1010 0011 = 0x00E008A3
```

## Memory layout (big endian)
```
@0 00000002
@1 00E008A3     <-- instruction under test ----.
@2 00000004                                    |
@3 00000006                                    |
@4 11111111     <-- x14's data merged here     |
@5 0000000A                                    |
@6 00000000                                    |
@7 00000000                                    |
@8 00000000                                    |
@9 00000000                                    |
@A 00000000                                    |
...                                            |
@10 00000004    <-- Reset vector pointing to --/
@11 00000000
```

# SType_sb_3
Store x14's lowest byte "0xAD" to word-address d4 byte = address 0x00000010 + 2 = 0x00000012

Byte Address [0x00000012] = 0x11**AD**1111

First we load x14 with **0xBEEFDEAD** from address **@A**. 
x14 is already preloaded in a *initial* block. See RegisterFile.sv

M[rs1+imm][0:7] = rs2[0:7]

```
   rs2   imm    rs1
sb x14, 0x010+2(x0)
imm = BA:4*(4 bytes)+2 = 0x00000012

--**--**--**--**--**--**--**--**--**--**--**--**--**
   imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
   0000000     01110  00000    000      10010     0100011

  0    0    E    0    0    9    2    3
0000 0000 1110 0000 0000 1001 0010 0011 = 0x00E00923
```

## Memory layout (big endian)
```
@0 00000002
@1 00E00923     <-- instruction under test ----.
@2 00000004                                    |
@3 00000006                                    |
@4 11111111     <-- x14's data merged here     |
@5 0000000A                                    |
@6 00000000                                    |
@7 00000000                                    |
@8 00000000                                    |
@9 00000000                                    |
@A 00000000                                    |
...                                            |
@10 00000004    <-- Reset vector pointing to --/
@11 00000000
```

# SType_sb_4
Store x14's lowest byte "0xAD" to word-address d4 byte = address 0x00000010 + 3 = 0x00000013

Byte Address [0x00000013] = 0x**AD**111111

First we load x14 with **0xBEEFDEAD** from address **@A**. 
x14 is already preloaded in a *initial* block. See RegisterFile.sv

M[rs1+imm][0:7] = rs2[0:7]

```
   rs2    imm   rs1
sb x14, 0x010+3(x0)
imm = BA:4*(4 bytes)+3 = 0x00000013

--**--**--**--**--**--**--**--**--**--**--**--**--**
   imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
   0000000     01110  00000    000      10011     0100011

  0    0    E    0    0    9    2    3
0000 0000 1110 0000 0000 1001 1010 0011 = 0x00E009A3
```

## Memory layout (big endian)
```
@0 00000002
@1 00E009A3     <-- instruction under test ----.
@2 00000004                                    |
@3 00000006                                    |
@4 11111111     <-- x14's data merged here     |
@5 0000000A                                    |
@6 00000000                                    |
@7 00000000                                    |
@8 00000000                                    |
@9 00000000                                    |
@A 00000000                                    |
...                                            |
@10 00000004    <-- Reset vector pointing to --/
@11 00000000
```

# SType_sh_1
Store x14's lowest half-word "0xDEAD" to word-address d4 byte = address 0x00000010 + 0 = 0x00000010

Byte Address [0x00000010] = 0x1111**DEAD**

First we load x14 with **0xBEEFDEAD** from address **@A**. 
x14 is already preloaded in a *initial* block. See RegisterFile.sv

M[rs1+imm][0:15] = rs2[0:15]

```
   rs2   imm  rs1
sh x14, 0x010(x0)
imm = BA:4*(4 bytes) = 0x00000010

--**--**--**--**--**--**--**--**--**--**--**--**--**
   imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
   0000000     01110  00000    001      10000     0100011

0000 0000 1110 0000 0001 1000 0010 0011 = 0x00E01823
```

## Memory layout (big endian)
```
@0 00000002
@1 00E01823     <-- instruction under test
@2 00000004                               
@3 00000006                               
@4 11111111     <-- x14's data merged here
@5 0000000A                               
@6 00000000                               
@7 00000000                               
@8 00000000                               
@9 00000000                               
@A 00000000                               
...                                       
@10 00000004    <-- Reset vector
@11 00000000
```

# SType_sh_2
Store x14's lowest half-word "0xDEAD" to word-address d4 byte = address 0x00000010 + 2'b10 = 0x00000012

Byte Address [0x00000012] = 0x**DEAD**1111

First we load x14 with **0xBEEFDEAD** from address **@A**. 
x14 is already preloaded in a *initial* block. See RegisterFile.sv

M[rs1+imm][0:15] = rs2[0:15]

```
   rs2    imm   rs1
sh x14, 0x010+2(x0)
imm = BA:4*(4 bytes)+2 = 0x00000012

--**--**--**--**--**--**--**--**--**--**--**--**--**
   imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
   0000000     01110  00000    001      10010     0100011

0000 0000 1110 0000 0001 1001 0010 0011 = 0x00E01923
```

## Memory layout (big endian)
```
@0 00000002
@1 00E01923     <-- instruction under test
@2 00000004                               
@3 00000006                               
@4 11111111     <-- x14's data merged here
@5 0000000A                               
@6 00000000                               
@7 00000000                               
@8 00000000                               
@9 00000000                               
@A 00000000                               
...                                       
@10 00000004    <-- Reset vector
@11 00000000
```

```
-------------------------------------------------------------------------
-- Words
-------------------------------------------------------------------------
```

# SType_sw
Store x14 to word-address d4 or 0x00000010

First we load x14 with **0xBEEFDEAD** from address **@A**. 
x14 is already preloaded in a *initial* block. See RegisterFile.sv

M[rs1+imm][0:31] = rs2[0:31]

```
   rs2   imm  rs1
sw x14, 0x010(x0)
imm = BA:4*(4 bytes) = 0x00000010                    ----->\
                                                            |
--**--**--**--**--**--**--**--**--**--**--**--**--**        |
   imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode    |
   0000000     01110  00000    010      10000     0100011   |
      ^                                   ^                 |
      |-----------------------------------|-----------------.

  0    0    E    0    2    8    2    3
0000 0000 1110 0000 0010 1000 0010 0011 = 0x00E02823
```

## Memory layout (big endian)
```
@00 0x00 00000002
@01 0x04 00E02823  sw x14, 0x010(x0)
@02 0x08 00100073  ebreak
@03 0x0C 00000006  
@04 0x10 00000008  x14's data stored here
@05 0x14 0000000A  
@06 0x18 00000000  
@07 0x1C 00000000  
@08 0x20 00000000  
@09 0x24 00000000  
@0A 0x28 00000000  
...          
@10 0x40 00000004 Reset vector
@11 0x44 00000000
```

# SType_sw_neg
- WA = word-address
- BA = byte-address

Goal:
Store x14's content to WA:0x08. The address computed as rs1+imm.

We need three things:
1) x14 loaded with the value that will be stored to a destination address
2) x2 (aka rs1) loaded with a *base* address for the "sw" instruction
3) Compute an immediate for the "sw" instruction

## #1
Pre-load **x14** with **0xBEEFDEAD** from an *initial* block. See *RegisterFile.sv*

## #2
We use an actual instruction to load x2 with WA:0x0A = BA:0x28, rather pre-load. This is the *base* for the "sw" instruction.

```
     rd   rs1   imm
lhu  x2,  x0,   0x28

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101000   00000   101     00010    0000011
      |
       \----- = 0x028
0000 0010 1000 0000 0101 0001 0000 0011 = 0x02805103
```
## #3
Now for the main instruction which stores rs2's (aka x14) content to @8. @8 is computed by rs1 + imm = x2 + imm. x2 was loaded during **#2**. Because the *base* is @A we need an "imm" of -2 to point to @8.

Using 2's complement we get **0xFF8**:
```
imm = -2 * 4 = -8 = (0000 0000 0010 << 2) = 0000 0000 1000
-8 is computed via 2's complement:
0000 0000 1000 => 1111 1111 1000 = 0xFF8 (12 bit signed offset)
```

Which give us: rs1 + imm = 0x28 + 0xFF8 = WA:**0x08** , BA:0x20

**Description**: M[rs1+imm][0:31] = rs2[0:31]

```
   rs2   imm  rs1
sw x14, 0xFF8(x2)

   imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
   1111111     01110  00010    010      11000     0100011

1111 1110 1110 0001 0010 1100 0010 0011 = 0xFEE12C23
```


## Memory layout (big endian)
```
@0 00000002
@1 02805103     <-- lbu x2,  x0, 0x28
@2 FEE12C23     <-- sw  x14, x2, 0xFF8
@3 00000006                               
@4 00000008     
@5 0000000A                               
@6 00000000                               
@7 00000000                               
@8 00000000     <-- x14's data stored here
@9 00000000                               
@A 00000000     <-- x2 points here
...                                       
@E                                        
@F                                        
@10 00000004    <-- Reset vector pointing 
@11 00000000
```

# SType_lw_sw
Store x14 to word-address d4 or 0x00000010

M[rs1+imm][0:31] = rs2[0:31]

First we load x14 with 0xD0A0DEAD from address @A
```
    rd  imm  rs1 
lw x14, 0x28(x0)     imm = (0x0A)*4 = 0x28

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101000   00000   010     01110    0000011
      |
      \----- = 0x028
0000 0010 1000 0000 0010 0111 0000 0011 = 0x02802703
```
Then we store it to address @4
```
   rs2   imm  rs1
sw x14, 0x010(x0)

--**--**--**--**--**--**--**--**--**--**--**--**--**
   imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
   0000000     01110  00000    010      10000     0100011

  0    0    E    0    2    8    2    3
0000 0000 1110 0000 0010 1000 0010 0011 = 0x00E02823
```

## Memory layout (big endian)
```
@0 00000002
@1 02802703     load x14 first from address @A below
@2 00E02823     <-- instruction under test ----.
@3 00000006                                    |
@4 00000008     <-- x14's data stored here     |
@5 0000000A                                    |
@6 00000000                                    |
@7 00000000                                    |
@8 00000000                                    |
@9 00000000                                    |
@A D0A0DEAD     <-- x14 loaded with this       |
...                                            |
@10 00000004    <-- Reset vector pointing to --/
@11 00000000
```

# SType_lw_sw_lw
Tests that "sw" sets the mem_rd = 1'b0. Every instruction must set mem_rd active in the last state.

Store x14 to word-address d4 or 0x00000010

M[rs1+imm][0:31] = rs2[0:31]

First we load x14 with 0xD0A0DEAD from address @A
```
    rd  imm  rs1 
lw x14, 0x28(x0)     imm = (0x0A)*4 = 0x28

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101000   00000   010     01110    0000011
      |
      \----- = 0x028
0000 0010 1000 0000 0010 0111 0000 0011 = 0x02802703
```
Then we store it to address @4
```
   rs2   imm  rs1
sw x14, 0x010(x0)    0x00000004 = 4*(4 bytes) = 0x00000010

--**--**--**--**--**--**--**--**--**--**--**--**--**
   imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
   0000000     01110  00000    010      10000     0100011

  0    0    E    0    2    8    2    3
0000 0000 1110 0000 0010 1000 0010 0011 = 0x00E02823
```

## Memory layout (big endian)
```
@0 00000002
@1 02802703     load x14 first from address @A below
@2 00E02823     store to @4
@3 02C00103     lb  x2, x0, 0x0B     
@4 00000008     x14's data stored here
@5 0000000A     
@6 00000000     
@7 00000000     
@8 00000000     
@9 00000000     
@A D0A0DEAD     x14 loaded with this
@B C0DE1DAC     x2 loaded with this
...             
@10 00000004    Reset vector
@11 00000000
```
