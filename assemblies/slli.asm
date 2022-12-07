// rd = rs1<<imm
// 1010_0000_0000_0000_0000_0000_0000_1010
// 0100_0000_0000_0000_0000_0000_0001_0100 = 0x40000014

Main: @
    lw x1, 0x28(x0)     // Load x1 with the contents of: 0x28 BA = 0x0A WA
    slli x2, x1, 0x01
    ebreak              // Stop

Data: @00A              // Specified in word-address (WA) format
    d: A000000A         // data to load

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector
