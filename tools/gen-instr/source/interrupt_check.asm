// Program runs a small loop.
// An external interrupt pauses the loop and increments
// a counter on each Trap call.

Main: @000
    addi x3, x0, 0        // Counter starts at 0
    addi x5, x0, 0        // Trap Counter starts at 0
    lw x1, 0x8(x4)        // Enable Global interrupts
    csrrs x0, mstatus, x1
Loop: @
    addi x3, x3, 1     // x3 += 1
    jal x0, @Loop
    ebreak
Boot: @010
    lw x4, @Data+3(x0)          // init x4 to point to @Data
    lw x1, 0x8(x4)       // Disable Global interrupts
    csrrc x0, mstatus, x1
    lw x1, 0x0(x4)          // load mtvec base addr
    csrrw x0, mtvec, x1
    lw x1, 0x4(x4)        // Enable M-mode Mie.MEIE 
    csrrs x0, mie, x1
    jal x0, @Main
Trap: @020                    // Trap handler
    // Each time Trap called we inc x5
    addi x5, x5, 1     // x5 += 1
    mret
    ebreak            // <== Should not be reached
Data: @030
    @: Trap           // Address of Trap handler
    d: 00000800       // Mask for enable/disable M-mode interrupts
    d: 00000008       // Mast for Global interrupts
    @: Data           // Address of Data block
RVector: @0C0
    @: Boot           // Address of Boot sequence
