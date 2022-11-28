// Note:
// 
// if considered signed then x1 > x2
// if considered unsigned then x1 < x2
// 
// x1 = 5
// 
// x2 = 0xFFFFFFFE
// 
// Flags: --C-     5 < FE   = true for unsigned
// 
// Flags: -N--     FE < 5   = true for signed

Main: @
    lw x1, @Data(x0)
    lw x2, @Data+1(x0)
    bltu x1, x2, @Offset    // branch taken
    lw x5, @Data+3(x0)      // path not taken
    ebreak

Offset: @
    lw x5, @Data+2(x0)      // path taken
    ebreak

Data: $028
    d: 00000005     // data for x1
    d: FFFFFFFE     // data for x2
    d: 00000A0A     // data for x5
    d: 00000B0B     // data for x5

RVector: @0C0
    @: Main             // Reset vector
