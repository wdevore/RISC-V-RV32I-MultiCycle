# SPI
- *spi* project is the first project I worked on and it is a SystemVerilog version of Nandland's
- *cross_domain_clock* is a demonstration of CDC without SPI. async_i is the signal that is syncrhonised.
- *spi_alt* is the next project--incomplete--at building a state machine variant
- *spi_sync* isn't quite correct. This is combinational state driven.
- *spi_sync2* This is not correct either.
- *spi_sync3* This --broken-- implements Mode 0 for single byte - full duplex
- *spi_sync4* This...
- *spi_sync5* This partially works but is still broken
- **spi_sync6** This is **fully functional** Mode 0 with an IO module as well **but only for simulation**. It has two improperly driven variables: *data_out* and *miso*.
- **spi_sync7** This is modified for Synthesis using Muxes and is what sources *spi_slave*
- *spi_slave* This is a modified version of spi_sync7 for functioning as a slave to a pico. It is designed to test the fpga acting as a slave.
- **spi_sync8** This is an attempt to rewrite the slave to fix a synthesis issue with pin ports. Gatecat solved my problem! It was an initializer missing on my "state" variable. It also synthesizes correctly now.

Synthesis:
- *spi_slave* is a working version. The simulations were simulating a digital implementation of which some of the logic is not syntheziable. So this version has tweaks that make it work correctly on an actual device.

# Tasks
0) Install DLA on desktop
1) Code a working microcontroller SPI master to 4 digit SPI display.
2) Synthesize a SPI Master to 4 digit SPI display
3) Synthesize a SPI Master to Nxt's 7 segments.
4) Synthesize a SPI Slave on Nxt to receive from uC and send to 7 Segment.