`default_nettype none

// --------------------------------------------------------------------------
// Register file 32x32
// --------------------------------------------------------------------------

module RegisterFile
#(
    parameter DATA_WIDTH = 32,
    parameter WORDS = 32,
    parameter SELECT_SIZE = 5)   // 5 bits = 32 = WORDS
(
    input  wire logic clk_i,
    input  wire logic reg_we_ni,                      // Write = Active Low
    input  wire logic [DATA_WIDTH-1:0] data_i,        // Data input
    input  wire logic [SELECT_SIZE-1:0] reg_dst_i,    // Reg destination select
    input  wire logic [SELECT_SIZE-1:0] reg_srcA_i,   // Source #1 select
    input  wire logic [SELECT_SIZE-1:0] reg_srcB_i,   // Source #2 select
    output wire logic [DATA_WIDTH-1:0] srcA_o,        // Source 1 output
    output wire logic [DATA_WIDTH-1:0] srcB_o         // Source 2 output
);

// The Registers
//     # registers           # of cells
reg [DATA_WIDTH-1:0] bank [(1<<WORDS)-1:0];

always @(posedge clk_i) begin
    if (~reg_we_ni) begin
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
