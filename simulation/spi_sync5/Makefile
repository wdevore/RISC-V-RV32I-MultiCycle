# Top module is the HDL component being tested.
TOP = Top

# A cpp test-bench driver
TEST_BENCH = \
	SPI_tb.cpp

TEMPLATE_HEADER = ../module.h

# VERILATOR_PUBLICS = 
# The vcd data for viewing
GTKWAVE_SETTINGS = waveform

# HDL modules
MODULES_FILES =  \
	definitions.sv \
	Enums.sv \
	SPIMaster.sv \
	SPISlave_mcp23s17.sv \
	../../modules/Memory.sv \
	IOModule.sv \
	Top.sv
	
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
	--top-module ${TOP}

compile:
	@echo "################## Compiling ##################"
	cp ${TEST_BENCH} ${BUILD_DIR}
	cp ${TEMPLATE_HEADER} ${BUILD_DIR}
	${SIMULATION_TOOLCHAIN} --Mdir ${BUILD_DIR} \
	--trace -cc \
	--top-module ${TOP} \
	--exe --build ${TEST_BENCH} ${MODULES_FILES} \
	-DUSE_TX_DATA \
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
