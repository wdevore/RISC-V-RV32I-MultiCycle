
module ClockGen(
	input  logic clk,
	output logic led,
	output logic gen_clk
);

logic [24:0] count;

assign led = count[22];
assign gen_clk = count[15];

always_ff @(posedge clk)
	count <= count + 1;

endmodule
