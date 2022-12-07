Main: @
    lui x3, 0x0A0A5
    auipc x2, 0x0000DEAD
    ebreak              // Stop

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector

