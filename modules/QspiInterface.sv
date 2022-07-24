`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// This module is for marshalling data from the STM to the FPGA
// via the Quad SPI interface

// Data from the STM32 is 4 bits = 1 nibble = Quad

module QspiInterface
#(
    parameter ADDR_WIDTH = 13,
    parameter DATA_WIDTH = 8
)
(
   input  logic select_i /*verilator public*/,
   input  logic [DATA_WIDTH-1:0] data0_i,  // Data input
   input  logic [DATA_WIDTH-1:0] data1_i,  // Data input
   output logic [DATA_WIDTH-1:0] data_o /*verilator public*/   // Output
);

/*verilator public_module*/



endmodule
