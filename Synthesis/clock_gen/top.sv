
module top (
  input logic clk,
  output logic led,
  output logic [11:0] tile2
);
    
ClockGen clock (
  .clk(clk),
  .led(led),
  .gen_clk(tile2[0])
);
    
endmodule
