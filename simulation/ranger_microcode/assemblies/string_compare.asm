// Compare two strings

Main: @
    lw x4, @Data+2(x0)  // set base of data
    addi x2, x0, 4     // x2 = string length
    addi x3, x4, 0     // x3 -> 1st string
    addi x4, x4, 4     // x4 -> 2nd string
    addi x5, x0, 0     // x5 = 0 = counter
    addi x9, x0, 0     // x9 = 0

Next: @
    lb x6, 0(x3)       // x6 = byte to check
    lb x7, 0(x4)       // x7 = byte to check
    addi x3, x3, 1     // x3++ next byte
    addi x4, x4, 1     // x4++ next byte
    bne x6, x7, @NoEq
    addi x5, x5, 1      // x5++
    blt x5, x2, @Next
    addi x9, x0, 1      // 1 = equals
    ebreak              // Halt

NoEq: @
    addi x9, x0, 2     // 2 !=
    ebreak

Data: @012          // = 0x040 byte-address
    d: 42454546     // ascii text "BEEF"
    d: 42454546     // ascii text "BEEF"
    @: Data         // address of data section, WA 0x010 = BW 0x040

RVector: @0C0
    @: Main             // Reset vector
