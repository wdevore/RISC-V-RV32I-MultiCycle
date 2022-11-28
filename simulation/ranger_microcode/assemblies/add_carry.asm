// Add 0x7FFFFFFF + 1
// Flags: VN--

Main: @
    lw x1, @Data(x0)
    lw x2, @Data+1(x0)
    add x3, x1, x2
    ebreak

Data: $028
    d: FFFFFFFF         // data for x1
    d: 00000001         // data for x2

RVector: @0C0
    @: Main             // Reset vector

