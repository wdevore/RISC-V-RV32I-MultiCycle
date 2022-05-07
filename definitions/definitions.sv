`define RTYPE   7'b0110011
`define ITYPE   7'b0010011
`define ITYPE_L 7'b0000011
`define ITYPE_J 7'b1100111
`define ITYPE_E 7'b1110011
`define STYPE   7'b0100011
`define BTYPE   7'b1100011
`define UTYPE_L 7'b0110111
`define UTYPE_A 7'b0010111
`define JTYPE   7'b1101111

`define SLLI 3'b001
// both srli and srai
`define SRLI 3'b101

`define BYTE_SIZE     2'b00
`define HALFWORD_SIZE 2'b01
`define WORD_SIZE     2'b10

`define AMuxSelectSize 2
`define BMuxSelectSize 2
`define ImmSelectSize 3
`define PCSelectSize 2
`define WDSelectSize 2
`define ALUOpSize 6
`define FlagSize 4

`define SrcZero 32'b0
`define SrcFour 32'h00000004
`define SrcUnused 32'bx
`define SrcUnConnected 32'bx

`define MEM_BUSY 1'b1
`define MEM_NOT_BUSY 1'b0

`define ALWAYS_LOAD 1'b0

// VNCZ
// 3210
`define FLAG_ZERO     0
`define FLAG_CARRY    1
`define FLAG_NEGATIVE 2
`define FLAG_OVERFLOW 3
