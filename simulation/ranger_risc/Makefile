# With (yes) or Without (no) CSRs
WITH_CSRs = no

# Top module is the HDL component being tested.
TOP = RangerRisc

ifeq ($(WITH_CSRs), yes)
	MATRIX = ControlMatrixCSRs
	RR_CSR = RangerRiscCSRs
	IGNORE_IRQ = 0
else
	MATRIX = ControlMatrix
	RR_CSR = RangerRisc
	IGNORE_IRQ = 1
endif

# A cpp test-bench driver
TEST_BENCH = \
	misc.cpp \
	loop.cpp \
	reset_sequence.cpp

TEMPLATE_HEADER = ../module.h

# VERILATOR_PUBLICS = 
# The vcd data for viewing
GTKWAVE_SETTINGS = ebreak

# HDL modules
MODULES_FILES =  \
	../../definitions/definitions.sv \
	../../definitions/TypeEnums.sv \
	../../modules/Mux8.sv \
	../../modules/Mux4.sv \
	../../modules/Mux2.sv \
	../../modules/${MATRIX}.sv \
	../../modules/Register.sv \
	../../modules/Memory.sv \
	../../modules/ALU.sv \
	../../modules/Immediate.sv \
	../../modules/RegisterFile.sv \
	../../modules/Pmmu.sv \
	../../modules/${RR_CSR}.sv
	
# output build directory
BUILD_DIR = /media/RAMDisk

# Verilator is the simulator
SIMULATION_TOOLCHAIN = /usr/local/bin/verilator

# Set your reset vector address here, and it should be in
# Byte-Address form. For example, if you have a Word-address
# of @00000010 then the Byte-address is 10*4 = 0x00000040
# RESET_BOOT_VECTOR = "32'h00000040" # @010
RESET_BOOT_VECTOR = "32'h00000300" # @0C0
# RESET_BOOT_VECTOR = "32'h0000006C"

# Typically you would use "lint", "compile"+"run"+"view", or just "go"
# The other target/phonies are for reference and perhaps of some limited functionality.
.PHONY: all

lint:
	@echo "############### Linting via Verilator ##################"
	${SIMULATION_TOOLCHAIN} --lint-only -Wall ${MODULES_FILES} \
	--top-module ${TOP} \
	-DSIMULATE

compile:
	@echo "################## Compiling ##################"
	cp ${TEST_BENCH} ${BUILD_DIR}
	cp ${TEMPLATE_HEADER} ${BUILD_DIR}
	cp RangerRisc_tb.cpp ${BUILD_DIR}/RangerRisc_tb.cpp
	${SIMULATION_TOOLCHAIN} --Mdir ${BUILD_DIR} \
	--trace -cc \
	--top-module ${TOP} \
	--exe --build RangerRisc_tb.cpp ${TEST_BENCH} ${MODULES_FILES} \
	-DSIMULATE \
	-DPOPULATE_REGISTERS \
	-DPOPULATE_CSR_REGISTERS \
	-DRESET_VECTOR=${RESET_BOOT_VECTOR} \
	-DIRQ_ENABLED=${IGNORE_IRQ} \
	-DUSE_ROM

run:
	@echo "################## Simulating ##################"
	${BUILD_DIR}/V${TOP}

view:
	@echo "################## Viewing ##################"
	gtkwave ${BUILD_DIR}/waveform.vcd ${GTKWAVE_SETTINGS}.gtkw

go: compile run view
	@echo "################## Simulated via Verilator ##################"

clean:
	rm ${BUILD_DIR}/*

exe:
	cp ${TEST_BENCH} ${BUILD_DIR}
	${SIMULATION_TOOLCHAIN} --cc --Mdir ${BUILD_DIR} \
	--exe ${TEST_BENCH} ${MODULES_FILES} \
	-DSIMULATE

build:
	${SIMULATION_TOOLCHAIN} --cc --Mdir ${BUILD_DIR} \
	--build ${TEST_BENCH} ${MODULES_FILES} \
	-DSIMULATE

archive:
# Step 1: Generate an xxx.a file for linking
# NOTE: use make's "-C" to change directory instead of "()"s
# ( \
# cd ${BUILD_DIR} && \
# make OPT_SLOW="-Os -march=native" -f Vregister_tb.mk Vregister_tb__ALL.a \
# )
	make -C ${BUILD_DIR} OPT_SLOW="-Os -march=native" -f V${TOP}.mk V${TOP}__ALL.a
