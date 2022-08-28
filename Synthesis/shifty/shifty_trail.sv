
module shifty(
	input  logic clk,
	output logic led,
	output logic [5:0] blade
);

// G  G  O  O  R  R
// 0  0  0  0  0  0

logic [22:0] count;
logic [5:0] shift = 4'b1;

always_ff @(posedge clk) begin
	count <= count + 1;
	if (count[22]) begin
		count <= 0;
		shift <= {~shift[0], shift[5:1]};
	end
end

assign led = count[22];
assign blade = shift;

endmodule
