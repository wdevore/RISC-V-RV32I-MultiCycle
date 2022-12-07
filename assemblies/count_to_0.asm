// Count down to 0

Main: @
    lw x4, @Data+4(x0)  // set base
    lb x1, 0(x4)        // Count down to 0
    lb x2, 4(x4)        // Dec by N
    lb x3, 8(x4)        // Counter
    lw x5, @Data+3(x0)  // Load IO base

Dec: @
    sub x3, x3, x2      // x3 -= 1
    sb x3, 0x0(x5)      // Write to IO port. Causes io_wr to assert
    bne x3, x1, @Dec    // branch if x3 != x1
    ebreak

Data: @010
    d: 00000000  // min count
    d: 00000001  // dec by 1
    d: 00000005  // counter starts at 5
    d: 00000800  // Base address of IO
    @: Data      // address of data section

RVector: @0C0
    @: Main             // Reset vector
