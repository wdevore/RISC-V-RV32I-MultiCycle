`default_nettype none

module Mux2
#(
    parameter DATA_WIDTH = 32
)
(
   input wire  logic select_i,
   input wire  logic [DATA_WIDTH-1:0] data0_i,  // Data input
   input wire  logic [DATA_WIDTH-1:0] data1_i,  // Data input
   output wire logic [DATA_WIDTH-1:0] data_o    // Output
);

assign data_o = (select_i == 1'b0) ? data0_i : data1_i;

endmodule
