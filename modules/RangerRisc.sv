`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

module RangerRisc
(
   input  logic clk_i,
   input  logic [DATA_WIDTH-1:0] data0_i,  // Data input
   input  logic [DATA_WIDTH-1:0] data1_i,  // Data input
   output logic [DATA_WIDTH-1:0] data_o    // Output
);


endmodule
