
This is a UART synthesis of both a transmitter and receiver.
See simulation readme.md for further details

# Summary
- protocol: 8N1
- baud: 115200

# Minicom
Turn off "flow control" [Ctrl-a x o]

```$ minicom -b 115200 -o -D /dev/ttyUSB0```
