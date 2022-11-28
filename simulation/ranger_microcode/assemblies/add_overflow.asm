// Add 0xFFFFFFFF + 1
// Flags: -N--

// For the Overflow flag "V" to set you would need to activate the overflow
// feature of the ALU. It is disabled by default.

Main: @
    lw x1, @Data(x0)
    lw x2, @Data+1(x0)
    add x3, x1, x2
    ebreak

Data: $028
    d: 7FFFFFFF         // data for x1
    d: 7FFFFFFF         // data for x2

RVector: @0C0
    @: Main             // Reset vector
