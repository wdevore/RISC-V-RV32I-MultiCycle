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
    output logic [11:0] tile1,
    output logic [3:0] pm4b,
    output logic [3:0] pm4a,
    output logic [3:0] pm5b
);

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

assign pm4b[0] = MOSI_sync;  // LA 4
assign pm4b[1] = SClk_sync;  // LA 5
assign pm4b[2] = SClk_fallingedge;  // LA 6
assign pm4b[3] = SClk_risingedge;  // LA 7

assign pm4a[0] = final_fall;  // LA 8
assign pm4a[1] = pattern1;  // LA 9
assign pm4a[2] = reset_cnt;  // LA 10
assign pm4a[3] = data_select[0];  // LA 11

assign pm5b[0] = data_select[1];  // LA 12
assign pm5b[1] = state[0];// LA 13
assign pm5b[2] = state[1];// LA 14
assign pm5b[3] = state[2];// LA 15

// -----------------------------------------------------------------
// Slave that interacts with Pico. It detects certain sequences and
// responds
// -----------------------------------------------------------------
logic [7:0] rx_byte;
logic [7:0] rx_bufI;
logic [1:0] bufCnt;
logic byte_sent;
logic final_fall;
logic SClk_fallingedge;
logic SClk_risingedge;
logic SClk_sync;
logic MOSI_sync;
logic reset_cnt;
logic [2:0] state;
logic [1:0] data_select;
logic bitFlag;
logic [1:0] current_data_select;
logic cds_loaded;
logic pattern1;
logic [7:0] data_out;

SPISlave slave (
    .sysClk(clk),
    .spiClk(pm6a[1]),
    .mosi(pm6a[0]),
    .cs(pm6a[2]),
    .miso(pm6b[0]),

    .rx_byte(rx_byte),
    .bufCnt(bufCnt),
    .rx_bufI(rx_bufI),
    .byte_sent(byte_sent),
    .final_fall(final_fall),
    .SClk_fallingedge(SClk_fallingedge),
    .SClk_risingedge(SClk_risingedge),
    .SClk_sync(SClk_sync),
    .MOSI_sync(MOSI_sync),
    .reset_cnt(reset_cnt),
    .state(state),
    .data_select(data_select),
    .bitFlag(bitFlag),
    .current_data_select(current_data_select),
    .cds_loaded(cds_loaded),
    .pattern1(pattern1),
    .data_out(data_out)
);

logic [3:0] digitL; // 0x0 -> 0xf
logic [3:0] digitM;
logic [3:0] digitR;

// logic [7:0] x;
// // assign x[11:8] = 4'b1000;
// // assign x[11:8] = rx_bufI[11:8];
// assign x[7:4] = rx_bufI[7:4];
// assign x[3:0] = rx_bufI[3:0];

// assign digitL = (x)       % 16;   // (v/(16**0)) % 16
// assign digitM = (x / 16)  % 16;   // (v/(16**1)) % 16
// assign digitR = (x / 256) % 16;   // (v/(16**2)) % 16

SevenSeg segs(
  .clk(clk),
  .digitL(4'b0000),
  .digitM(data_out[7:4]),
  .digitR(data_out[3:0]),
  .tile1(tile1)
);

logic [3:0] sysClkCnt;

// Functioning indicator
logic [24:0] count;
assign led = count[22];

always_ff @(posedge clk) begin
	count <= count + 1;

    sysClkCnt <= sysClkCnt + 4'b0001;
    if (sysClkCnt == 4'b0101) begin
        sysClkCnt <= 4'b0000;
    end
end

endmodule

