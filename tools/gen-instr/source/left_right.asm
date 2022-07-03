// Shift a 1 bit pattern left and right, like a cyclon

Main: @000
    lw x4, @Data+3(x0)   // set base
    lb x2, 0(x4)      // Shift by N
    lb x3, 4(x4)      // Start pattern
    lb x1, 4(x4)      // Right pattern
    lw x5, 8(x4)      // Left pattern
SftL: @
    sll x3, x3, x2     // shift left by x2 amount
    bne x3, x5, @SftL  // branch if x3 != x5
SftR: @
    srl x3, x3, x2     // shift right by x2 amount
    bne x3, x1, @SftR  // branch if x3 != x5
    jal x0, @SftL
    ebreak             // unreachable
Data: @
    d: 00000001  // shift by 1
    d: 00000001  // right pattern
    d: 80000000  // left pattern
    @: Data      // address of data section
RVector: @0C0
    @: Main      // Reset vector
