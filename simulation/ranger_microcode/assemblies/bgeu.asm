// Note:
// 
// x1 = 0xFFFFFFFE
// 
// x2 = 5
// 
// Flags: -N--     FE >= 5  <-- C=0
// 
// offset = 3*4 = 12 = 0x0C

Main: @
    lw x1, @Data(x0)
    lw x2, @Data+1(x0)
    bgeu x1, x2, @Offset    // branch taken
    lw x5, @Data+3(x0)      // path not taken
    ebreak

Offset: @
    lw x5, @Data+2(x0)      // path taken
    ebreak

Data: $028
    d: FFFFFFFE     // data for x1
    d: 00000005     // data for x2
    d: 00000A0A     // data for x5
    d: 00000B0B     // data for x5

RVector: @0C0
    @: Main             // Reset vector
