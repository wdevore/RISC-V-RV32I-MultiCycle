// Note: any byte can be targeted by adding 0-3 to offset of base register.
// byte 2
// Load lowest byte (aka byte 2) and interpret as signed
// from word-address **0x0000000A**. Only **0xBE** is loaded.

// rd = M[rs1+imm][0:7]

// Load x1 with DEADBEEF

Main: @
    lb x1, 0x29(x0)     // Load x1 = 0xEF
    ebreak              // Stop

Data: @00A
    d: DEADBEEF         // data to load

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector

