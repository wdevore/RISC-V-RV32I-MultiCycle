

module SevenSeg (
	input  logic clk,
	input  logic [3:0] digitL, // High value 0x0 -> 0xf
	input  logic [3:0] digitM, // 0x0 -> 0xf
	input  logic [3:0] digitR, // 0x0 -> 0xf
	output logic [11:0] tile1
);

localparam scan_rate = 19;
logic [24:0] scan_counter = 0;

logic state = 0;

logic [2:0] seg_scan;
logic [3:0] bcd;
logic [6:0] segs;

Decoder seg7(
	.bcd(bcd),
	.seg(segs)
);

always_ff @(posedge clk) begin
	scan_counter <= scan_counter + 1;

	case (state)
		1'b0: begin
			// Lattice chips don't guarantee bits being Set
			// on initialization so we need a state to Set them.
			state <= 1'b1;
			seg_scan <= 3'b110;	// Start scanning on the left digit
		end
		1'b1: begin
			if (scan_counter[scan_rate] == 1'b1) begin
				scan_counter[scan_rate] <= 0;
				case (seg_scan)
					3'b110: begin
						bcd <= digitL;
						seg_scan <= 3'b101;
					end
					3'b101: begin
						bcd <= digitM;
						seg_scan <= 3'b011;
					end
					3'b011: begin
						bcd <= digitR;
						seg_scan <= 3'b110;
					end
				endcase
			end
		end
	endcase
end

assign tile1[3]  = segs[0];     // middle segment of left digit if the decimal point towards the top.
assign tile1[4]  = segs[1];		// lower right
assign tile1[5]  = segs[2];		// bottom
assign tile1[6]  = segs[3];		// top right
assign tile1[7]  = segs[4];		// lower left
assign tile1[9]  = segs[5];		// top
assign tile1[11] = segs[6];		// top left

assign tile1[8] = 1'b1;		// decimal point
assign tile1[10] = 1'b1;    // ??

assign tile1[0] = seg_scan[0];		// Left digit
assign tile1[2] = seg_scan[1];		// Middle digit
assign tile1[1] = seg_scan[2];		// Right digit

endmodule
