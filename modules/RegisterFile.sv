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

initial begin
    `ifdef POPULATE_REGISTERS
        $display("------Populating RegisterFile----");
        bank[0] =  32'h00000002;       // Simple data for testing
        bank[1] =  32'h00000004;
        bank[2] =  32'h00000006;
        bank[3] =  32'h00000008;
        bank[4] =  32'h00000028;   // x4
        bank[5] =  32'h0000000B;
        bank[6] =  32'h0000000C;
        bank[7] =  32'h0000000D;
        bank[8] =  32'h0000000E;
        bank[9] =  32'h0000000F;
        bank[10] = 32'h00000012;   // x10
        bank[11] = 32'h00000014;
        bank[12] = 32'h00000016;
        bank[13] = 32'h00000018;
        bank[14] = 32'hBEEFDEAD;
        bank[15] = 32'h0000001B;
        bank[16] = 32'h0000001C;
        bank[17] = 32'h0000001E;
        bank[18] = 32'h0000001F;
        bank[19] = 32'h00000021;
        bank[20] = 32'h00000022;
        bank[21] = 32'h00000023;
        bank[22] = 32'h00000024;
        bank[23] = 32'h00000025;
        bank[24] = 32'h00000026;
        bank[25] = 32'h00000027;
        bank[26] = 32'h00000028;
        bank[27] = 32'h00000029;
        bank[28] = 32'h0000002A;
        bank[29] = 32'h0000002B;
        bank[30] = 32'h0000002C;
        bank[31] = 32'h0000002D;
    `endif
end

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
