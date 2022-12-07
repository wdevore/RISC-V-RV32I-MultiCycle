// rd = (rs1 < imm) ? 1:0  = 0x28 < -2 = false
// x2 = false = 0

Main: @
    lw x1, 0x28(x0)     // Load x1 with the contents of 0x0A WA
    slti x2, x1, -2
    ebreak              // Stop

Data: @00A              // Specified in word-address (WA) format
    d: 00000028         // data to load

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector
