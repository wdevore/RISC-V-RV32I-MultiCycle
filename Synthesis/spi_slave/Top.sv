`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// Top interfaces with the fpga

`define TX_BYTES 4
`define RX_BYTES 4

module Top (
    input  logic clk,       // 25MHz of fpga

    output logic led,       // Operation indicator
    output logic [5:0] blade1,

    // SPI from Pico via Pmod6(a,b) on the BlackiceNxt.
    // "a" is on the "top" row (i.e. farthest from the IceLogicBus plane)
    // "b" is the bottom row.
    // Ground = (Orange)
    // pm6a[0] = spiClk (in) = From Pico = GP18 (Red)
    // pm6a[1] = mosi (in)   = From Pico = Tx = GP19 (Brown)
    // pm6a[2] = cs (in)     = From Pico = GP17 (Yellow)
    input  logic [3:0] pm6a,
    // pm6b[0] = miso (out)  = To Pico = Rx = GP16 (Green)
    output logic [3:0] pm6b
);

// Functioning indicator
logic [24:0] count;
assign led = count[22];

//     ___________ 
//   A|+.-.3.2.1.0|
//   B|+.-.3.2.1.0|
//     ----------- 

assign blade1[0] = 1'b1;//pm6a[0]; // SPI clock (LED Red 1)
assign blade1[1] = 1'b1;//pm6a[1]; // MOSI (LED Red 2)
assign blade1[2] = 1'b1;//pm6a[2]; // /SS (LED Yellow 1)
assign blade1[3] = 1'b1;
assign blade1[4] = 1'b1;//pm6b[0]; // MISO (LED Green 1)
assign blade1[5] = 1'b1;//byte_sent;

assign pm6b[1] = 1'b0;
assign pm6b[2] = 1'b0;
assign pm6b[3] = 1'b0;

// -----------------------------------------------------------------
// Slave that interacts with Pico. It detects certain sequences and
// responds
// -----------------------------------------------------------------

SPISlave slave (
    .sysClk(clk),
    .spiClk(pm6a[1]),
    .mosi(pm6a[0]),
    .cs(pm6a[2]),
    .miso(pm6b[0])
);

// Functioning indicator
logic [24:0] count;
assign led = count[22];

always_ff @(posedge clk) begin
	count <= count + 1;
end

endmodule

