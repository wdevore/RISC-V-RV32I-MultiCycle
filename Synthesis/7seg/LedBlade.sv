
module LedBlade (
	input  logic clk,
	output logic led,
	output logic [5:0] blade
);

logic [24:0] count = 0;
logic [23:0] lcount = 0;
logic [11:0] segCount = 0;  // 2^12 = 4096 - 0xFFF

// G  G  O  O  R  R
// 0  0  0  0  0  0
logic state = 0;

always_ff @(posedge clk) begin
	count <= count + 1;
	lcount <= lcount + 1;

	case (state)
		1'b0: begin
			// Lattice chips don't guarantee bits being Set
			// on initialization so we need a state to Set them.
			state <= 1'b1;
		end
		1'b1: begin
			if (count[24] == 1'b1) begin
				count[24] <= 0;
				segCount <= segCount + 1;
			end
		end
	endcase
end

assign led = lcount[23];
assign blade = ~segCount[5:0];

endmodule
