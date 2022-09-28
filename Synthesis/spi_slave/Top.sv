`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// Top interfaces with the fpga

`define TX_BYTES 4
`define RX_BYTES 4

module Top (
    input  logic clk,       // 25MHz of fpga

    // SPI from Pico
    input  logic spiClk,
    input  logic mosi,      // From Pico
    input  logic cs,
    output logic miso,      // To Pico

    output logic led,       // Operation indicator
    output logic [5:0] blade1
);

logic [24:0] count;

assign led = count[22];

always_ff @(posedge clk)
	count <= count + 1;

assign blade1[0] = spiClk;
assign blade1[1] = mosi;
assign blade1[2] = cs;
assign blade1[3] = miso;
assign blade1[4] = 1'b1;
assign blade1[5] = 1'b1;

// -----------------------------------------------------------------
// Slave that interacts with Pico. It detects certain sequences and
// responds
// -----------------------------------------------------------------
SPISlave slave (
    .sysClk(clk),
    .spiClk(spiClk),
    .cs(cs),
    .mosi(mosi),
    .miso(miso)
);


endmodule

