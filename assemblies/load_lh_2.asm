// Load highest half word as signed
// from word-address **0x0000000A**. Only **0xDEAD** is loaded.

// rd = M[rs1+imm][0:7]

// Load x1 with DEADBEEF
// 0x28 + 0x02 = 0x2A

Main: @
    lh x1, 0x2A(x0)     // Load x1 = 0xDEAD
    ebreak              // Stop

Data: @00A
    d: DEADBEEF         // data to load

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector
