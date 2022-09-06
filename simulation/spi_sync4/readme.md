For collected information see [spi_sync3](../spi_sync3/readme.md)

# Summary
Usage:
This version is designed a Mode 0 and it will transmit N bytes and receive M bytes in half-duplex. This means Rx bytes are captured until all Tx bytes have been sent. This style is good for devices such as MCP23S17 where--in byte mode--2 bytes are sent and 1 byte is received.

There can also be *gaps* between bytes meaning that the clock can go inactive after a byte and then reactivate for another byte. Keep in mind that it's the Master that controls the clock and the slave completely operates by it. So if the slave has a byte to send it has to wait for clock from the master.

The Master will also keep the Clock low while inactive during *gaps*.

Master does not control /SS any longer but instead an outside Module.

# Simulation
In this simulation there are Modules:

- Top
  - TxModule
    - SPIMaster
  - RxModule
    - SPISlave

The TxModule will send 2 bytes and wait for a 3rd from the RxModule (aka slave)

The RxModule will wait for 2 bytes and decode them. If they equal a certain value it will send a byte back.

Each module has a small buffer for Tx/Rx.

## Transmit
To transmit data you assert chip-select (CS). The master will then transmit and receive bytes until CS is deasserted.

You can specify a *Clock gap* count. This specifies how many clock cycles to generate between each byte transmission.

# SPI Protocol Mode 0

**CPOL=0** is a clock which idles at 0, and each cycle consists of a pulse of 1. That is, the leading edge is a rising edge, and the trailing edge is a falling edge.
```
   Lead   Trailing
      |   |
      v   v
   ___/---\___/---\___
          |
          |
          | data changes here for the "next" rising edge.
```
            

**CPHA=0**, the "out" side changes the data on the trailing edge of the preceding clock cycle, while the "in" side captures the data on (or shortly after) the leading edge of the clock cycle.

The out side holds the data valid until the trailing edge of the current clock cycle. For the first cycle, the first bit must be on the MOSI line before the leading clock edge. An alternative way of considering it is to say that a CPHA=0 cycle consists of a half cycle with the clock idle, followed by a half cycle with the clock asserted.
