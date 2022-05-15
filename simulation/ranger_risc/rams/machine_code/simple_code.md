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

## Left_right

## Memory layout
```
    @00 0x00  00000002
    @01 0x04  06802203  lw x4, 0x68(x0)   // set base
    @02 0x08  00020103  lb x2, 0(x4)      // Shift by N
    @03 0x0C  00420183  lb x3, 4(x4)      // Start pattern
    @04 0x10  00420083  lb x1, 4(x4)      // Right pattern
    @05 0x14  00822283  lw x5, 8(x4)      // Left pattern
SftL:
    @06 0x18  002191B3  sll x3, x3, x2    // shift left by x2 amount
    @07 0x1C  FE519EE3  bne x3, x5, SftL  // branch if x3 != x5
SftR:
    @08 0x20  0021D1B3  srl x3, x3, x2    // shift right by x2 amount
    @09 0x24  FE119EE3  bne x3, x1, SftR  // branch if x3 != x5
    @0A 0x28  FF1FF06F  jal x0, SftL
    @0B 0x2C  00100073  ebreak            // unreachable
    @0C 0x30  00000000
    @0D 0x34  00000000
    @0E 0x38  00000000
    @0F 0x3C  00000000
    @10 0x40  00000000
    @11 0x44  00000000
    @12 0x48  00000000
    @13 0x4C  00000000
    @14 0x50  00000000
Data: 
    @15 0x54  00000001  shift by 1
    @16 0x58  00000001  right pattern
    @17 0x5C  80000000  left pattern
    @18 0x60  00000000
    @19 0x64  00000000
    @1A 0x68  00000054  address of data section
    @1B 0x6C  00000004  Reset vector
```

## Left-right-comp
Uses byte compacted memory.
Big-endian demonstration

## Memory layout
```
    @00 0x00  00000002
    @01 0x04  06802203  lw  x4, 0x68(x0)  // set base
    @02 0x08  00020103  lb  x2, 0(x4)     // Shift by N
    @03 0x0C  00120183  lb  x3, 1(x4)     // Start pattern
    @04 0x10  00120083  lb  x1, 1(x4)     // Right pattern
    @05 0x14  00224283  lbu x5, 2(x4)     // Left pattern
SftL:
    @06 0x18  002191B3  sll x3, x3, x2    // shift left by x2 amount
    @07 0x1C  FE519EE3  bne x3, x5, SftL  // branch if x3 != x5
SftR:
    @08 0x20  0021D1B3  srl x3, x3, x2    // shift right by x2 amount
    @09 0x24  FE119EE3  bne x3, x1, SftR  // branch if x3 != x5
    @0A 0x28  FF1FF06F  jal x0, SftL
    @0B 0x2C  00100073  ebreak            // unreachable
    @0C 0x30  00000000
    @0D 0x34  00000000
    @0E 0x38  00000000
    @0F 0x3C  00000000
    @10 0x40  00000000
    @11 0x44  00000000
    @12 0x48  00000000
    @13 0x4C  00000000
    @14 0x50  00000000
Data: 
    @15 0x54  00800101  left : right pattern : shift by 1
    @16 0x58  00000000
    @17 0x5C  00000000
    @18 0x60  00000000
    @19 0x64  00000000
    @1A 0x68  00000054  address of data section
    @1B 0x6C  00000004  Reset vector
```

## sub_routine
Count to 5 via a subroutine

## Memory layout
```
    @00 0x00  00000002
    @01 0x04  06802203  lw  x4, 0x68(x0)  // set base
    @02 0x08  00024083  lbu x1, 0(x4)     // Count up to N
    @03 0x0C  00124103  lbu x2, 1(x4)     // Inc by M
    @04 0x10  00224183  lbu x3, 2(x4)     // Starting count value
Cnt:
    @05 0x14  030002EF  jal x5, IncSub    // Call subroutine
    @06 0x18  FE11CEE3  blt x3, x1, Cnt   // Check and loop
    @07 0x1C  00100073  ebreak            // Halt
    @08 0x20  00000000
    @09 0x24  00000000
    @0A 0x28  00000000
    @0B 0x2C  00000000
    @0C 0x30  00000000
    @0D 0x34  00000000
    @0E 0x38  00000000
    @0F 0x3C  00000000
    @10 0x40  00000000
IncSub:
    @11 0x44  002181B3  add  x3, x3, x2   // x3 += M
    @12 0x48  00028067  jalr x0, x5, Zero // return
    @13 0x4C  00000000
    @14 0x50  00000000
Data: 
    @15 0x54  00020105  (2)Start count:(1)Inc by M:(0)up to N
    @16 0x58  00000000
    @17 0x5C  00000000
    @18 0x60  00000000
    @19 0x64  00000000
    @1A 0x68  00000054  address of data section
    @1B 0x6C  00000004  Reset vector
```

## Count via memory location
mem_count.ram

## Memory layout
```
    @00 0x00  00000002
    @01 0x04  06802203  lw  x4, 0x68(x0)  // set base
    @02 0x08  00024083  lbu x1, 0(x4)     // Count up to N
    @03 0x0C  00124103  lbu x2, 1(x4)     // Inc by M
    @04 0x10  00224183  lbu x3, 2(x4)     // Starting count value
Cnt:
    @05 0x14  030002EF  jal x5, IncStr    // Call subroutine
    @06 0x18  00422303  lw  x6, 4(x4)     // Get current value
    @07 0x1C  FE134CE3  blt x6, x1, Cnt   // Check and loop
    @08 0x20  00100073  ebreak            // Halt
    @09 0x24  00000000
    @0A 0x28  00000000
    @0B 0x2C  00000000
    @0C 0x30  00000000
    @0D 0x34  00000000
    @0E 0x38  00000000
    @0F 0x3C  00000000
    @10 0x40  00000000
IncStr:
    @11 0x44  002181B3  add  x3, x3, x2   // x3 += M
    @12 0x48  00322223  sw   x3, 4(x4)    // Store new value
    @13 0x4C  00028067  jalr x0, x5, Zero // return
    @14 0x50  00000000
Data: 
    @15 0x54  00010104  (2)Start count:(1)Inc by M:(0)up to N
    @16 0x58  00000000  Count
    @17 0x5C  00000000
    @18 0x60  00000000
    @19 0x64  00000000
    @1A 0x68  00000054  address of data section
    @1B 0x6C  00000004  Reset vector
```

## Compare two strings
str.ram

42454546 = 0x0287CE12 = BEEF
46414345 = 0x02C43A09 = FACE
D = 44

## Memory layout
```
    @00 0x00  00000002
    @01 0x04  06802203  lw x4, 0x68(x0)    // Point to Data section
    @02 0x08  00400113  addi x2, x0, 4     // x2 = string length
    @03 0x0C  00020193  addi x3, x4, 0     // x3 -> 1st string
    @04 0x10  00420213  addi x4, x4, 4     // x4 -> 2nd string
    @05 0x14  00000293  addi x5, x0, 0     // x5 = 0 = counter
Next:
    @06 0x18  00018303  lb x6, 0(x3)       // x6 = byte to check
    @07 0x1C  00020383  lb x7, 0(x4)       // x7 = byte to check
    @08 0x20  00118193  addi x3, x3, 1     // x3++ next byte
    @09 0x24  00120213  addi x4, x4, 1     // x4++ next byte
    @0A 0x28  00731E63  bne x6, x7, NoEq
    @0B 0x2C  00128293  addi x5, x5, 1     // x5++
    @0C 0x30  FE22C4E3  blt x5, x2, Next
    @0D 0x34  00100493  addi x9, x0, 1     // 1 = equals
    @0E 0x38  00100073  ebreak             // Halt
    @0F 0x3C  00000000
    @10 0x40  00000004  Reset vector
NoEq:
    @11 0x44  00200493  addi x9, x0, 2     // 2 !=
    @12 0x48  00100073  ebreak             // Halt
    @13 0x4C  00000000  
    @14 0x50  00000000
Data: 
    @15 0x54  42454546  BEEF
    @16 0x58  44454546  DEEF
    @17 0x5C  00000000
    @18 0x60  00000000
    @19 0x64  00000000
    @1A 0x68  00000054  address of data section
    @1B 0x6C  00000000  
```

## Fibonacci
fibo.ram

0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144
   x1 x2

loop
    x3 = x1 + x2
    x1 = x2
    x2 = x3
    br loop

## Memory layout
```
    @00 0x00  00000002
    @01 0x04  000000B3  add x1, x0, x0      // 0
    @02 0x08  00100113  addi x2, x0, 1      // 1
    @03 0x0C  00A00213  addi x4, x0, 0xa    // x4 = 10
    @04 0x10  000002B3  add x5, x0, x0      // x5 = 0
Next:
    @05 0x14  002081B3  add x3, x1, x2
    @06 0x18  000100B3  add x1, x2, x0      // x1 = x2
    @07 0x1C  00018133  add x2, x3, x0      // x2 = x3
    @08 0x20  00128293  addi x5, x5, 1      // x5++
    @09 0x24  FE42C8E3  blt x5, x4, Next
    @0A 0x28  00100073  ebreak              // Halt
    @0B 0x2C  00000000  
    @0C 0x30  00000000  
    @0D 0x34  00000000  
    @0E 0x38  00000000  
    @0F 0x3C  00000000
    @10 0x40  00000004  Reset vector
    @11 0x44  00000000  
```
