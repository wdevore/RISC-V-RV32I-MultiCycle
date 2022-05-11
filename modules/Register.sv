`default_nettype none

`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// --------------------------------------------------------------------------
// Standard register with Load
// --------------------------------------------------------------------------

module Register
#(
    parameter DATA_WIDTH = 32)
(
    input  logic clk_i /*verilator public*/,                     // Processor domain clock
    input  logic ld_i /*verilator public*/, // Active Low
    input  logic [DATA_WIDTH-1:0] data_i /*verilator public*/,  // Input
    output logic [DATA_WIDTH-1:0] data_o /*verilator public*/  // Output
);
/*verilator public_module*/

// The register acts only the negative edge of the clock
always_ff @(negedge clk_i) begin
    if (~ld_i) begin
        // `ifdef SIMULATE
        //     $display("Register Load: (%b) %h", data_i, data_i);
        // `endif
        data_o <= data_i;
    end
    else 
        data_o <= data_o;
end

endmodule
