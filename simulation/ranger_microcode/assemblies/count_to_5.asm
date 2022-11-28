// Count up to 5 using x3 register

Main: @
    lw x4, @Data+3(x0)  // set base
    addi x3, x0, 0x0    // Init counter to 0
    lb x1, 0x0(x4)      // Count up to 5
    lb x2, 0x4(x4)      // Inc by N

Inc: @
    add x3, x3, x2      // x3 += 1
    blt x3, x1, @Inc
    ebreak

Data: @00A
    d: 00000005  // max count
    d: 00000001  // inc by 1
    d: 00000001  // counter starts at 1
    d: 00000028  // address of data section

RVector: @0C0
    @: Main             // Reset vector
