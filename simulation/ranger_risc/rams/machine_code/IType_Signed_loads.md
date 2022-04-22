# IType_lw
lw => rd = M[rs1+imm][0:31]

```
    rd  imm rs1 
lw x1, 0x28(x0)     imm = (0x0A)*4 = 0x28

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101000   00000   010     00001    0000011
      |
      \----- = 0x028
0000 0010 1000 0000 0010 0000 1000 0011 = 0x02802083
```

## Memory layout
```
@00 0x00 00000002
@01 0x04 02802083  lw x1, 0x28(x0)
@02 0x08 00100073  ebreak
@03 0x0C 00000006  
@04 0x10 00000008  
@05 0x14 0000000A  
@06 0x18 00000000  
@07 0x1C 00000000  
@08 0x20 00000000  
@09 0x24 00000000  
@0A 0x28 DEADBEEF  data to load
...             
@10 0x40 00000004  Reset vector
@11 0x44 00000000
```

# IType_lb_1 lowest byte
Load lowest byte (aka byte 1) and interpret as signed
from word-address **0x0000000A**. Only **0xEF** is loaded.

rd = M[rs1+imm][0:7]

```
0xEF is a negative number = One filled.
    rd   imm  rs1   
lb x1,   0x28(x0),   (0x0A)*4 + 0 = 0x28 + 0b00

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101000   00000   000     00001    0000011
      |
      \----- = 0x028
0000 0010 1000 0000 0000 0000 1000 0011 = 0x02800083
```

## Memory layout
```
@00 0x00 00000002
@01 0x04 02800083  lb x1, 0x28(x0)
@02 0x08 00100073  ebreak
@03 0x0C 00000006  
@04 0x10 00000008  
@05 0x14 0000000A  
@06 0x18 00000000  
@07 0x1C 00000000  
@08 0x20 00000000  
@09 0x24 00000000  
@0A 0x28 DEADBEEF  data to load
...           
@10 0x40 00000004  Reset vector
@11 0x44 00000000
```

# IType_lb_2
Load byte 2 and interpret as signed
from word-address **0x0000000A**. Only **0xBE** is loaded.

rd = M[rs1+imm][0:7]

```
0xBE is a negative number thus signed extended with 1's.
    rd   rs1   imm
lb x19,  x0,   (0x0A)*4 + 1 = 0x28 + 0b01

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101001   00000   000     10011    0000011
      |
      \----- = 0x029
0000 0010 1001 0000 0000 1001 1000 0011 = 0x02900983
```

## Memory layout
```
@0 00000002
@1 02900983     <-- instruction under test ----.
@2 00100073  ebreak                            |
@3 00000006                                    |
@4 00000008                                    |
@5 0000000A                                    |
@6 00000000                                    |
@7 00000000                                    |
@8 00000000                                    |
@9 00000000                                    |
@A DEADBEEF     <-- data to load               |
...                                            |
@10 00000004    <-- Reset vector pointing to --/
@11 00000000
```

# IType_lb_3
Load byte 3 and interpret as signed
from word-address **0x0000000A**. Only **0xAD** is loaded.

rd = M[rs1+imm][0:7]

```
0xBE is a negative number thus signed extended with 1's.
    rd   rs1   imm
lb x19,  x0,   (0x0A)*4 + 2 = 0x28 + 0b10

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101010   00000   000     10011    0000011
      |
      \----- = 0x02A
0000 0010 1010 0000 0000 1001 1000 0011 = 0x02A00983
```

## Memory layout
```
@0 00000002
@1 02A00983     <-- instruction under test ----.
@2 00100073  ebreak                            |
@3 00000006                                    |
@4 00000008                                    |
@5 0000000A                                    |
@6 00000000                                    |
@7 00000000                                    |
@8 00000000                                    |
@9 00000000                                    |
@A DEADBEEF     <-- data to load               |
...                                            |
@10 00000004    <-- Reset vector pointing to --/
@11 00000000
```

# IType_lb_4
Load byte 4 and interpret as signed
from word-address **0x0000000A**. Only **0xDE** is loaded.

rd = M[rs1+imm][0:7]

```
0xBE is a negative number thus signed extended with 1's.
    rd   rs1   imm
lb x19,  x0,   (0x0A)*4 + 3 = 0x28 + 0b11

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101011   00000   000     10011    0000011
      |
      \----- = 0x02B
0000 0010 1011 0000 0000 1001 1000 0011 = 0x02B00983
```

## Memory layout
```
@0 00000002
@1 02B00983     <-- instruction under test ----.
@2 00100073  ebreak                            |
@3 00000006                                    |
@4 00000008                                    |
@5 0000000A                                    |
@6 00000000                                    |
@7 00000000                                    |
@8 00000000                                    |
@9 00000000                                    |
@A DEADBEEF     <-- data to load               |
...                                            |
@10 00000004    <-- Reset vector pointing to --/
@11 00000000
```

# IType_lh_1
Load half-word 1 and interpret as signed
from word-address **0x0000000A**. Only **0xBEEF** is loaded.

rd = M[rs1+imm][0:15]

```
0xBEEF is a negative number thus signed extended with 1's.
    rd   rs1   imm
lh x19,  x0,   (0x0A)*4 + 0 = 0x28 + 0b00

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101000   00000   001     10011    0000011
      |
      \----- = 0x028
0000 0010 1000 0000 0001 1001 1000 0011 = 0x02801983
```

## Memory layout
```
@0 00000002
@1 02801983     <-- instruction under test ----.
@2 00100073  ebreak                            |
@3 00000006                                    |
@4 00000008                                    |
@5 0000000A                                    |
@6 00000000                                    |
@7 00000000                                    |
@8 00000000                                    |
@9 00000000                                    |
@A DEADBEEF     <-- data to load               |
...                                            |
@10 00000004    <-- Reset vector pointing to --/
@11 00000000
```

# IType_lh_2
Load half-word 2 and interpret as signed
from word-address **0x0000000A**. Only **0xDEAD** is loaded.

rd = M[rs1+imm][0:15]

```
0xDEAD is a negative number thus signed extended with 1's.
    rd   rs1   imm
lh x19,  x0,   (0x0A)*4 + 2 = 0x28 + 0b10

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101010   00000   001     10011    0000011
      |
      \----- = 0x02A
0000 0010 1010 0000 0001 1001 1000 0011 = 0x02A01983
```

## Memory layout
```
@0 00000002
@1 02A01983     <-- instruction under test ----.
@2 00100073  ebreak                            |
@3 00000006                                    |
@4 00000008                                    |
@5 0000000A                                    |
@6 00000000                                    |
@7 00000000                                    |
@8 00000000                                    |
@9 00000000                                    |
@A DEADBEEF     <-- data to load               |
...                                            |
@10 00000004    <-- Reset vector pointing to --/
@11 00000000
```

# IType_lb_p
Load byte 1 and interpret as signed
from word-address **0x0000000A**. Only **0x42** is loaded.

rd = M[rs1+imm][0:7]

```
0x42 is a positive number thus signed extended with 0's.
    rd   rs1   imm
lb x19,  x0,   (0x0A)*4 + 0 = 0x28 + 0b00

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101000   00000   000     10011    0000011
      |
      \----- = 0x028
0000 0010 1000 0000 0000 1001 1000 0011 = 0x02800983
```

## Memory layout
```
@0 00000002
@1 02800983     <-- instruction under test ----.
@2 00100073  ebreak                            |
@3 00000006                                    |
@4 00000008                                    |
@5 0000000A                                    |
@6 00000000                                    |
@7 00000000                                    |
@8 00000000                                    |
@9 00000000                                    |
@A 00000042     <-- data to load               |
...                                            |
@10 00000004    <-- Reset vector pointing to --/
@11 00000000
```
