// Note: In order to specify a an offset by bytes or half words you need to
// use byte-format for loads.

Main: @
    lh x1, 0x28+2(x0)     // Load x1 = 0xBEEF
    sh x1, @Data+1(x0)
    ebreak              // Stop

Data: @00A
    d: DEADBEEF         // data to load
    d: 00000000         // data stored here
RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector

