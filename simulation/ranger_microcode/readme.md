# Microcode
This version splits the ControlMatrixCSRs.sv into basically two parts. If moves many of the combinational statements out of the main combinational behavioural block and refactors the **Decode** and **Execute** states.

## Reset
This state sequence stays the same. All of the signals it changes are ORed with the respective ROM signals.

## Fetch
This state sequence stays the same. *ir_ld* and *pcp_ld* are not in the ROM.

## Decode
This state calculates the ROM address for the **Execute** state.

## Execute
This state is a Microcode ROM bank with a counter that is set by the **Decode** state.

## Assembly

### Notes:
The instructions themselves need to have the offset specified in byte-address form, however, the memory addresses can be defined as byte-address using "$" or word-address using "@".

If an instruction references an address that is defined in word-address form then it is converted to byte-address form even if it refers to a word-address. This is per the RISC-V ISA specs.

### Compiling
You need to run the assembler to produce a rams/code.ram file.

```cd /media/path/to/risc/RISC-V-RV32I-MultiCycle/tools/gen-instr/assembler```.

update the *inputPath* and *inputFile* keys to the .asm file you are targeting. Also, update the *RamDir* to direct the assembled ram code to a destination.

Then run ```go run .``` or ```go run . xxx.asm```

### Example assembly code
```
Main: @
    lw x1, 0x28(x0)     // 0x28 BA = 0x0A WA
    ebreak              // Stop

Data: @00A
    d: DEADBEEF         // data to load

RVector: @0C0           // 0x300 BA = 0xC0 WA
    @: Main             // Reset vector
```

The *RVector*'s value is what is defined in the makefile entry:

```RESET_BOOT_VECTOR = "32'h00000300" # @0C0```

After running the assembler you get a helpful yet extra *code.out* for cross reference:

```
@00000000 02802083 lw x1, 0x28(x0)     // 0x28 BA = 0x0A WA
@00000001 00100073 ebreak              // Stop
@0000000A DEADBEEF d: DEADBEEF         // data to load
@000000C0 00000000 @: Main             // Reset vector
```

## Simulation
Now that you have assembled your code you can run the simulation.

```cd /media/path/to/risc/RISC-V-RV32I-MultiCycle/simulation/ranger_microcode```
```make go```