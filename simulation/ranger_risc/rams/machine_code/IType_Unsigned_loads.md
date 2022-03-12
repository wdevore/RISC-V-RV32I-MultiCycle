# IType_lbu
Load lowest byte (aka byte 1) and interpret as un-signed
from word-address **0x0000000A**. Only **0xEF** is loaded.

rd = M[rs1+imm][0:7]

```
0xEF signed extended with 0's
    rd   rs1   imm
lbu x19,  x0,   (0x0A)*4 + 0 = 0x28 + 0b00

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101000   00000   100     10011    0000011
      |
      \----- = 0x028
0000 0010 1000 0000 0100 1001 1000 0011 = 0x02804983
```

## Memory layout
```
@0 00000002
@1 02804983     <-- instruction under test ----.
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

# IType_lhu_l
Load lower half-word and interpret as un-signed
from word-address **0x0000000A**. Only **0xBEEF** is loaded.

rd = M[rs1+imm][0:15]

```
0xDEAD signed extended with 0's
    rd   rs1   imm
lhu x19,  x0,   (0x0A)*4 + 0 = 0x28

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101000   00000   101     10011    0000011
      |
      \----- = 0x028
0000 0010 1000 0000 0101 1001 1000 0011 = 0x02805983
```

## Memory layout
```
@0 00000002
@1 02805983     <-- instruction under test ----.
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

# IType_lhu_h
Load high half-word and interpret as un-signed
from word-address **0x0000000A**. Only **0xDEAD** is loaded.

rd = M[rs1+imm][0:15]

```
0xDEAD signed extended with 0's
    rd   rs1   imm
lhu x19,  x0,   (0x0A)*4 + 0 = 0x28 + 0b10

   imm11:0   |  rs1 | funct3 |   rd  |  opcode
000000101100   00000   101     10011    0000011
      |
      \----- = 0x02A
0000 0010 1010 0000 0101 1001 1000 0011 = 0x02A05983
```

## Memory layout
```
@0 00000002
@1 02A05983     <-- instruction under test ----.
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