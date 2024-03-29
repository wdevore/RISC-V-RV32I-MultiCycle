# Top module is the HDL component being tested.
TOP = ALU

# A cpp test-bench driver
TEST_BENCH = \
	../../definitions/definitions.sv \
	misc.cpp \
	${TOP}_8bit_tb.cpp

TEMPLATE_HEADER = ../module.h

# VERILATOR_PUBLICS = 
# The vcd data for viewing
GTKWAVE_SETTINGS = waveform

# HDL modules
MODULES_FILES = \
	../../definitions/TypeEnums.sv \
	../../modules/${TOP}.sv

# output build directory
BUILD_DIR = /media/RAMDisk

# Verilator is the simulator
SIMULATION_TOOLCHAIN = /usr/local/bin/verilator

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
	--trace -cc \
	--top-module ${TOP} \
	--exe --build ${TEST_BENCH} ${MODULES_FILES} \
	-DSIMULATE

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
