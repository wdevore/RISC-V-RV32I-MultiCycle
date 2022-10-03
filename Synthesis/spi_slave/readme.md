# Summary
This is a test *harness* designed to test the *slave* portion of the SPI module. The fpga will not utilize a SPI Master just the Slave.

The *master* is a Pico RP2040. The master sends a sequence of bytes mimicking a small portion of an MCP23S17. Once a specific byte sequence is detected a return byte is sent back otherwise zeros are sent.

There are a pair of debug versions that expose a bunch of signals on the BlackiceNxt PMOD tiles:
- SPISlave_mcp23s17_debug.sv
- Top_debug.sv

The normal versions lack the "_debug" extensions.
