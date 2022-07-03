// Count up via a memory location

Main: @000
    lw  x4, @Data+2(x0)  // set base
    lbu x1, 0(x4)     // Count up to N
    lbu x2, 1(x4)     // Inc by M
    lbu x3, 2(x4)     // Starting count value
Cnt: @
    jal x5, @IncStr    // Call subroutine
    lw  x6, 4(x4)      // Get current value
    blt x6, x1, @Cnt   // Check and loop
    ebreak             // Halt
IncStr: @
    add  x3, x3, x2   // x3 += M
    sw   x3, 4(x4)    // Store new value
    jalr x0, 0x0(x5)  // return
Data: @
    d: 00010104        // (2)Start count:(1)Inc by M:(0)up to N
    d: 00000000        // Count
    @: Data            // address of data section
RVector: @0C0
    @: Main            // Reset vector
