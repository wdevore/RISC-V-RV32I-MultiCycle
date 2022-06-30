# Interrupts

Reset Vector is moved from:

```localparam ResetVector = 32'h00000010 * 4```

RangerRisc___.sv to

```localparam ResetVector = 32'h000000C0 * 4```

Initialize mtvec

|       base         | mode |

mode = 0

## intr0.ram
```
Main:
    @000 0x000 20802083  lw x1, 0x208(x0) // Enable Global interrupts
    @001 0x004 3000A073  csrrs x0, mstatus, x1
    @002 0x008 01404083  lbu x1, 0x14(x0)   <<**IRQ**>>
    @003 0x00C 01004103  lbu x2, 0x10(x0)
    @004 0x010 00100073  ebreak
    @005 0x014 0000000C
    @006 0x018 0000000B
    @007 0x01C 0000000A
Boot:
    @040 0x100 20802083  lw x1, 0x208(x0) // Disable Global interrupts
    @041 0x104 3000B073  csrrc x0, mstatus, x1
    @042 0x108 20002083  lw x1, 0x200(x0) // load mtvec base addr
    @043 0x10C 30509073  csrrw x0, mtvec, x1
    @044 0x110 20402083  lw x1, 0x204(x0) // Enable M-mode Mie.MEIE 
    @045 0x114 3040A073  csrrs x0, mie, x1
    @046 0x118 EE9FF06F  jal x0, Main
Trap:
    @060 0x180 00C04183  lbu x3, 0x0C(x0)  // Trap handler
    @061 0x184 00100073  ebreak
    ----
Data:
    @080 0x200 00000180  // Address of Trap handler
    @081 0x204 00000800  // Mask for enable/disable M-mode interrupts
    @082 0x208 00000008  // Mast for Global interrupts
RVector:
    @0C0 0x300 00000100  // Address of Boot sequence
```

## intr1.ram

Add the "mret" instruction

Ncurse setup
- dt 1
- bra 0x60
- irqt 1202
- irqd 3
- irq on
- fr on

```
Main:
    @000 0x000 20802083  lw x1, 0x208(x0) // Enable Global interrupts
    @001 0x004 3000A073  csrrs x0, mstatus, x1
    @002 0x008 01404083  lbu x1, 0x14(x0)   <<**IRQ**>>
    @003 0x00C 01004103  lbu x2, 0x10(x0)
    @004 0x010 00100073  ebreak
    @005 0x014 0000000C
    @006 0x018 0000000B
    @007 0x01C 0000000A
Boot:
    @040 0x100 20802083  lw x1, 0x208(x0) // Disable Global interrupts
    @041 0x104 3000B073  csrrc x0, mstatus, x1
    @042 0x108 20002083  lw x1, 0x200(x0) // load mtvec base addr
    @043 0x10C 30509073  csrrw x0, mtvec, x1
    @044 0x110 20402083  lw x1, 0x204(x0) // Enable M-mode Mie.MEIE 
    @045 0x114 3040A073  csrrs x0, mie, x1
    @046 0x118 EE9FF06F  jal x0, Main
Trap:
    @060 0x180 00C04183  lbu x3, 0x0C(x0)  // Trap handler
    @061 0x184 30200073  mret
    @062 0x188 00100073  ebreak   <== Should not be reached
    ----
Data:
    @080 0x200 00000180  // Address of Trap handler
    @081 0x204 00000800  // Mask for enable/disable M-mode interrupts
    @082 0x208 00000008  // Mast for Global interrupts
RVector:
    @0C0 0x300 00000100  // Address of Boot sequence
```
