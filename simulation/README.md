# SPI
- *spi* project is the first project I worked on and it is a SystemVerilog version of Nandland's
- *cross_domain_clock* is a demonstration of CDC without SPI. async_i is the signal that is syncrhonised.
- *spi_alt* is the next project--incomplete--at building a state machine variant
- *spi_sync* isn't quite correct. This is combinational state driven.
- *spi_sync2* This is not correct either.
- *spi_sync3* This --broken-- implements Mode 0 for single byte - full duplex
- *spi_sync4* This...
- *spi_sync5* This partially works but is still broken
- **spi_sync6** This is fully functional Mode 0 with an IO module as well.


# Tasks
0) Install DLA on desktop
1) Code a working microcontroller SPI master to 4 digit SPI display.
2) Synthesize a SPI Master to 4 digit SPI display
3) Synthesize a SPI Master to Nxt's 7 segments.
4) Synthesize a SPI Slave on Nxt to receive from uC and send to 7 Segment.