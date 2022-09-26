# Summary
This is a test *harness* designed to test the *slave* portion of the SPI module. The fpga will not utilize the SPI Master just the Slave.

The *master* is a Pico RP2040. The master sends a sequence of bytes mimicking a small portion of an MCP23S17. Once a specific byte sequence is detected a return byte is sent back otherwise zeros are sent.

The Top module contains the IOModule.