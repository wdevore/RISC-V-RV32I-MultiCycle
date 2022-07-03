// Fibonacci

// 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377,
// 610, 987, 1597, 2584, 4181, 6765, 10946, 17711, 28657,
// 46368, 75025, 121393, 196418, 317811

Main: @000
    add  x1, x0, x0     // 0
    addi x2, x0, 1      // 1
    addi x4, x0, 0x1b   // x4 = 27 = how many
    add  x5, x0, x0     // x5 = 0
Next: @
    add  x3, x1, x2     // next fibonacci #
    add  x1, x2, x0     // x1 = x2
    add  x2, x3, x0     // x2 = x3
    addi x5, x5, 1      // x5++
    blt  x5, x4, @Next
    ebreak              // Halt
RVector: @0C0
    @: Main            // Reset vector
