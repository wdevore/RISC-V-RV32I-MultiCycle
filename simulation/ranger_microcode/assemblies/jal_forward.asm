// Jump forward

Main: @
    jal x0, @Jumpto
    ebreak              // We shouldn't return here

Jumpto: @
    lw x5, @Data(x0)      // path taken
    ebreak

Data: $028
    d: 00000A0A     // data for x5
    d: 00000B0B     // data for x5

RVector: @0C0
    @: Main             // Reset vector
