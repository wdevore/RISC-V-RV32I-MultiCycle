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
    input  wire logic clk_i,                   // Processor domain clock
    input  wire logic ld_ni,                   // Active Low
    input  wire logic [DATA_WIDTH-1:0] data_i, // Input
    output wire logic [DATA_WIDTH-1:0] data_o  // Output
);

// The register acts only the negative edge of the clock
always_ff @(posedge clk_i) begin
    if (~ld_ni) begin
        `ifdef SIMULATE
            $display("%d Register Load: (%b) %h", $stime, data_i, data_i);
        `endif
        data_o <= data_i;
    end
    else 
        data_o <= data_o;
end

endmodule
