
module top (
  input logic clk,
  output logic led,
  output logic [5:0] blade1,
  output logic [11:0] tile1
);

localparam count_rate = 21;

LedBlade blade(
  .clk(clk),
  .led(led),
  .blade(blade1)
);

logic [3:0] digitL; // 0x0 -> 0xf
logic [3:0] digitM;
logic [3:0] digitR;

logic [31:0] digit_counter = 0;
logic [24:0] counter = 0;

// 999 = 0x3E7

always_ff @(posedge clk) begin
  counter <= counter + 1;
  if (counter[count_rate] == 1'b1) begin
    counter[count_rate] <= 0;
    digit_counter <= digit_counter + 1;
  end
end

SevenSeg segs(
  .clk(clk),
  .digitL(digitL),
  .digitM(digitM),
  .digitR(digitR),
  .tile1(tile1)
);

// BUG: if trying to divide by 10 it cause a toolchain error that take at least
// a minute before it errors out.
// Need to convert (0->999) integer to 3 bcd digits
//
// Another way to do this is using the Double-Dabbler algorithm:
// https://nandland.com/binary-to-bcd-the-double-dabbler/
// https://en.wikipedia.org/wiki/Double_dabble
// assign digitL = (digit_counter / 1)   % 10;   // digit 0, ones place
// assign digitM = (digit_counter / 10)  % 10;   // digit 1, tens place
// assign digitR = (digit_counter / 100) % 10;   // digit 2, hundreds place

assign digitL = (digit_counter)       % 16;   // (v/(16**0)) % 16
assign digitM = (digit_counter / 16)  % 16;   // (v/(16**1)) % 16
assign digitR = (digit_counter / 256) % 16;   // (v/(16**2)) % 16

endmodule
