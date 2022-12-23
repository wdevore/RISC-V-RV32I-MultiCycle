/**
 * PLL configuration
 *
 * This Verilog module was generated automatically
 * using the icepll tool from the IceStorm project.
 * Use at your own risk.
 *
 * Given input frequency:        25.000 MHz
 * Requested output frequency:   18.000 MHz
 * Achieved output frequency:    17.969 MHz
 */

module pll(
	input  logic clk,
	output logic clock_out,
	output logic locked
);

SB_PLL40_CORE #(
	.FEEDBACK_PATH("SIMPLE"),
	.DIVR(4'b0000),		// DIVR =  0
	.DIVF(7'b0010110),	// DIVF = 22
	.DIVQ(3'b101),		// DIVQ =  5
	.FILTER_RANGE(3'b010)	// FILTER_RANGE = 2
) uut (
	.LOCK(locked),
	.RESETB(1'b1),
	.BYPASS(1'b0),
	.REFERENCECLK(clk),
	.PLLOUTCORE(clock_out)
);

endmodule
