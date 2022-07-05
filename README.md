# Ranger Risc (RISC-V-RV32I-MultiCycle)
An intuitive multi-cycle RISC-V RV32I soft-core processor for FPGAs using open source software and Folknology's BlackIce Mx.

This repository represents the **[After Hours Engineering](https://www.youtube.com/channel/UCQxFumV2LMrKBMDW6dar_ZA)** Youtube series.

![AfterHoursEngineering](AfterHoursEngineering.png)

## Components
    [x] Mux(s)
    [x] Register
    [x] RegisterFile
    [x] ALU
    [x] Immediate
    [x] Memory
    [x] Pmmu
    [x] ControlMatrix

## Simulation
    [x] Mux(s)
    [x] Register
    [x] RegisterFile
    [x] ALU
    [x] Immediate
    [x] Memory
    [x] Pmmu
    [x] Instruction Register
    [x] RangerRisc
    [x] Testbench GtkWave
    [x] Testbench NCurses

# Howto(s)

# RangerRisc Console
Simulating the softcore processor was done two ways: *Gtkwave* and *NCurses console*.

## NCurses console
### Run simulation
- Navigate into the *RISC-V-RV32I-MultiCycle/simulation/ranger_console* directory.
- Modify *memory.sv* ```defines``` to reference your *.ram* file.
   ```
   `define ROM_PATH "rams/"
   `define ROM_EXTENSION ".ram"
   `define MEM_CONTENTS "itype_csrs/intr1"
   ```

- execute "make console"

### Commands the console recognizes
- Hitting "return" repeats the previous command -- if there was one
- **rn** Run to a specific state or instruction, for example
   - rn fetch **or** rn fe
   - rn decode **or** rn de
   - rn execute **or** rn ex
   - rn ebreak **or** rn eb
   - rn pc *word addrs*
      - rn pc 0x10
- **reset** resets simulation
- **sg** Send a (l)ow/(h)igh signal
   - sg reset h
- **ss** Start simulation. Runs N steps before stopping
   - To run for 1000000 steps and then stop
      - ss 1000000
- **h** Halts simulation if running
- **ns** Steps a single unit-step
- **hc** Steps a half clock cycle
- **fl** Steps a full clock cycle
- **delay** enables/disables thread sleep delay
   - delay on
   - delay off
- **dt** Change thread sleep delay time
   - dt delay-number
      - dt 1
      - dt 10
- **srg** Makes a RegFile register active for display in binary and decimal
   - srg 3
- **crg** Change a RegFile value
   - change x3 to 0
      - crg 3
   - change x9 to 0xAA
      - crg 9 0xAA
- **mr** Set starting memory display range *Word-address* format. Default is 0
   - mr 0x040
- **mm** Modify a memory address *Word-address* format.
   - mm 0x4c 0x0000ABCD
- **ld** Load a program from *rams* folder, without *.ram* extension.
   - To load lr.ram
      ld lr
- **pc** Set PC register to a *Word-address*
   - pc 0x04D
- **bra** Break a *Word-address*
   - bra 0xC0
- **br** Break enable/disable
   - br on
   - br off
      - **or** br
- **fr** FreeRun enable/disable
   - fr on
   - fr off
      - **or** fr
- **stp** Stepping enable/disable
   - stp on
   - stp off
      - **or** stp
- **irq** IRQ enable/disable
   - irq on
   - irq off
      - **or** irq
- **irqt** Set trigger point (Units are in unit-step)
   - irqt 0x04D
- **irqd** Set IRQ duration. Default = 3
   - irqd 5

![RangerRiscConsole](RangerRiscConsole.gif)

## Gtkwave
### Run simulation
- Navigate into the *RISC-V-RV32I-MultiCycle/simulation/ranger_risc* directory.
- Modify *memory.sv* ```defines``` to reference your *.ram* file.
   ```
   `define ROM_PATH "rams/"
   `define ROM_EXTENSION ".ram"
   `define MEM_CONTENTS "itype_csrs/intr1"
   ```
- execute "make go"

You should now see the Gtkwave output as shown below.

![Gtkwave](Gtkwave_CountUp.png)

# Hardware

## Folknology
![Folknology](Folknology.png)



## DPI
- https://www.doulos.com/knowhow/systemverilog/systemverilog-tutorials/systemverilog-dpi-tutorial/
- https://en.wikipedia.org/wiki/SystemVerilog_DPI
- https://www.youtube.com/watch?v=HhSAnApHYkU

https://www.exploringbinary.com/twos-complement-converter/

## Misc

Tasks:
- Store PC in mepc
- Store mtvec in PC
- Add mem mapped IO and interrupts
- CSRs:
- https://opencores.org/projects/potato/control%20registers
- https://marz.utk.edu/my-courses/cosc562/riscv/ eOS
- https://danielmangum.com/posts/risc-v-bytes-privilege-levels/
- https://book.rvemu.app/hardware-components/03-csrs.html
- https://danielmangum.com/posts/risc-v-bytes-privilege-levels/
- https://bonfirecpu.eu/bonfire_core.html version scheme
- RISCV An Overview of the ISA.pdf
- The RISC-V Reader privileged Arch

- mtvec, Machine Trap Vector, holds the address the processor jumps to when an exception occurs.
- mepc, Machine Exception PC, points to the instruction where the exception occurred.
- mcause, Machine Exception Cause, indicates which exception occurred.
- mie, Machine Interrupt Enable, lists which interrupts the processor can take and which it must ignore.
- mip, Machine Interrupt Pending, lists the interrupts currently pending.
- mtval, Machine Trap Value, holds additional trap information: the faulting address for address exceptions, the instruction itself for illegal instruction exceptions, and zero for other exceptions.
- mscratch, Machine Scratch, holds one word of data for temporary storage.
- mstatus, Machine Status, holds the global interrupt enable, along with a plethora of other state, as Figure 10.4 shows.


Interrupt can be taken if mstatus.MIE=1, mie[N]=1, and mip[N]=1

- mip.MEIP = mip[11] (RO)
- mie.MEIE = mie[11]
- mstatus.MIE = mstatus[3]
- mstatus.MPIE = mstatus[7]

Interrupts pending bits are checked at the end of an instruction (retired).
- Prolog stores state
- Epilog restores state

### Communication
Only one byte is transmitted at a time. Before each Trx the Ownership bits are checked.

## Ownership
- 00 = neither own
- 01 = Console owns
- 10 = Sim owns

### Sim
At the end of each retired instruction the Sim checks ownership bits. Thus the Sim can only transmit if the bits = 00.

### Console

To send data either Console or Sim must grab the mutex first. The one that has the mutex can send data.
The other must poll until the mutex is freed.
PIO.control[0] = mutex
PIO.control[1] = send-ready signal
PIO.control[2] = data-ready signal
PIO.control[3] = data-end signal

-------------------

## Circuit

### UART

BitRate/ClockFrq = (9600/1000000000)/(1000000000/50000000) = 5208.333333333

Ceil(5208.333333333) = 13

and 2^13 = 8192

% difference is: 0.853333333 = 8.5% which is < 10% allowable max.

#### Links
- https://nandland.com/uart-serial-port-module/
- https://www.fpga4fun.com/SerialInterface2.html
- https://www.maximintegrated.com/en/design/technical-documents/tutorials/2/2141.html
- https://community.silabs.com/s/article/baud-rate-accuracy-using-the-hfrco?language=en_US
- https://erg.abdn.ac.uk/users/gorry/eg3576/UART.html
- https://www.sciencedirect.com/topics/engineering/baud-rate
- https://en.wikipedia.org/wiki/Crystal_oscillator_frequencies#:~:text=115200-,UART%20clock%20allows%20integer%20division%20to%20common%20baud%20rates%20up,)%20or%20230%2C400(x8x3).&text=audio-,Used%20in%20CD%2DDA%20systems%20and%20CD%2DROM%20drives%3B,22.05%20kHz%2C%20and%2011.025%20kHz.



##@ async futures
- https://devdreamz.com/question/844791-user-input-without-pausing-code-c-console-application
- https://forum.juce.com/t/async-input-stream/48817/4
- https://www.codeproject.com/Questions/5275669/How-can-I-use-input-without-waiting-user-to-give-s
- https://www.linuxquestions.org/questions/programming-9/how-do-i-watch-for-keyboard-input-without-waiting-in-c-858521/
- http://www.cplusplus.com/forum/general/242502/

Blogs:
- http://jborza.com/

RISC-V usage:
- https://dzone.com/articles/introduction-to-the-risc-v-architecture#:~:text=The%20RISC%2DV%20S%20privilege,a%2012%2Dbit%20page%20offset.
  - LUI example with addi

## Tools
- https://www.digitalelectronicsdeeds.com/index.html
- https://github.com/chipsalliance/UHDM  SystemVerilog to Verilog
- https://www.rapidtables.com/convert/number/decimal-to-hex.html Good calculator

coredumps:
ulimit -c unlimited
gdb /media/RAMDisk/VRangerRisc
   backtrace

## Verilator Errors
### AstNode error
```
AstNode is not of expected type, but instead has type 'TYPEDEF'
  138 | } CSReg /*verilator public*/ ; 
      |   ^~~~~
```
The above error is caused when you incorrectly use your *enum* incorrectly. For example,
```
    case (csrAddr)
        CSReg::Mstatus: regIdx = 0;
```
Leave the XXX:: prefix off:
```
    case (csrAddr)
        Mstatus: regIdx = 0;
```

                // IRQ0: begin
                //     // PC is pointing at the next instruction. Store it
                //     // for mret instruction.
                //     // Mepc <== PC
                //     csr_src = CSRSrcPC;
                    // csr_wr = RWActive;
                //     csradr_src = CMCSRAddr;
                //     csr_addr = Mepc;

                //     next_ir_state = IRQ1;
                // end
