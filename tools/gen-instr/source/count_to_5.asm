// Count to 5

Data0: @000
    d: 00000002

Main: @
    lw x4, @Data+5(x0)   // set base
    lb x1, 0(x4)      // Count up to 5
    lb x2, 1(x4)      // Inc by N
    lb x3, 2(x4)      // Counter

Inc: @
    add x3, x3, x2    // x3 += 1
    blt x3, x1, @Inc
    ebreak            // Stop

Data: @00A
    d: 00000005  // max count
    d: 00000001  // inc by 1
    d: 00000001  // counter starts at 1
    d: 00000000
    d: 00000000
    @: Data      // address of data section
    @: Main      // Reset vector
    d: 00000000
