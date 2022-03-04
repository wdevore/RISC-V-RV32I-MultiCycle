## signed conditions:

- jl (aka RISC-V **blt**) : Jump if less (SF≠ OF). That's output signbit not-equal to Overflow Flag, from a subtract / cmp
- jle : Jump if less or equal (ZF=1 or SF≠ OF).
- jge (aka RISC-V **bge**) : Jump if greater or equal (SF=OF).
- jg (aka RISC-V **bgt**) : Jump short if greater (ZF=0 and SF=OF).
If you decide to have your ALU just produce a "signed-less-than" output instead of separate SF and OF outputs, that's fine. SF==OF is just !(SF != OF).

## unsigned:

- jb (aka RISC-V **bltu**) : Jump if below (CF=1). That's just testing the carry flag.
- jae (aka RISC-V **bgeu**) : Jump short if above or equal (CF=0).
- ja (aka RISC-V **bgtu**) : Jump short if above (CF=0 and ZF=0).

```
--------------------------------------------
All operands are consider Signed or Unsigned in this suite
--------------------------------------------
```

# RType_cmp_beq
NOTE: this test only checks the flags. There is a separate test for the actual *beq* instruction. bne is simply the opposite.

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

# RType_cmp_blt
NOTE: this test only checks the flags. There is a separate test for the actual *blt* instruction.

If 5 < 7 then N != V

rs1 < rs2 = **true**. Check if N!=V
```
    x1  x2
Sub 5 - 7       x1 - x2

Flags: -NC-    <== N!=V

If the two operands are considered signed then N!=V is interpreted as "5 is less than 7"

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

x3 should = 0x00000000
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
@C 00000007     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_cmp_bge
NOTE: this test only checks the flags. There is a separate test for the actual *blt* instruction.

rs1 >= rs2 = **true**.
```
    rs1 rs2
    x1  x2
Sub 7 - 5

Flags: ----    <== N=V  both are not-set thus equal

If the two operands are considered signed then N=V is interpreted as "7 is greater than 5".

If the two operands are considered unsigned, "bgeu", then we interpret C=0 as "7 is greater than 5".


x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

x3 should = 0x00000000
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
@A 00000007     <-- data for x1
@B 00000000
@C 00000005     <-- data for x2
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_cmp_blt_2
NOTE: this test only checks the flags. There is a separate test for the actual *blt* instruction.

If -2 < 3 then N != V

rs1 < rs2 = **true**. Check if N!=V
```
    x1  x2
Sub -2 - 3       x1 - x2    0xFFFFFFFB = -5

Flags: -N--    <== N!=V

If the two operands are considered signed then N!=V is interpreted as "-2 is less than 3"

If the two operands are considered unsigned, "bltu", then we interpret C=0 as "FFFFFFFE is greater than 3".

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

x3 should = 0x00000000
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
@A FFFFFFFE     <-- data for x1    -2
@B 00000000
@C 00000003     <-- data for x2     3
...
@10 00000004    <-- Reset vector
@11 00000000
```

# RType_cmp_blt_3
NOTE: this test only checks the flags. There is a separate test for the actual *blt* instruction.

If 3 < -2 then N = V

rs1 < rs2 = **false**. Check if N=V
```
    x1  x2
Sub 3 - (-2)       x1 - x2    0x00000005

Flags: --C-     3 < FE
Flags: -N--     FE < 3

If the two operands are considered signed then N=V is interpreted as "3 is NOT less than -2" or "3 is greater than -2"

If the two operands are considered unsigned, "bltu", then we interpret C=0 as "3 is less than FFFFFFFE" or rs1 < rs2

x4 = base = WA:0x0A, BA:0x28  <-- preloaded via initial block

x3 should = 0x00000000
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
@A 00000003     <-- data for x1    3
@B 00000000
@C FFFFFFFE     <-- data for x2   -2
...
@10 00000004    <-- Reset vector
@11 00000000
```
