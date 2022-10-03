`default_nettype none

`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// --------------------------------------------------------------------------
// Standard parallel load shift register
// Shift left on neg-edge.
// Output is Most significant bit.
// --------------------------------------------------------------------------

module ParallelLoadShiftReg
#(
    parameter DATA_WIDTH = 8)
(
    input  logic clk /*verilator public*/,
    input  logic load /*verilator public*/, // Active Low
    input  logic reset, // Active Low
    input  logic shift, // Active Low
    input  logic [DATA_WIDTH-1:0] data_in /*verilator public*/,
    output logic data_out /*verilator public*/
);

/*verilator public_module*/

logic [DATA_WIDTH-1:0] q;

// To make reset and load async add them to the sensativity list
// Ex:
// always @ (negedge clk or negedge reset or negedge load) begin
always @ (negedge clk) begin
    if (~reset)
        q <= {DATA_WIDTH{1'b0}};
    else if (~load)
        q <= data_in;
    else if (~shift)
        q <= q << 1;
end

assign data_out = q[DATA_WIDTH-1];

endmodule
