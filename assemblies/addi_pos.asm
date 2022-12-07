// 0x0A + 0x0A = 0x14

Main: @
    lw x4, 0x28(x0)     // Load x4 with the contents of: 0x28 BA = 0x0A WA
    addi x2, x4, 0x0A   // x4 + 0x0A
    ebreak              // Stop

Data: @00A              // Specified in word-address (WA) format
    d: 0000000A         // data to load

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector
