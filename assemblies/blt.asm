// 4 < 5 = true = branch taken

Main: @
    lw x1, @Data(x0)
    lw x2, @Data+1(x0)
    blt x1, x2, @Offset
    lw x5, @Data+3(x0)      // path not taken
    ebreak

Offset: @
    lw x5, @Data+2(x0)      // path taken
    ebreak

Data: $028
    d: 00000004     // data for x1
    d: 00000005     // data for x2
    d: 00000A0A     // data for x5 branch taken
    d: 00000B0B     // data for x5 branch not taken

RVector: @0C0
    @: Main             // Reset vector
