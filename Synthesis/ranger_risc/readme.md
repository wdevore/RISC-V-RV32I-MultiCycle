# Description
This is RangerRisc version **without** CSRs. See ranger_risc_csr for CSRs expansion.

## Assembly
Nihongo/Hardware/Risc-v/TopReference/risc-v-asm-manual.pdf

### Notes:
The instructions themselves need to have the offset specified in byte-address form, however, the memory addresses can be defined as byte-address using "$" or word-address using "@".

If an instruction references an address that is defined in word-address form then it is converted to byte-address form even if it refers to a word-address. This is per the RISC-V ISA specs.

## Setup and running programs
You need to do several things in order for the cpu to run code on the FPGA. Open 3 terminals: one for the assembler, another for HDL toolchain and another for the go UART client.

1) Create or modify your ```<file>.asm``` program and make sure you update the assembler's assembly.json file. The assemlby files are typically stored in the *assemblies* under the application root folder.
2) Open a terminal and *cd* to *\<path to\>/tools/gen-instr/assembler* folder
3) Run the assembler ```go run . <file>.asm``` to produce the *code.ram* file that is embedded into the fpga bit stream via the ```$readmemh``` command.
4) Open another terminal and *cd* to *\<path to\>/Synthesis/ranger_risc* folder and run ```make```.
5) Open another terminal and *cd* to *\<path to\>/tools/go-uart* and run ```go run .```

### Assembler json
update the *inputPath* and *inputFile* keys to the .asm file you are targeting. Also, update the *RamDir* to direct the assembled ram code to a destination.

Then run ```go run .``` or ```go run . <file>.asm```

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

# Makefile
There are two ways we can setup a macro for injecting dynamic definitions in verilog code. I prefer #1.

1) Create a file, for example, **definitions.sv** with a ``` `define ROM_PATH "../rams/"```
2) Or, add a variable and macro definition to a makefile:
```Makefile
CODE_PATH = "\"../rams/\""
...
	-DRAMROM_PATH=${CODE_PATH} \
```
Then define a **localparam** as: ```localparam RomPath = `RAMROM_PATH;``` some place you need it, for example, memory.sv.

Here is an example:
```Makefile
CODE_PATH = "\"../rams/\""

.PHONY: all

all: build route upload

compile: build route

build: ${MODULES_FILES} ${PINS_CONSTRAINTS}
	@echo "##### Building..."
	${ICESTORM_TOOLCHAIN}/bin/yosys -p ${YOSYS_COMMAND} \
	-l ${BUILD_BIN}/yo.log \
	-q \
	-defer \
	-DRESET_VECTOR=${RESET_BOOT_VECTOR} \
	-DRAMROM_PATH=${CODE_PATH} \
	-DUSE_ROM \
	-DDEBUG_MODE \
	${MODULES_FILES}
```
