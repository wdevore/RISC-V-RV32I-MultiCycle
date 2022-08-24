# Line assembler
First you place your 1 line of assembly in the *assembly.json* file and include any context information like a **label** and **PC** values. Some instructions need context others don't.

Then you invoke the tool that is in *gen-instr/* folder and invoked as:
- $go run .

# Basic assembler
This tool takes the line assembler to the next step by assembling *.asm* files. The syntax is fairly simple and is just enough for the video series. It isn't meant as a replacement for a full assembler.

The tool is in the *gen-instr/assembler* folder. It also uses an *assembly.json* file to specify what is assemble and where the source is and where the output goes.

You invoke it as:
- $go run .

Open a separate tab when using it in conjuction with the simulator.

Your *assembly.json* file should look similar to this only that your values will be different.

```json
{
    "RamDir": "/<path-to-rams>/RISC-V-RV32I-MultiCycle/simulation/ranger_console/rams/",
    "RamFile": "code.ram",
    "OutFile": "/media/RAMDisk/code.out",
    "input": "../source/interrupt_check.asm",
    "entryAddr": "0x0"
}
```
