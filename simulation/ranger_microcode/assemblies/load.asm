// Load x1 with DEADBEEF

Main: @
    lw x1, 0x28(x0)     // 0x28 BA = 0x0A WA
    ebreak              // Stop

Data: @00A
    d: DEADBEEF         // data to load

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector
