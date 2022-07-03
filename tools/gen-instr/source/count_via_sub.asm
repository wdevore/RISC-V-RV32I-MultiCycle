// Count up via a subroutine

Main: @000
    lw  x4, @Data+5(x0)  // set base
    lbu x1, 0(x4)      // Count up to N
    lbu x2, 1(x4)      // Inc by M
    lbu x3, 2(x4)      // Starting count value
Cnt: @
    jal x5, @IncSub    // Call subroutine
    blt x3, x1, @Cnt   // Check and loop
    ebreak             // Halt
IncSub: @
    add  x3, x3, x2    // x3 += M
    jalr x0, 0x0(x5)   // return
Data: @
    d: 00020105           // (2)Start count:(1)Inc by M:(0)up to N
    @: Data            // address of data section
RVector: @0C0
    @: Main            // Reset vector
