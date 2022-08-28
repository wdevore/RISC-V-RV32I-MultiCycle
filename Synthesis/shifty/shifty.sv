
module shifty (
	input  logic clk,
	output logic led,
	output logic [5:0] blade
);

logic [21:0] count = 0;
logic [23:0] lcount = 0;
// G  G  O  O  R  R
// 0  0  0  0  0  0
logic [5:0] shifter;
logic state = 0;
logic dir = 0; // 0 = left, 1 = right

// 111110
always_ff @(posedge clk) begin
	count <= count + 1;
	lcount <= lcount + 1;

	case (state)
		1'b0: begin
			// Lattice chips don't guarantee bits being Set
			// on initialization so we need a state to Set them.
			shifter <= 6'b111_110;
			state <= 1'b1;
		end
		1'b1: begin
			if (count[21] == 1'b1) begin
				count[21] <= 0;

				// is bit 4 6'b101_111 = zero
				if (shifter[4] == 1'b0)
					dir <= 1'b1; // switch to right
				else if (shifter[1] == 1'b0) // 6'b111_101
					dir <= 1'b0; // switch to left

				if (dir == 1'b0)
					shifter <= {shifter[4:0], 1'b1}; // left
				else
					shifter <= {1'b1, shifter[5:1]}; // right

				// An explicit shift
				// if (dir == 1'b0) begin
				// 	case (shifter)
				// 		6'b111_110: shifter <= 6'b111_101;
				// 		6'b111_101: shifter <= 6'b111_011;
				// 		6'b111_011: shifter <= 6'b110_111;
				// 		6'b110_111: shifter <= 6'b101_111;
				// 		6'b101_111: shifter <= 6'b011_111;
				// 		6'b011_111: begin
				// 			shifter <= 6'b101_111;
				// 			dir <= 1'b1;
				// 		end
				// 	endcase
				// end
				// else begin
				// 	case (shifter)
				// 		6'b101_111: shifter <= 6'b110_111;
				// 		6'b110_111: shifter <= 6'b111_011;
				// 		6'b111_011: shifter <= 6'b111_101;
				// 		6'b111_101: shifter <= 6'b111_110;
				// 		6'b111_110: begin
				// 			shifter <= 6'b111_101;
				// 			dir <= 1'b0;
				// 		end
				// 	endcase
				// end
			end

		end
	endcase
end

assign led = lcount[23];
assign blade = shifter;

endmodule
