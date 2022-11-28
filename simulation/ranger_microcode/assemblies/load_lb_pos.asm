// lowest byte
// Load lowest byte (aka byte 1) and interpret as signed
// from word-address **0x0000000A**. Only **0x42** is loaded.

// rd = M[rs1+imm][0:7]

// Load x1 with 0x00000042
// 42 is positive thus sign extended with zeros.

Main: @
    lb x1, 0x28(x0)     // Load x1 = 0xEF
    ebreak              // Stop

Data: @00A
    d: 00000042         // data to load

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector
