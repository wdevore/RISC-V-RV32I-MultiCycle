- https://electronics.stackexchange.com/questions/553981/spi-clock-signal-sclk-usage-in-fpga-spi-slave
- https://coertvonk.com/hw/math-talk/byte-exchange-with-a-fpga-as-slave-30818
- https://www.fpga4fun.com/CrossClockDomain.html

As soon as you introduce a SPI slave interface into your FPGA design, you introduce a new clock (the SPI clock) and a second clock domain. All of the SPI signals belong to that second domain, and you are now faced with the problem of reliably transferring information across the boundary. This is commonly referred to as "CDC" (clock domain crossing), and there's plenty of information about this topic if you search for it.

By far the most common approach, if the FPGA's main clock is fast enough, is to synchronize the three incoming signals (SSEL, SCLK, MOSI) into the main clock domain right away (two FFs per signal), run the SPI state machine in that clock domain, and ignore the jitter that this introduces into the output signal (MISO) feeding back into the SPI clock domain. This generally works fine.

An alternative approach is to run the SPI state machine in the SPI clock domain, and transfer information between the two clock domains a byte or word at a time using asynchronous (dual-clock) FIFOs. This approach can potentially run faster, but it requires careful design of the state machine that takes into account the limited number of clock edges available to it.

In either case, you will have one set of timing constraints for the FPGA clock domain, another set of constraints for the SPI clock domain, and a third set that covers the CDC.

If the FPGA clock is >= 4X the SPI clock rate it is relatively easy to digitally detect the edges. Nyquist says you only need 2X, but its really hard to guarantee that you'll see all the edges. If they are almost the same speed you should use the SCLK. It should go through the FPGA clock buffers so that you will have a low amount of clock skew. There are clock conditioners / PLLs that will let you take in the SCLK and adjust the phase so that you can drive it to the Flip-Flops in the I/O registers.

Writing timing constraints is one of the hardest parts of FPGA design. You need to look at the SPI spec and also account for board routing delays. If you define the phase relationship between the data and the clock at the IO pin, the tools will let you know if it will meet timing at the flip-flops.

You may not need global clock routing, but I would recommend at least regional clock routing. If you use certain pins on some FPGAs it can be routed to clock buffers more easily.

```
logic [2:0] async_r;  // 3 bits
always @(posedge sysClk)
    async_r <= { async_r[1:0], async };
logic rising = ( async_r[2:1] == 2'b01 );
logic falling = ( async_r[2:1] == 2'b10 );
logic sync = async_r[1];
```