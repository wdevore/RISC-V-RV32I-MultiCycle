`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

module Top
(
   input logic clk_i
   output logic clk_o
);


/*verilator public_module*/
Counter counter
(
   .clk_i(clk_i),
   .clk_o(clk_o)
);


endmodule

