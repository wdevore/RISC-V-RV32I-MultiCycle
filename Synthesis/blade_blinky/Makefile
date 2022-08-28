TOP_FILE = top.sv

SUB_MODULES_FILES = blink.sv

MODULES_FILES = ${SUB_MODULES_FILES} ${TOP_FILE}

BUILD_BIN = /media/RAMDisk

ICESTORM_TOOLCHAIN = /usr/local

YOSYS_COMMAND = "synth_ice40 -blif ${BUILD_BIN}/chip.blif -json ${BUILD_BIN}/hardware.json -top top"

# The Blackice Nxt shows up as generally ACM0 or ACM1 depending on what other
# devices you have connected. Be sure to run "dmesg -w" and see what
# the device name is.

# 2:1.0: ttyACM0: USB ACM device
# new high-speed USB device number 42 using xhci_hcd
# New USB device found, idVendor=2109, idProduct=2815, bcdDevice= 7.04
# New USB device strings: Mfr=1, Product=2, SerialNumber=0
# Product: USB2.0 Hub             
# Manufacturer: VIA Labs, Inc.

TARGET_PORT = /dev/ttyACM0

PINS_CONSTRAINTS = ../IceLogicBus.pcf

.PHONY: all

all: build route upload

build: ${MODULES_FILES} ${PINS_CONSTRAINTS}
	@echo "##### Building..."
	${ICESTORM_TOOLCHAIN}/bin/yosys -p ${YOSYS_COMMAND} \
	-l ${BUILD_BIN}/yo.log \
	-q \
	-defer \
	${MODULES_FILES}

route: ${BUILD_BIN}/hardware.json
	@echo "##### Routing..."
	${ICESTORM_TOOLCHAIN}/bin/nextpnr-ice40 \
	--hx8k \
	-q \
	--freq 64 \
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
