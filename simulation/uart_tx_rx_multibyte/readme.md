
This is a UART simulation of both a transmitter and receiver.

# Summary
- protocol: **8N1**
- baud: **115200**
- Crystal clock: 1843200

We use clock-enables instead of clock-dividers. The clock idles high.

## Crystals
- https://electronics.stackexchange.com/questions/283044/the-crystal-oscillator-used-in-uart-is-of-11-059mhz-why

## Baud generator
- https://docs.google.com/document/d/1R4TkLq2c04HjlUcB7ZM2g75sccjFwR_p9DKrgqMnw1Q/edit#heading=h.7wtgda4qtml1

Clock enables every =
```
  core clock frequency          25000000
  -------------------   =  ------------------- = 217.0138.. = 217 = bit period
        baud rate                115200
```
An enable pulse is generated every 217 ticks. Maximum baud error rate allowed is +-5%.

If the core clock is 2MHz then we use Dimensional analysis and chose M (2^M) = 1024 = 2^10

1024 is selected because it is a power of 2: = 10 bits (2^10)
- Core clock = 2MHz
- M = 2^10
```
2000000    M(2^10)        1024
------- = ------   => X = ------- * 115200 = 58.9824 = 59
115200      X             2000000

2000000     1024           59
------- = ------  => B = ------- * 2000000 = 115234.375 = 115234
    B       59            1024

Error rate   (115234 - 115200)/115200 * 100 = 0.000295139 * 100 = 0.03%
```

If the core clock is 25MHz and M = 2^16 = 65536:
```
25000000    M(2^16)        65536
-------- = ------  => X = ------- * 115200 = 301.989888 = 302
115200       X            25000000

25000000   65536           302
------- = ------  => B = ------- * 25000000 = 115203.857421875 = 115204
   B        302            65536

Error rate = (115204 - 115200)/115204 = 0.000034721 = 0.00003 = 0.003%

```
This means we need a 17 bit register and a tick is picked off from the reg[16]: assign tick = acc[16];

## Misc
- https://codereview.stackexchange.com/questions/115003/verilog-uart-transmitter
