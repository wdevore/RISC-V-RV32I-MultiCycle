// Store 0x99 at 0x800 which is the first IO mapped register.
// 0x99 = 1001_1001
Main: @
    lbu x1, @Data(x0)       // Load x1 = 0x99
    lw x2, @Data+1(x0)      // Load IO base
    sb x1, 0x0(x2)          // Write to IO port. Causes io_wr to assert
    lw x2, @Data+2(x0)      // Load IO base
    sb x1, 0x0(x2)          // Write 0x99 to Memorys
    ebreak                  // Stop

Data: @00A
    d: 0000000A         // data to load
    d: 00000800         // Base address of IO
    d: 00000700         // Memory address
    @: Data             // Base address of data section

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector

