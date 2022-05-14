# Top module is the HDL component being tested.
TOP = RangerRisc

# A cpp test-bench driver
TEST_BENCH = \
	console.cpp \
	simulation.cpp \
	utils.cpp \
	console_tb.cpp

TEMPLATE_HEADER = \
	console_module.h

HEADERS = \
	commands.h \
	row_indices.h \
	console.h \
	model.h \
	simulation.h \
	utils.h \
	property.h

# HDL modules
MODULES_FILES =  \
	../../definitions/definitions.sv \
	../../definitions/TypeEnums.sv \
	../../modules/Mux8.sv \
	../../modules/Mux4.sv \
	../../modules/Mux2.sv \
	../../modules/ControlMatrix.sv \
	../../modules/Register.sv \
	../../modules/Memory.sv \
	../../modules/ALU.sv \
	../../modules/Immediate.sv \
	../../modules/RegisterFile.sv \
	../../modules/Pmmu.sv \
	${TOP}.sv
	
# output build directory
BUILD_DIR = /media/RAMDisk

# Verilator is the simulator
SIMULATION_TOOLCHAIN = /usr/local/bin/verilator

# .PHONY: all

lint:
	@echo "############### Linting via Verilator ##################"
	${SIMULATION_TOOLCHAIN} --lint-only -Wall ${MODULES_FILES} \
	--top-module ${TOP} \
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
	${SIMULATION_TOOLCHAIN} --cc \
	--Mdir ${BUILD_DIR} \
	--top-module ${TOP} \
	--exe ${TEST_BENCH} ${MODULES_FILES} \
	-DDEBUG_MODE \
	-DSIMULATE \
	-DPOPULATE_REGISTERS \
	-DUSE_ROM

runMake:
	@echo "################## Running Makefile ##################"
	make -j4 -C ${BUILD_DIR} -f V${TOP}.mk CXXFLAGS='-Wall -Wextra -g' LIBS='-lncurses'

launch:
	@echo "################## Simulating ##################"
	${BUILD_DIR}/V${TOP}
