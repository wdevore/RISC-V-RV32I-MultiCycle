// Shift a bit left and right like a Cylon.

Main: @
    lw x4, @Data+4(x0)  // set base of data
    lb x2, 0(x4)        // Shift by N
    lb x3, 4(x4)        // Start pattern
    lb x1, 4(x4)        // Right pattern
    lw x5, 8(x4)        // Left pattern
    lw x6, @Data+3(x0)  // Load IO base

SftL: @
    sll x3, x3, x2      // shift left by x2 amount
    sb x3, 0x0(x6)      // Write to IO port. Causes io_wr to assert
    bne x3, x5, @SftL   // branch if x3 != x5

SftR: @
    srl x3, x3, x2      // shift right by x2 amount
    sb x3, 0x0(x6)      // Write to IO port. Causes io_wr to assert
    bne x3, x1, @SftR   // branch if x3 != x5
    jal x0, @SftL
    ebreak              // unreachable

Data: @010          // Data
    d: 00000001     // shift by 1
    d: 00000001     // right pattern --00_0001
    d: 00000020     // left pattern  --10_0000
    d: 00000800     // Base address of IO
    @: Data         // address of data section, WA 0x010 = BW 0x040

RVector: @0C0
    @: Main             // Reset vector
