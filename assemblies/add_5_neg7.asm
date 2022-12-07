// Add 5 + -7 = -2 = 0xFE
// Flags: -N--

Main: @
    lb x1, 0x28(x0)     // Load x1 = 0x05
    lb x2, 0x29(x0)     // Load x1 = 0xF9
    add x3, x1, x2
    ebreak              // Stop

Data: @00A
    d: 0000F905         // data to load

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector
