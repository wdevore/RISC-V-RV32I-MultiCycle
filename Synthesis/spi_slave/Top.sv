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
    output logic [3:0] pm6b,
    // output logic [3:0] pm4b,
    // output logic [3:0] pm4a,
    output logic [3:0] pm5b
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

// assign pm4b[0] = MOSI_sync;  // LA 4
// assign pm4b[1] = SClk_sync;  // LA 5
// assign pm4b[2] = SClk_fallingedge;  // LA 6
// assign pm4b[3] = SClk_risingedge;  // LA 7

// assign pm4a[0] = final_fall;  // LA 8
// assign pm4a[1] = pattern1;  // LA 9
// assign pm4a[2] = reset_cnt;  // LA 10
// assign pm4a[3] = data_select[0];  // LA 11

assign pm5b[0] = 1'b1;//data_select[1];  // LA 12
assign pm5b[1] = state[0];// LA 13
assign pm5b[2] = state[1];// LA 14
assign pm5b[3] = state[2];// LA 15

// -----------------------------------------------------------------
// Slave that interacts with Pico. It detects certain sequences and
// responds
// -----------------------------------------------------------------
logic [2:0] state;

SPISlave slave (
    .sysClk(clk),
    .spiClk(pm6a[1]),
    .mosi(pm6a[0]),
    .cs(pm6a[2]),
    .miso(pm6b[0]),

    // .state(state)

);

// Functioning indicator
logic [24:0] count;
assign led = count[22];

always_ff @(posedge clk) begin
	count <= count + 1;
end

endmodule

