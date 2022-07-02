// Tests the MRET instruction

Main: @000
    lw x1, @Data+2(x0)        // Enable Global interrupts
    csrrs x0, mstatus, x1
    lbu x1, @Data1(x0)        // <<**IRQ**>>
    lbu x2, @Data1+1(x0)
    ebreak
Data1: @005
    d: 0000000C
    d: 0000000B
    d: 0000000A

Boot: @040
    lw x1, @Data+2(x0)        // Disable Global interrupts
    csrrc x0, mstatus, x1
    lw x1, @Data(x0)        // load mtvec base addr
    csrrw x0, mtvec, x1
    lw x1, @Data+1(x0)        // Enable M-mode Mie.MEIE 
    csrrs x0, mie, x1
    jal x0, Main
Trap: @060
    lbu x3, @Main+3(x0)  // Trap handler
    mret
    ebreak            // <== Should not be reached
Data: @080
    @: Trap           // Address of Trap handler
    d: 00000800       // Mask for enable/disable M-mode interrupts
    d: 00000008       // Mast for Global interrupts
RVector: @0C0
    @: Boot           // Address of Boot sequence
