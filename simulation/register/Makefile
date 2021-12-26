# Top module is the HDL component being tested.
TOP = Register

# A cpp test bench driver
TEST_BENCH = register_tb.cpp

# The vcd data for viewing
GTKWAVE_SETTINGS = waveform

# HDL modules
MODULES_FILES = ../../modules/${TOP}.sv

# ARCHIVE_LIB = VRegister_tb.a

# output build directory
OBJECT_DIR = /media/RAMDisk

# Verilator is the simulator
SIMULATION_TOOLCHAIN = /usr/local/bin/verilator

.PHONY: all

lint:
	@echo "############### Linting via Verilator ##################"
	${SIMULATION_TOOLCHAIN} --lint-only -Wall ${MODULES_FILES}
exe:
	${SIMULATION_TOOLCHAIN} --cc --top-module ${TOP} --Mdir ${OBJECT_DIR} --exe ${MODULES_FILES}
build:
	${SIMULATION_TOOLCHAIN} --cc --top-module ${TOP} --Mdir ${OBJECT_DIR} --build ${MODULES_FILES}

archive:
# Step 1: Generate an xxx.a file for linking
# NOTE: use make's "-C" to change directory instead of "()"s
# ( \
# cd ${OBJECT_DIR} && \
# make OPT_SLOW="-Os -march=native" -f Vregister_tb.mk Vregister_tb__ALL.a \
# )
	make -C ${OBJECT_DIR} OPT_SLOW="-Os -march=native" -f V${TOP}.mk V${TOP}__ALL.a

compile:
	cp ${TEST_BENCH} ${OBJECT_DIR}
	${SIMULATION_TOOLCHAIN} -Wall --trace -cc --Mdir ${OBJECT_DIR} \
	-DSIMULATE \
	--exe --build ${TEST_BENCH} ${MODULES_FILES}

run:
	${OBJECT_DIR}/V${TOP}

view:
	gtkwave ${OBJECT_DIR}/waveform.vcd ${GTKWAVE_SETTINGS}.gtkw

go: compile run view
	@echo "################## Simulating via Verilator ##################"

clean:
	rm ${OBJECT_DIR}/*
