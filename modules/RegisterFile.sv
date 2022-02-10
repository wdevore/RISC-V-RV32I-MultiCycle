`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// --------------------------------------------------------------------------
// Register file 32x32
// --------------------------------------------------------------------------

module RegisterFile
#(
    parameter DATA_WIDTH = 32,
    parameter WORDS = 32,
    parameter SELECT_SIZE = 5)   // 5 bits = 32 = WORDS
(
    input  logic clk_i,
    input  logic reg_we_i,                      // Write = Active Low
    input  logic [DATA_WIDTH-1:0] data_i,        // Data input
    input  logic [SELECT_SIZE-1:0] reg_dst_i,    // Reg destination select
    input  logic [SELECT_SIZE-1:0] reg_srcA_i,   // Source #1 select
    input  logic [SELECT_SIZE-1:0] reg_srcB_i,   // Source #2 select
    output logic [DATA_WIDTH-1:0] srcA_o,        // Source 1 output
    output logic [DATA_WIDTH-1:0] srcB_o         // Source 2 output
);

// The Registers
//     # of bits          # of registers
logic [DATA_WIDTH-1:0] bank [0:WORDS-1] /*verilator public*/;

always @(negedge clk_i) begin
    // RISC-V Reg 0 is always Zero
    if (~reg_we_i && reg_dst_i != 0) begin
        bank[reg_dst_i] <= data_i;

        `ifdef SIMULATE
            $display("%d Write Reg File DIn: %h, Reg: ", $stime, data_i, reg_dst_i);
        `endif
    end
end

// Source outputs
// RISC-V x0 is always returns Zero
assign srcA_o = reg_srcA_i == 0 ? 0 : bank[reg_srcA_i];
assign srcB_o = reg_srcB_i == 0 ? 0 : bank[reg_srcB_i];

endmodule
