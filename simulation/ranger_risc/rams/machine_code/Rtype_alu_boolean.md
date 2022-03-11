## AND, OR, XOR


# RType_and

  8'b01100110  x1
& 8'b01110011  x2
-------------
     01100010  x3 = 0x62

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
     rd  rs1&rs2
and  x3, x1, x2

   func7   |  rs2  |  rs1  | funct3 |   rd  |  opcode
  0000000    00010   00001    111     00011    0110011 = 0x0020F1B3
  
```

## Memory layout
```
@0 00000002
@1 00020083   lb  x1, x4, 0
@2 00820103   lb  x2, x4, 8
@3 0020F1B3   and x3, x1, x2
@4 00100073   ebreak
@5 0000000A     
...
@A 00000066     <-- data for x1
@B 00000000
@C 00000073     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_or

  8'b01100110  x1
| 8'b01110011  x2
-------------
     01110111  x3 = 0x77

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
     rd  rs1&rs2
or  x3, x1, x2

   func7   |  rs2  |  rs1  | funct3 |   rd  |  opcode
  0000000    00010   00001    110     00011    0110011 = 0x0020E1B3
  
```

## Memory layout
```
@0 00000002
@1 00020083   lb  x1, x4, 0
@2 00820103   lb  x2, x4, 8
@3 0020E1B3   or x3, x1, x2
@4 00100073   ebreak
@5 0000000A     
...
@A 00000066     <-- data for x1
@B 00000000
@C 00000073     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_xor

  8'b01100110  x1
^ 8'b01110011  x2
-------------
     00010101  x3 = 0x15

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

```
     rd  rs1&rs2
or  x3, x1, x2

   func7   |  rs2  |  rs1  | funct3 |   rd  |  opcode
  0000000    00010   00001    100     00011    0110011 = 0x0020C1B3
  0000 0000 0010 0000 1100 0001 1011 0011
```

## Memory layout
```
@0 00000002
@1 00020083   lb  x1, x4, 0
@2 00820103   lb  x2, x4, 8
@3 0020C1B3   or x3, x1, x2
@4 00100073   ebreak
@5 0000000A     
...
@A 00000066     <-- data for x1
@B 00000000
@C 00000073     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```
