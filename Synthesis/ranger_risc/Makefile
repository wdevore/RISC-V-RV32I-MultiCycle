MATRIX = ControlMatrixCSRs

TOP_FILE = Top.sv

SUB_MODULES_FILES = \
	../../definitions/definitions.sv \
	TypeEnums.sv \
	../../modules/CDCSynchron.sv \
	../../modules/Mux8.sv \
	../../modules/Mux4.sv \
	../../modules/Mux2.sv \
	../../modules/Register.sv \
	../../modules/Memory.sv \
	../../modules/ALU.sv \
	../../modules/Immediate.sv \
	../../modules/RegisterFile.sv \
	../../modules/Pmmu.sv \
	../Modules/Decoder.sv \
	../Modules/SevenSeg.sv \
	Enums.sv \
	UARTDefinitions.sv \
	UARTTx.sv \
	UARTRx.sv \
	ControlMatrix.sv \
	RangerRiscProcessor.sv

MODULES_FILES = ${SUB_MODULES_FILES} ${TOP_FILE}

BUILD_BIN = /media/RAMDisk

ICESTORM_TOOLCHAIN = /usr/local

YOSYS_COMMAND = "synth_ice40 -blif ${BUILD_BIN}/chip.blif -json ${BUILD_BIN}/hardware.json -top Top"

# The Blackice Nxt shows up as generally ACM0 or ACM1 depending on what other
# devices you have connected. Be sure to run "dmesg -w" and see what
# the device name is.

# 2:1.0: ttyACM0: USB ACM device
# new high-speed USB device number 42 using xhci_hcd
# New USB device found, idVendor=2109, idProduct=2815, bcdDevice= 7.04
# New USB device strings: Mfr=1, Product=2, SerialNumber=0
# Product: USB2.0 Hub             
# Manufacturer: VIA Labs, Inc.
#	--randomize-seed \

TARGET_PORT = /dev/ttyACM0

PINS_CONSTRAINTS = ../IceLogicBus.pcf

# Set your reset vector address here, and it should be in
# Byte-Address form. For example, if you have a Word-address
# of @00000010 then the Byte-address is 10*4 = 0x00000040
# RESET_BOOT_VECTOR = "32'h00000040" # @010
RESET_BOOT_VECTOR = "32'h00000300" # @0C0
# RESET_BOOT_VECTOR = "32'h0000006C"

# Note: 20MHz is used as the clock constraint instead of 64MHz. This design
# struggles to reach 22MHz as it is.
CORE_FREQUENCY = 18

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
	-DUSE_ROM \
	-DDEBUG_MODE \
	${MODULES_FILES}

route: ${BUILD_BIN}/hardware.json
	@echo "##### Routing..."
	${ICESTORM_TOOLCHAIN}/bin/nextpnr-ice40 \
	--hx8k \
	-q \
	--freq ${CORE_FREQUENCY} \
	--package bg121:4k \
	--pcf ${PINS_CONSTRAINTS} \
	-l ${BUILD_BIN}/next.log \
	--json ${BUILD_BIN}/hardware.json \
	--asc ${BUILD_BIN}/hardware.asc

time: ${BUILD_BIN}/hardware.bin
	icetime -tmd hx8k ${BUILD_BIN}/hardware.asc
	
upload: ${BUILD_BIN}/hardware.asc
	@echo "##### Packing..."
	${ICESTORM_TOOLCHAIN}/bin/icepack ${BUILD_BIN}/hardware.asc ${BUILD_BIN}/hardware.bin
	@echo "##### Uploading..."
	stty -F ${TARGET_PORT} raw
	cat ${BUILD_BIN}/hardware.bin >${TARGET_PORT}
