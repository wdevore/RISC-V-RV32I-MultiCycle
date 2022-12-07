// 0x0A + 0xFE = 0x08

Main: @
    lw x4, 0x28(x0)     // Load x4 with the contents of: 0x28 BA = 0x0A WA
    addi x2, x4, -2     // x4 + 0xFE
    ebreak              // Stop

Data: $028              // Specified in byte-address (BA) format
    d: 0000000A         // data to load

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector
