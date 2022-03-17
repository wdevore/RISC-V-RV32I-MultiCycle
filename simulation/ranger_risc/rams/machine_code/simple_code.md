# Simple counters

## Count to 5

## Memory layout
```
    @00 0x00  00000002
    @01 0x04  03C02203  lw x4, 0x3C(x0)   // set base
    @02 0x08  00020083  lb x1, 0(x4)      // Count up to 5
    @03 0x0C  00420103  lb x2, 4(x4)      // Inc by N
    @04 0x10  00820183  lb x3, 8(x4)      // Counter
inc:
    @05 0x14  002181B3  add x3, x3, x2    // x3 += 1
    @06 0x18  FE11CEE3  blt x3, x1, inc
    @07 0x1C  00100073  ebreak            // Stop
    @08 0x20  00000000
    @09 0x24  00000000
data: 
    @0A 0x28  00000005  max count
    @0B 0x2C  00000001  inc by 1
    @0C 0x30  00000001  counter starts at 0
    @0D 0x34  00000000
    @0E 0x38  00000000
    @0F 0x3C  00000028  address of data section
    @10 0x40  00000004  Reset vector
    @11 0x44  00000000
```

## Count down to 0

## Memory layout
```
    @00 0x00  00000002
    @01 0x04  03C02203  lw x4, 0x3C(x0)   // set base
    @02 0x08  00020083  lb x1, 0(x4)      // Count down to 0
    @03 0x0C  00420103  lb x2, 4(x4)      // Dec by N
    @04 0x10  00820183  lb x3, 8(x4)      // Counter
dec:
    @05 0x14  402181B3  sub x3, x3, x2    // x3 -= 1
    @06 0x18  FE119EE3  bne x3, x1, dec   // branch if x3 != x1
    @07 0x1C  00100073  ebreak            // Stop
    @08 0x20  00000000
    @09 0x24  00000000
data: 
    @0A 0x28  00000000  min count
    @0B 0x2C  00000001  dec by 1
    @0C 0x30  00000005  counter starts at 5
    @0D 0x34  00000000
    @0E 0x38  00000000
    @0F 0x3C  00000028  address of data section
    @10 0x40  00000004  Reset vector
    @11 0x44  00000000
```

