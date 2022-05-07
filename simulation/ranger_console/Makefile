# Top module is the HDL component being tested.
TOP = RangerRisc

# 	reset_sequence.cpp \

# A cpp test-bench driver
TEST_BENCH = \
	misc.cpp \
	console.cpp \
	console_tb.cpp

TEMPLATE_HEADER = \
	console_module.h

HEADERS = \
	commands.h \
	console.h

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

# ------------ NCurses ----------------------------
# NCurses = libncursesw.a
# LDLIBS = /usr/lib/gcc/x86_64-linux-gnu/9/libstdc++.a \
# 	/usr/lib/x86_64-linux-gnu/${NCurses}
	
# INCLUDES = /usr/include

#	-lncurses \
#	-I${INCLUDES} \
#	-LDFLAGS ${LDLIBS} \

# make build
# make exe
# make ncbuild
# make run

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
	${SIMULATION_TOOLCHAIN} --Mdir ${BUILD_DIR} \
	--cc \
	--top-module ${TOP} \
	--exe --build ${TEST_BENCH} ${MODULES_FILES} \
	-DSIMULATE \
	-DPOPULATE_REGISTERS \
	-DUSE_ROM


go: compile run
	@echo "################## Simulated via Verilator ##################"

build:
	@echo "################## Build ##################"
	cp ${TEST_BENCH} ${BUILD_DIR}
	cp ${TEMPLATE_HEADER} ${BUILD_DIR}
	${SIMULATION_TOOLCHAIN} --cc --Mdir ${BUILD_DIR} \
	--top-module ${TOP} \
	--build ${TEST_BENCH} ${MODULES_FILES} \
	-DSIMULATE \
	-DPOPULATE_REGISTERS \
	-DUSE_ROM

clean:
	rm ${BUILD_DIR}/*

# Below are the targets for building AND linking with ncurses
# It is split into several parts:
# 1) build the verilator makefile and simulation source
#    which includes the ncurses source and dependencies
# 2) run "make" against make file and set extra flags for
#    for stronger warnings and ncurses library dependency
# 3) run the executable produced by the ".mk" makefile
console: buildSimMk runMake launch

buildSimMk:
	@echo "################## Building Makefile ##################"
	cp ${TEST_BENCH} ${BUILD_DIR}
	cp ${TEMPLATE_HEADER} ${BUILD_DIR}
	cp ${HEADERS} ${BUILD_DIR}
	${SIMULATION_TOOLCHAIN} --cc \
	--Mdir ${BUILD_DIR} \
	--top-module ${TOP} \
	--exe ${TEST_BENCH} ${MODULES_FILES} \
	-DSIMULATE \
	-DPOPULATE_REGISTERS \
	-DUSE_ROM

runMake:
	@echo "################## Running Makefile ##################"
	make -C ${BUILD_DIR} -f V${TOP}.mk CXXFLAGS='-Wall -Wextra -g' LIBS='-lncurses'

launch:
	@echo "################## Simulating ##################"
	${BUILD_DIR}/V${TOP}
