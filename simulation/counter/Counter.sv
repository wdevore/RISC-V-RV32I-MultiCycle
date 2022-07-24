`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

module Counter
(
    input logic clk_i,
    output logic clk_o
);

/*verilator public_module*/

logic [1:0] counter;    // Counts to three
logic ff;

// always_comb begin
// end

always_ff @(negedge clk_i) begin
    if (counter == 2) begin
        counter <= 2'b0;
        ff <= ~ff;
    end
    else begin
        counter <= counter + 1;
    end
end

assign clk_o = ff;

endmodule

