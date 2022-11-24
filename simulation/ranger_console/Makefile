# With (yes) or Without (no) CSRs
WITH_CSRs = yes

# Top module is the HDL component being tested.
TOP = RangerRisc

ifeq ($(WITH_CSRs), yes)
	MATRIX = ControlMatrixCSRs
	RR_CSR = RangerRiscCSRs
else
	MATRIX = ControlMatrix
	RR_CSR = RangerRisc
endif

# A cpp test-bench driver
TEST_BENCH = \
	console.cpp \
	simulation.cpp \
	utils.cpp

TEMPLATE_HEADER = \
	console_module.h

HEADERS = \
	definitions.h \
	model.h \
	commands.h \
	row_indices.h \
	console.h \
	simulation.h \
	utils.h \
	property.h

# HDL modules
MODULES_FILES =  \
	../../definitions/definitions.sv \
	../../definitions/TypeEnums.sv \
	../../modules/CDCSynchron.sv \
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

# .PHONY: all

lint:
	@echo "############### Linting via Verilator ##################"
	${SIMULATION_TOOLCHAIN} --lint-only -Wall ${MODULES_FILES} \
	--top-module ${TOP} \
	-DRESET_VECTOR=${RESET_BOOT_VECTOR} \
	-DSIMULATE

clean:
	rm ${BUILD_DIR}/*

# Below are the targets for building AND linking with ncurses
# It is split into several parts:
# 1) build the verilator makefile and simulation source
#    which includes the ncurses source and dependencies
# 2) run "make" against make file and append extra flags for
#    for stronger warnings and ncurses library dependency
# 3) run the executable produced by the ".mk" makefile

console: buildSimMk runMake launch
	@echo "################## Console ##################"

buildSimMk:
	@echo "################## Building Makefile ##################"
	cp ${TEST_BENCH} ${BUILD_DIR}
	cp ${TEMPLATE_HEADER} ${BUILD_DIR}
	cp ${HEADERS} ${BUILD_DIR}
	cp console_tb.cpp ${BUILD_DIR}/console_tb.cpp
	${SIMULATION_TOOLCHAIN} --cc \
	--Mdir ${BUILD_DIR} \
	--top-module ${TOP} \
	--exe console_tb.cpp ${TEST_BENCH} ${MODULES_FILES} \
	-DSIMULATE \
	-DPOPULATE_REGISTERS \
	-DPOPULATE_CSR_REGISTERS \
	-DRESET_VECTOR=${RESET_BOOT_VECTOR} \
	-DUSE_ROM

runMake:
	@echo "################## Running Makefile ##################"
	make -j4 \
	-C ${BUILD_DIR} \
	-f V${TOP}.mk \
	CXXFLAGS='-Wall -Wextra -g' LIBS='-lncurses'

launch:
	@echo "################## Simulating ##################"
	${BUILD_DIR}/V${TOP}
