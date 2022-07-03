// Count up via a memory location

Main: @000
    lw x4, @Data+2(x0)    // Point to Data section
    addi x2, x0, 4     // x2 = string length
    addi x3, x4, 0     // x3 -> 1st string
    addi x4, x4, 4     // x4 -> 2nd string
    addi x5, x0, 0     // x5 = 0 = counter
Next: @
    lb x6, 0(x3)       // x6 = byte to check
    lb x7, 0(x4)       // x7 = byte to check
    addi x3, x3, 1     // x3++ next byte
    addi x4, x4, 1     // x4++ next byte
    bne x6, x7, @NoEq
    addi x5, x5, 1     // x5++
    blt x5, x2, @Next
    addi x9, x0, 1     // 1 = equals
    ebreak             // Halt
NoEq: @
    addi x9, x0, 2     // 2 !=
    ebreak             // Halt
Data: @
    d: 42454546        // BEEF
    d: 44454546        // DEEF
    @: Data            // address of data section
RVector: @0C0
    @: Main            // Reset vector
