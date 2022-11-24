// Display 6 bits of x5 on Blade

Main: @000
    addi x5, x0, 0xAA       // Load x5 with 10101010
    addi x2, x0, 0x800      // Address of mapped blade register WA = 0x200*4 => 0x800 BA
    sb x5, 0x0(x2)          // Or 0x4c
    ebreak
Boot: @010
    jal x0, @Main
RVector: @0C0            // 0xC0 word address = 0x300 byte address (BA)
    @: Boot              // Address of Boot sequence
