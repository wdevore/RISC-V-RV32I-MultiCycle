// Count down to 0

Main: @
    lw x4, @Data+3(x0)  // set base
    lb x1, 0(x4)        // Count down to 0
    lb x2, 4(x4)        // Dec by N
    lb x3, 8(x4)        // Counter

Dec: @
    sub x3, x3, x2      // x3 -= 1
    bne x3, x1, @Dec    // branch if x3 != x1
    ebreak

Data: @00A
    d: 00000000  // min count
    d: 00000001  // dec by 1
    d: 00000005  // counter starts at 5
    @: Data      // address of data section

RVector: @0C0
    @: Main             // Reset vector
