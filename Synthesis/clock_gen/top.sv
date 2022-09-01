
module top (
  input logic clk,
  output logic led,
  output logic [3:0] pm6b
);
    
ClockGen clock (
  .clk(clk),
  .led(led),
  .gen_clk(pm6b[3]) 
);

assign pm6b[0] = 1'b1;
assign pm6b[1] = 1'b1;
assign pm6b[2] = 1'b1;
// assign pm6b[3] = 1'b1;

endmodule
