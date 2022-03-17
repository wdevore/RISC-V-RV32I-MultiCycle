`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

module IRModule
#(
    parameter DATA_WIDTH = 32)
(
   input logic clk_i,
   input logic reset_i
);

/*verilator public_module*/

// logic [DATA_WIDTH-1:0] instruction = 32'h04082983;  // lw x19, x16,  d16

// localparam AMuxSelectSize = 2;
// localparam BMuxSelectSize = 2;
// localparam ImmSelectSize = 3;
// localparam PCSelectSize = 2;
// localparam WDSelectSize = 2;
// localparam ALUOpSize = 3;

// address d1023 = 0x3FF word-address = 0xFFC byte-address
// word 0000_0000_0000_0000_0000_0011_1111_1111
// byte 0000_0000_0000_0000_0000_1111_1111_1100
localparam ResetVector = 32'h00000FFC; // Reset Vector 0x3FF word = 0xFFC byte address

// --++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++
// Wires connecting modules
// --++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++
logic cm_to_ir_ld /*verilator public*/;   // CM to IR

logic cm_to_pc_ld;
logic [`PCSelectSize-1:0] cm_to_pc_src;    // CM to PC_Src
logic [DATA_WIDTH-1:0] pc_out;
logic [DATA_WIDTH-1:0] pc_src_out;        // pc_src mux to PC_Mux

logic cm_to_addr_src;
logic [DATA_WIDTH-1:0] addr_mux_to_pmmu;
logic [DATA_WIDTH-1:0] pmmu_out;

logic cm_to_mem_wr;
logic cm_to_mem_rd;

logic [2:0] funct3 = ir_out[14:12]; //3'b010;
logic cm_to_rst_src;
logic [2:0] rst_src_out;

logic rg_wr;
logic [`AMuxSelectSize-1:0] a_src;
logic [`BMuxSelectSize-1:0] b_src;
logic [`ImmSelectSize-1:0] imm_src;
logic alu_id;
logic [`ALUOpSize-1:0] alu_op;
logic jal_id;
logic [`WDSelectSize-1:0] wd_src;
logic [DATA_WIDTH-1:0] ir_out /*verilator public*/;

logic [DATA_WIDTH-1:0] wd;
logic mwr;
logic mem_rdy;

// Signal sequencer
ControlMatrix matrix
(
   .clk_i(clk_i),
   .ir_i(ir_out),
   .reset_i(reset_i),
   .mem_busy_i(1'b0),
   .ir_ld_o(cm_to_ir_ld),
   .pc_ld_o(cm_to_pc_ld),
   .pc_src_o(cm_to_pc_src),
   .mem_wr_o(cm_to_mem_wr),
   .mem_rd_o(cm_to_mem_rd),
   .addr_src_o(cm_to_addr_src),
   .rst_src_o(cm_to_rst_src),
   .rg_wr_o(rg_wr),
   .a_src_o(a_src),
   .b_src_o(b_src),
   .imm_src_o(imm_src),
   .alu_id_o(alu_id),
   .alu_op_o(alu_op),
   .jal_id_o(jal_id),
   .wd_src_o(wd_src)
);

// Memory management
Pmmu pmmu
(
   .clk_i(clk_i),
   .funct3(rst_src_out),
   .byte_addr_i(addr_mux_to_pmmu),
   .wd_i(wd),
   .mwr_i(cm_to_mem_wr),
   .mrd_i(cm_to_mem_rd),
   .rd_o(pmmu_out),
   .mem_rdy_o(mem_rdy)
);

// PC_Src mux
Mux4 #(.DATA_WIDTH(DATA_WIDTH)) pc_mux
(
    .select_i(cm_to_pc_src),
    .data0_i(32'h00000001),
    .data1_i(32'h00000002),
    .data2_i(ResetVector),
    .data3_i(pmmu_out),
    .data_o(pc_src_out)
);

Mux2 #(.DATA_WIDTH(DATA_WIDTH)) addr_mux
(
    .select_i(cm_to_addr_src),
    .data0_i(pc_out),
    .data1_i(32'h00000005),
    .data_o(addr_mux_to_pmmu)
);

// Reset sequence mux connected to pmmu
Mux2 #(.DATA_WIDTH(3)) rst_mux
(
    .select_i(cm_to_rst_src),
    .data0_i(funct3),
    .data1_i(3'b010),
    .data_o(rst_src_out)
);

// PC register
Register pc
(
   .clk_i(clk_i),
   .ld_i(cm_to_pc_ld),
   .data_i(pc_src_out),
   .data_o(pc_out)
);

// IR register
Register ir
(
   .clk_i(clk_i),
   .ld_i(cm_to_ir_ld),
   .data_i(pmmu_out),
   .data_o(ir_out)
);

endmodule
