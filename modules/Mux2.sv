`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

module Mux2
#(
    parameter DATA_WIDTH = 32
)
(
   input  logic select_i,
   input  logic [DATA_WIDTH-1:0] data0_i,  // Data input
   input  logic [DATA_WIDTH-1:0] data1_i,  // Data input
   output logic [DATA_WIDTH-1:0] data_o    // Output
);

assign data_o = (select_i == 1'b0) ? data0_i : data1_i;

endmodule
