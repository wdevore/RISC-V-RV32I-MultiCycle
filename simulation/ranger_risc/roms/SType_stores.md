# SType_sw
Store x14 to word-address d4 or 0x00000010

First we load x14 with **0xBEEFDEAD** from address **@A**. 
x14 is already preloaded in a *initial* block. See RegisterFile.sv

M[rs1+imm][0:31] = rs2[0:31]

```
   rs2  rs1   imm
sw x14, x0    0x00000004 = 4*(4 bytes) = 0x00000010  ----->\
--**--**--**--**--**--**--**--**--**--**--**--**--**        |
   imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode    |
   0000000     01110  00000    010      10000     0100011   |
      ^                                   ^                 v
      |-----------------------------------|-----------------/

  0    0    E    0    2    8    2    3
0000 0000 1110 0000 0010 1000 0010 0011 = 0x00E02823
```

## Memory layout (big endian)
```
@0 00000002
@1 00E02823     <-- instruction under test ----.
@2 00000004                                    |
@3 00000006                                    |
@4 00000008     <-- x14's data stored here     |
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

# SType_sb_1
Store x14's lowest byte "0xAD" to word-address d4 or byte address 0x00000010

Address 0x00000010 = 0x111111AD

First we load x14 with **0xBEEFDEAD** from address **@A**. 
x14 is already preloaded in a *initial* block. See RegisterFile.sv

M[rs1+imm][0:7] = rs2[0:7]

```
   rs2   rs1  imm
sb x14,  x0   0x00000004 = 4*(4 bytes) = 0x00000010
--**--**--**--**--**--**--**--**--**--**--**--**--**
   imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
   0000000     01110  00000    000      10000     0100011

  0    0    E    0    0    8    2    3
0000 0000 1110 0000 0000 1000 0010 0011 = 0x00E00823
```

## Memory layout (big endian)
```
@0 00000002
@1 00E00823     <-- instruction under test ----.
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

# SType_sb_2
Store x14's lowest byte "0xAD" to word-address d4 byte = address 0x00000010 + 1 = 0x00000011

Address [0x00000011] = 0x1111**AD**11

First we load x14 with **0xBEEFDEAD** from address **@A**. 
x14 is already preloaded in a *initial* block. See RegisterFile.sv

M[rs1+imm][0:7] = rs2[0:7]

```
   rs2   rs1  imm
sb x14,  x0   0x00000004 = 4*(4 bytes) + 1 = 0x00000011
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

Address [0x00000012] = 0x11**AD**1111

First we load x14 with **0xBEEFDEAD** from address **@A**. 
x14 is already preloaded in a *initial* block. See RegisterFile.sv

M[rs1+imm][0:7] = rs2[0:7]

```
   rs2   rs1  imm
sb x14,  x0   0x00000004 = 4*(4 bytes) + 2 = 0x00000012
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

Address [0x00000013] = 0x**AD**111111

First we load x14 with **0xBEEFDEAD** from address **@A**. 
x14 is already preloaded in a *initial* block. See RegisterFile.sv

M[rs1+imm][0:7] = rs2[0:7]

```
   rs2   rs1  imm
sb x14,  x0   0x00000004 = 4*(4 bytes) + 2 = 0x00000012
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


-----------------------------------------------------

# Inprogress ------------------------------------

# SType_lw_sw
Store x14 to word-address d4 or 0x00000010

M[rs1+imm][0:31] = rs2[0:31]

First we load x14 with 0xBEEFDEAD from address @A
```
   rs2  rs1   imm
sw x14, x0    0x00000004 = 4*(4 bytes) = 0x00000010
--**--**--**--**--**--**--**--**--**--**--**--**--**
   imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode
   0000000     01110  00000    010      10000     0100011

  0    0    E    0    2    8    2    3
0000 0000 1110 0000 0010 1000 0010 0011 = 0x00E02823
```

## Memory layout (big endian)
```
@0 00000002
@1 02802983     <-- instruction under test ----.
@2 00E02823                                    |
@3 00000006                                    |
@4 00000008     <-- x14's data stored here     |
@5 0000000A                                    |
@6 00000000                                    |
@7 00000000                                    |
@8 00000000                                    |
@9 00000000                                    |
@A BEEFDEAD     <-- x14 loaded with this       |
...                                            |
@10 00000004    <-- Reset vector pointing to --/
@11 00000000
```
