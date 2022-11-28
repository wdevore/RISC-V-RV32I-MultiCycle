Main: @
    lb x1, @Data(x0)     // Load x1 = 0xEF
    sb x1, @Data+1(x0)
    ebreak              // Stop

Data: @00A
    d: DEADBEEF         // data to load
    d: 00000000         // data stored here
RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector

