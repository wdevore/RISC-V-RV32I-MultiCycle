# IType-e

Control and status registers
Formats:
         csrrw rd, csr, rs1

## csrrw1.ram

```
x9 is preloaded 32'h00000101
mstatus is preloaded 32'h000_000A
x2 is loaded with mstatus

@00 0x00 00000002
@01 0x04 30049173  csrrw x2, mstatus, x9
@02 0x08 00100073  ebreak
@03 0x0C 00000000
@04 0x10 00000000
@05 0x14 00000000
@06 0x18 00000000
@07 0x1C 00000000
@08 0x20 00000000
@09 0x24 00000000
@0A 0x28 00000000
...        
@10 0x40 00000004
@11 0x44 00000000
```

## csrrw2.ram

```
x9 is preloaded 32'h00000101
rd = x0 causes write side effects on CSR only
nothing else matters

@00 0x00 00000002
@01 0x04 30049073  csrrw x0, mstatus, x9
@02 0x08 00100073  ebreak
@03 0x0C 00000000
@04 0x10 00000000
@05 0x14 00000000
@06 0x18 00000000
@07 0x1C 00000000
@08 0x20 00000000
@09 0x24 00000000
@0A 0x28 00000000
...        
@10 0x40 00000004
@11 0x44 00000000
```

## csrrs0.ram
Only a read of CSR is performed and the
results is tossed away.

```
rs1 = x0
x2 is just for completeness it is not affected.

@00 0x00 00000002  
@01 0x04 30002173  csrrs x2, mstatus, x0
@02 0x08 00100073  ebreak
@03 0x0C 00000000
@04 0x10 00000000
@05 0x14 00000000
@06 0x18 00000000
@07 0x1C 00000000
@08 0x20 00000000
@09 0x24 00000000
@0A 0x28 00000000
...        
@10 0x40 00000004
@11 0x44 00000000
```

## csrrs1.ram
Set bits 1 and 3.

```
x9 is loaded 32'h00000005
mstatus is pre initialized to 32'h0000_000A
x2 is loaded with whatever mstatus was

@00 0x00 00000002  
@01 0x04 02802483  lw x9, 0x28(x0)
@02 0x08 3004A173  csrrs x2, mstatus, x9
@03 0x0C 00100073  ebreak
@04 0x10 00000000
@05 0x14 00000000
@06 0x18 00000000
@07 0x1C 00000000
@08 0x20 00000000
@09 0x24 00000000
@0A 0x28 00000005
...        
@10 0x40 00000004
@11 0x44 00000000
```

## csrrc1.ram
clear bits 3 and 5.
0001_0100

```
x9 is loaded 32'h00000014
mie is preloaded 32'h0005_0055 = 0101_0101
                                 0001_0100
                                 0100_0001 = 41
x2 is loaded with whatever mie was

@00 0x00 00000002  
@01 0x04 02802483  lw x9, 0x28(x0)
@02 0x08 3044B173  csrrc x2, mie, x9
@03 0x0C 00100073  ebreak
@04 0x10 00000000
@05 0x14 00000000
@06 0x18 00000000
@07 0x1C 00000000
@08 0x20 00000000
@09 0x24 00000000
@0A 0x28 00000014  0001_0100 clear bits
...        
@10 0x40 00000004
@11 0x44 00000000
```

## csrrc2.ram
no bits are cleared. Only a CSR read side effect

```
x0 will cause only a read side effect on the CSR
mie is preloaded 32'h0005_0055

@00 0x00 00000002  
@01 0x04 02802483  lw x9, 0x28(x0)
@02 0x08 30403173  csrrc x2, mie, x0
@03 0x0C 00100073  ebreak
@04 0x10 00000000
@05 0x14 00000000
@06 0x18 00000000
@07 0x1C 00000000
@08 0x20 00000000
@09 0x24 00000000
@0A 0x28 00000000  no clear bits
...        
@10 0x40 00000004
@11 0x44 00000000
```

Formats:
    csrrwi rd, csr, zimm[4:0]

## csrrwi1.ram
Write immediate

```
mie is preloaded 32'h0005_0055
x2 is loaded with whatever mie was

@00 0x00 00000002  
@01 0x04 3042D173  csrrwi x2, mie, 0x05
@02 0x08 00100073  ebreak
@03 0x0C 00000000
@04 0x10 00000000
@05 0x14 00000000
@06 0x18 00000000
@07 0x1C 00000000
@08 0x20 00000000
@09 0x24 00000000
@0A 0x28 00000000
...        
@10 0x40 00000004
@11 0x44 00000000
```

## csrrsi1.ram
Write immediate

```
mie is preloaded 32'h0005_0055
mie = 32'h0005_0057 after instruction executes
x2 is loaded with whatever mie was

@00 0x00 00000002  
@01 0x04 30416173  csrrsi x2, mie, 0x02
@02 0x08 00100073  ebreak
@03 0x0C 00000000
@04 0x10 00000000
@05 0x14 00000000
@06 0x18 00000000
@07 0x1C 00000000
@08 0x20 00000000
@09 0x24 00000000
@0A 0x28 00000000
...        
@10 0x40 00000004
@11 0x44 00000000
```

## csrrci1.ram
Write immediate

```
mie is preloaded 32'h0005_0055
mie = 32'h0005_0054 after instruction executes
x2 is loaded with whatever mie was

@00 0x00 00000002  
@01 0x04 3040F173  csrrci x2, mie, 0x01
@02 0x08 00100073  ebreak
@03 0x0C 00000000
@04 0x10 00000000
@05 0x14 00000000
@06 0x18 00000000
@07 0x1C 00000000
@08 0x20 00000000
@09 0x24 00000000
@0A 0x28 00000000
...        
@10 0x40 00000004
@11 0x44 00000000
```

