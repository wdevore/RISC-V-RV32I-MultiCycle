# Microcode

## Reset
This state sequence stays the same. All of the signals it changes are ORed with the respective ROM signals.

## Fetch
This state sequence stays the same. *ir_ld* and *pcp_ld* are not in the ROM.

## Decode
This state calculates the ROM address for the **Execute** state.