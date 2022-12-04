# Description
Send bytes to fpga via UART.

We use a coroutine for non-blocking keyboard IO.

# Links
- https://pkg.go.dev/go.bug.st/serial
- https://github.com/jacobsa/go-serial
- https://reprage.com/posts/2014-01-12-using-golang-to-connect-raspberrypi-and-arduino/
- https://stackoverflow.com/questions/27209697/how-to-read-input-from-console-in-a-non-blocking-way-with-go

```
Info: Max frequency for clock  'clk$SB_IO_IN_$glb_clk': 147.62 MHz (PASS at 25.00 MHz)
ERROR: Max frequency for clock 'led$SB_IO_OUT_$glb_clk': 22.07 MHz (FAIL at 25.00 MHz)
```

At 20MHz for nextpnr
```
Info: Max frequency for clock 'clk$SB_IO_IN_$glb_clk': 141.02 MHz (PASS at 20.00 MHz)
Info: Max frequency for clock    'cpu_clock_$glb_clk': 20.85 MHz (PASS at 20.00 MHz)
```