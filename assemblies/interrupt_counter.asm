// Count by 1 each time an interrupt event occurs.

Main: @000
    addi x3, x0, 0          // Counter starts at 0
    addi x5, x0, 0          // Trap Counter starts at 0
    lw x6, @Data+3(x0)      // Load IO base
    addi x7, x0, 0x100      // x7 <== 0x100 = max count
    lw x1, 0x8(x4)          // Enable Global interrupts
    csrrs x0, mstatus, x1

Loop: @
    addi x3, x3, 1      // x3 += 1
    sb x5, 0x0(x6)      // Write to Blade
    sb x3, 0x1(x6)      // Write to 7seg
    blt x3, x7, @Loop
    addi x3, x0, 0x0    // Clear x3
    jal x0, @Loop
    ebreak

Boot: @020
    lw x4, @Data+4(x0)      // init x4 to point to @Data
    lw x1, 0x8(x4)          // Disable Global interrupts
    csrrc x0, mstatus, x1
    lw x1, 0x0(x4)          // load x1 with Trap addr
    csrrw x0, mtvec, x1     // Store in mtvec
    lw x1, 0x4(x4)          // x1 = mask, Enable M-mode Mie.MEIE 
    csrrs x0, mie, x1       // Set bit using mask
    jal x0, @Main           // Jump to program *Start*

Trap: @030                    // Trap handler
    // Each time our Trap is called we inc x5
    addi x5, x5, 1      // x5 += 1
    mret
    ebreak            // <== Should not be reached

Data: @040
    @: Trap           // Address of Trap handler
    d: 00000800       // Mask for enable/disable M-mode interrupts
    d: 00000008       // Mast for Global interrupts
    d: 00000800       // Base address of IO
    @: Data           // Address of Data block

RVector: @0C0
    @: Boot           // Address of Boot sequence
