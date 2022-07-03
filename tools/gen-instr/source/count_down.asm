// Count down to zero

Main: @000
    lw x4, @Data+5(x0)   // set base
    lb x1, 0(x4)      // Count down to 0
    lb x2, 1(x4)      // Dec by N
    lb x3, 2(x4)      // Counter
    
Dec: @
    sub x3, x3, x2    // x3 -= 1
    bne x3, x1, @Dec  // branch if x3 != x1
    ebreak            // Stop
  
Data: @00A
    d: 00000000  // min count
    d: 00000001  // dec by 1
    d: 00000005  // counter starts at 5
    d: 00000000
    d: 00000000
    @: Data      // address of data section
    @: Main      // Reset vector
