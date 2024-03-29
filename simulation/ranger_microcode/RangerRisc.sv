`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

module RangerRisc
#(
    parameter DATA_WIDTH = 32)
(
   input logic clk_i,

   // ---------------------------------------------
   // Uni directional 8bit parallel data
   // ---------------------------------------------
   output logic [7:0] data_out,
   output logic io_wr,

/* verilator lint_off UNDRIVEN */
`ifdef DEBUG_MODE
   input logic reset_i,
   output logic halt_o
`else
   input logic reset_i,
   input logic irq_i,
   output logic ready_o
`endif
/* verilator lint_on UNDRIVEN */
);

/*verilator public_module*/

// -()-()-()-()-()-()-()-()-()-()-()-()-()-()-()-()-()-()-()-()-()-
//               --------- ResetVector ---------
// -()-()-()-()-()-()-()-()-()-()-()-()-()-()-()-()-()-()-()-()-()-
localparam ResetVector = `RESET_VECTOR; // See Makefile for values

// --++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++
// Wires and Buses connecting modules
// --++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++
logic cm_to_ir_ld /*verilator public*/;   // CM to IR

logic cm_to_pc_ld;
logic [`PCSelectSize-1:0] cm_to_pc_src;
logic [DATA_WIDTH-1:0] pc_out;
logic cm_to_pcp_ld;
logic [DATA_WIDTH-1:0] pc_prior_out;
logic [DATA_WIDTH-1:0] pc_src_out /*verilator public*/;

logic cm_to_addr_src;
logic [DATA_WIDTH-1:0] addr_mux_to_pmmu;
logic [DATA_WIDTH-1:0] pmmu_out /*verilator public*/;

logic cm_to_mem_wr;
logic cm_to_mem_rd;

logic [2:0] funct3 = ir_out[14:12]; //3'b010;
logic cm_to_rst_src;
logic [2:0] rst_src_out;

logic [`AMuxSelectSize-1:0] cm_to_a_src;
logic [`BMuxSelectSize-1:0] cm_to_b_src;

logic [`WDSelectSize-1:0] cm_to_wd_src;
logic [DATA_WIDTH-1:0] ir_out /*verilator public*/;

// verilator lint_off UNUSED
logic mem_rdy;
// verilator lint_on UNUSED

logic [DATA_WIDTH-1:0] a_mux_out;
logic [DATA_WIDTH-1:0] b_mux_out;

logic cm_to_alu_ld;
logic cm_to_alu_flags_ld;
logic [`ALUOpSize-1:0] cm_to_alu_op;
logic [DATA_WIDTH-1:0] alu_imm_out;
logic [DATA_WIDTH-1:0] alu_out;

logic [DATA_WIDTH-1:0] rsa_out;
logic [DATA_WIDTH-1:0] rsb_out;

logic [DATA_WIDTH-1:0] imm_ext_out;

logic cm_to_mdr_ld;
logic [DATA_WIDTH-1:0] mdr_out;

logic cm_to_rg_wr;
logic [4:0] rs1 = ir_out[19:15];
logic [4:0] rs2 = ir_out[24:20];
logic [4:0] rd = ir_out[11:7];
logic [DATA_WIDTH-1:0] rs1_out;
logic [DATA_WIDTH-1:0] rs2_out;
logic [DATA_WIDTH-1:0] wd_src_out;

logic [`FlagSize-1:0] alu_flags_cm;
logic [`FlagSize-1:0] alu_flags_out;

// CSR wires
logic cm_to_rsa_ld;
logic [DATA_WIDTH-1:0] cm_rd_data;

// Signal sequencer
MicroCodeMatrix matrix
(
   .clk_i(clk_i),
   .ir_i(ir_out),
   .reset_i(reset_i),
   .mem_busy_i(`MEM_NOT_BUSY),
   .flags_i(alu_flags_cm),
   .rsa_i(rsa_out),
   .pc_i(pc_out),
   .irq_i(irq_i),
   // .eff_addr_i(addr_mux_to_pmmu),  // Map Effective address
   .ir_ld_o(cm_to_ir_ld),
   .pc_ld_o(cm_to_pc_ld),
   .pcp_ld_o(cm_to_pcp_ld),
   .flags_ld_o(cm_to_alu_flags_ld),
   .pc_src_o(cm_to_pc_src),
   .mem_wr_o(cm_to_mem_wr),      // Active Low
   .mem_rd_o(cm_to_mem_rd),
   .addr_src_o(cm_to_addr_src),
   .rst_src_o(cm_to_rst_src),
   .rg_wr_o(cm_to_rg_wr),
   .a_src_o(cm_to_a_src),
   .b_src_o(cm_to_b_src),
   .alu_ld_o(cm_to_alu_ld),
   .alu_op_o(cm_to_alu_op),
   .wd_src_o(cm_to_wd_src),
   .rsa_ld_o(cm_to_rsa_ld),
   .rd_data_o(cm_rd_data),
`ifdef DEBUG_MODE
   .mdr_ld_o(cm_to_mdr_ld),
   .ready_o(ready_o),
   .halt_o(halt_o)
`else
   .mdr_ld_o(cm_to_mdr_ld)
`endif
   // ---- IO------------------

);

// -------------- Mapped IO -------------------------
// 0x000 -> 0x7ff  = BRAM
// 0x800 -> -      = IO    = 1000_0000_0000
// --------------------------------------------------
// Any attempt to write BRAM at 0x800 or higher is simply
// ignored by BRAM meaning the write signal is held inactive (high).
logic mem_wr;

// Active low
// If either signal is high then writing to memory is disabled.
// Which means we are either not writing or we are writing to IO.
assign mem_wr = cm_to_mem_wr | addr_mux_to_pmmu[11];

// Using "sb" instruction at 0x800 or above means writing to IO.
assign io_wr = ~(~cm_to_mem_wr & addr_mux_to_pmmu[11]); // Active low
assign data_out = rsb_out[7:0];

// Memory management
Pmmu pmmu
(
   .clk_i(clk_i),
   .funct3(rst_src_out),
   .byte_addr_i(addr_mux_to_pmmu),
   .wd_i(rsb_out),
   .mwr_i(mem_wr),
   .mrd_i(cm_to_mem_rd),
   .rd_o(pmmu_out),
   .mem_rdy_o(mem_rdy)
);

// PC_Src mux
Mux8 #(.DATA_WIDTH(DATA_WIDTH)) pc_mux
(
    .select_i(cm_to_pc_src),
    .data0_i(alu_imm_out),
    .data1_i(alu_out),
    .data2_i(ResetVector),
    .data3_i(cm_rd_data),
    .data4_i(pmmu_out),
    .data5_i(`SrcZero),
    .data6_i(`SrcZero),
    .data7_i(`SrcZero),
    .data_o(pc_src_out)
);

// Address mux drives Pmmu address
Mux2 #(.DATA_WIDTH(DATA_WIDTH)) addr_mux
(
    .select_i(cm_to_addr_src),
    .data0_i(pc_out),
    .data1_i(alu_out),
    .data_o(addr_mux_to_pmmu)
);

// Reset sequence mux connected to pmmu
Mux2 #(.DATA_WIDTH(3)) rst_mux
(
    .select_i(cm_to_rst_src),
    .data0_i(funct3),
    .data1_i(3'b010),      // Simulate funct3
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

// PC prior-to-incrementing register
Register pc_prior
(
   .clk_i(clk_i),
   .ld_i(cm_to_pcp_ld),
   .data_i(pc_out),
   .data_o(pc_prior_out)
);

// IR register
Register ir
(
   .clk_i(clk_i),
   .ld_i(cm_to_ir_ld),
   .data_i(pmmu_out),
   .data_o(ir_out)
);

// ALU
ALU #(.DATA_WIDTH(DATA_WIDTH)) alu
(
   .a_i(a_mux_out),
   .b_i(b_mux_out),
   .func_op_i(cm_to_alu_op),
   .y_o(alu_imm_out),
   .flags_o(alu_flags_out)
);

// ALUOut register
Register alu_out_rg
(
   .clk_i(clk_i),
   .ld_i(cm_to_alu_ld),
   .data_i(alu_imm_out),
   .data_o(alu_out)
);

// ALU flags register
Register #(.DATA_WIDTH(`FlagSize)) alu_flags_rg
(
   .clk_i(clk_i),
   .ld_i(cm_to_alu_flags_ld),
   .data_i(alu_flags_out),
   .data_o(alu_flags_cm)
);

// A Src mux drives SrcA ALU
Mux4 #(.DATA_WIDTH(DATA_WIDTH)) a_mux
(
    .select_i(cm_to_a_src),
    .data0_i(pc_out),
    .data1_i(pc_prior_out),
    .data2_i(`SrcZero),
    .data3_i(rsa_out),
    .data_o(a_mux_out)
);

// B Src mux drives SrcB ALU
Mux4 #(.DATA_WIDTH(DATA_WIDTH)) b_mux
(
    .select_i(cm_to_b_src),
    .data0_i(rsb_out),
    .data1_i(`SrcFour),
    .data2_i(imm_ext_out),
    .data3_i(`SrcZero),
    .data_o(b_mux_out)
);

// MDR register
Register mdr
(
   .clk_i(clk_i),
   .ld_i(cm_to_mdr_ld),
   .data_i(pmmu_out),
   .data_o(mdr_out)
);

// Immediate extender
Immediate imm_ext
(
   .ir_i(ir_out),
   .imm_o(imm_ext_out)
);

// Register file
RegisterFile reg_file
(
   .clk_i(clk_i),
   .reg_we_i(cm_to_rg_wr),
   .data_i(wd_src_out),
   .reg_dst_i(rd),
   .reg_srcA_i(rs1),
   .reg_srcB_i(rs2),
   .srcA_o(rs1_out),
   .srcB_o(rs2_out)
);

// RsA register
Register rsa
(
   .clk_i(clk_i),
   .ld_i(cm_to_rsa_ld),
   .data_i(rs1_out),
   .data_o(rsa_out)
);

// RsB register
Register rsb
(
   .clk_i(clk_i),
   .ld_i(`ALWAYS_LOAD),
   .data_i(rs2_out),
   .data_o(rsb_out)
);

// Write back data to WD
Mux4 #(.DATA_WIDTH(DATA_WIDTH)) wd_mux
(
   .select_i(cm_to_wd_src),
   .data0_i(alu_imm_out),
   .data1_i(alu_out),
   .data2_i(mdr_out),
   .data3_i(cm_rd_data),
   .data_o(wd_src_out)
);

endmodule
