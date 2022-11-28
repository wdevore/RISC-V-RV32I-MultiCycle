// Jump and return

Main: @
    jal x1, @Jumpto
    lw x5, @Data+1(x0)  // return here
    ebreak              // We shouldn't return here

Jumpto: @
    lw x5, @Data(x0)    // path taken
    jalr x0, 0x0(x1)    // x1 has the return address
    ebreak

Data: $028
    d: 00000A0A     // data for x5
    d: 00000B0B     // data for x5

RVector: @0C0
    @: Main             // Reset vector
