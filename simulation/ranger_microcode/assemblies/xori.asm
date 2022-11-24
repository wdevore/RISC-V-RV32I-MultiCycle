// rd = rs1 ^ imm  = 0x0A ^ 0x05 = 0x0F

Main: @
    lw x1, 0x28(x0)     // Load x1 with the contents of: 0x28 BA = 0x0A WA
    xori x2, x1, 0x05
    ebreak              // Stop

Data: @00A              // Specified in word-address (WA) format
    d: 0000000A         // data to load

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector
