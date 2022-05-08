`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

module Mux4
#(
    parameter DATA_WIDTH = 32,
    parameter SELECT_SIZE = 2
)
(
   input  logic [SELECT_SIZE-1:0] select_i /*verilator public*/,
   input  logic [DATA_WIDTH-1:0] data0_i,  // Data input
   input  logic [DATA_WIDTH-1:0] data1_i,  // Data input
   input  logic [DATA_WIDTH-1:0] data2_i,  // Data input
   input  logic [DATA_WIDTH-1:0] data3_i,  // Data input
   output logic [DATA_WIDTH-1:0] data_o /*verilator public*/    // Output
);

/*verilator public_module*/

assign data_o = (select_i == 2'b00) ? data0_i :
                (select_i == 2'b01) ? data1_i :
                (select_i == 2'b10) ? data2_i :
                (select_i == 2'b11) ? data3_i :
                {DATA_WIDTH{1'b0}};
endmodule

