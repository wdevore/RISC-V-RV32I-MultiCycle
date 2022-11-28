// Jump forward

Main: @
    jal x0, @Jumpto

Backto: @
    lw x5, @Data+1(x0)  // This is executed afterward
    ebreak              // We shouldn't return here

Jumpto: @
    lw x5, @Data(x0)    // path taken
    jal x0, @Backto     // Jump backward
    ebreak

Data: $028
    d: 00000A0A     // data for x5
    d: 00000B0B     // data for x5

RVector: @0C0
    @: Main             // Reset vector
