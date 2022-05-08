`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

module Mux2
#(
    parameter DATA_WIDTH = 32
)
(
   input  logic select_i /*verilator public*/,
   input  logic [DATA_WIDTH-1:0] data0_i,  // Data input
   input  logic [DATA_WIDTH-1:0] data1_i,  // Data input
   output logic [DATA_WIDTH-1:0] data_o /*verilator public*/   // Output
);

/*verilator public_module*/
// You need to add the above Verilator Language Extension so that
// it will be exposed in the RangerRisc verilator code.

assign data_o = (select_i == 1'b0) ? data0_i : data1_i;

endmodule
