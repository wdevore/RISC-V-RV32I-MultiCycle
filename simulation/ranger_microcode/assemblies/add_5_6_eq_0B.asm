// Add 5 + 6 = 11 = 0x0B = x3

Main: @
    lb x1, 0x28(x0)     // Load x1 = 0x05
    lb x2, 0x29(x0)     // Load x1 = 0x06
    add x3, x1, x2
    ebreak              // Stop

Data: @00A
    d: 00000605         // data to load

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector
