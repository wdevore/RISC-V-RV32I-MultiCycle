# Build
- $make

# 7Seg tile
bits 0,1,2 are the common anodes for each digit. They are negative logic meaning a zero enables the digit and any zeros applied to the other pins lights up those sub segments.

You need to use a scanning techique to show all digits.