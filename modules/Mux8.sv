`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// ----------------------------------------------------
// Currently unused by RangerRisc
// ----------------------------------------------------

module Mux8
#(
    parameter DATA_WIDTH = 32,
    parameter SELECT_SIZE = 3
)
(
   input  logic [SELECT_SIZE-1:0] select_i,
   input  logic [DATA_WIDTH-1:0] data0_i,  // Data input
   input  logic [DATA_WIDTH-1:0] data1_i,  // Data input
   input  logic [DATA_WIDTH-1:0] data2_i,  // Data input
   input  logic [DATA_WIDTH-1:0] data3_i,  // Data input
   input  logic [DATA_WIDTH-1:0] data4_i,  // Data input
   input  logic [DATA_WIDTH-1:0] data5_i,  // Data input
   input  logic [DATA_WIDTH-1:0] data6_i,  // Data input
   input  logic [DATA_WIDTH-1:0] data7_i,  // Data input
   output logic [DATA_WIDTH-1:0] data_o    // Output
);

assign data_o = (select_i == 3'b000) ? data0_i :
                (select_i == 3'b001) ? data1_i :
                (select_i == 3'b010) ? data2_i :
                (select_i == 3'b011) ? data3_i :
                (select_i == 3'b100) ? data4_i :
                (select_i == 3'b101) ? data5_i :
                (select_i == 3'b110) ? data6_i :
                (select_i == 3'b111) ? data7_i :
                {DATA_WIDTH{1'b0}};
endmodule
