// low half-word
// Load lowest half word as signed
// from word-address **0x0000000A**. Only **0xBEEF** is loaded.

// rd = M[rs1+imm][0:7]

// Load x1 with DEADBEEF

Main: @
    lh x1, 0x28(x0)     // Load x1 = 0xBEEF
    ebreak              // Stop

Data: @00A
    d: DEADBEEF         // data to load

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector
