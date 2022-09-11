`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// The Slave module is just for testing. 
// This module will typically ...

// Half duplex
// Transmits N bytes from a buffer and receives M bytes into a buffer.
// It uses a SPIMaster to perform the bit transmissions.
// When both byte-counts reach zero then the IO Trx is complete
//
// Call *reset* first
// 
module IOModule
(
    input  logic sysClk,                // system domain clock
    input  logic reset,                 // Reset for a new Trx (active low)
    input  logic send,                  // Initiate data transmission (active low)
    // Data IO
    input  logic [7:0] tx_byte,         // Data to write to tx buffer
    input  logic [3:0] rx_index,        // Address of rx buffer byte
    output logic [7:0] rx_byte          // Data read from rx buffer
    // SPI IO
    output logic clk,            // SPI Clock output
    output logic mosi,           // output (1 bit at a time) routed to Slave
    input  logic miso,           // Bit from Slave
    output logic cs,             // CS directed at Slave
);

/*verilator public_module*/

// How many SPI clocks between each byte.
logic [3:0] gapCnt;

// ------------------------------------------------------------------------
// IO buffers
// ------------------------------------------------------------------------
logic [3:0] tx_addr;
logic [3:0] rx_addr;

// Send buffer (16 bytes)
logic [7:0] tx_buf [3:0] /*verilator public*/;

always_ff @(posedge sysClk) begin
    if (~reset) begin
        tx_addr <= 0;
    end
    else if (~tx_wr) begin
        tx_buf[tx_addr] <= tx_byte;
    end
end

// Receive buffer (16 bytes)
logic [7:0] rx_buf [3:0] /*verilator public*/;

always_ff @(posedge sysClk) begin
    if (~reset) begin
        rx_addr <= 0;
    end
    else if (~rx_wr) begin
        rx_buf[rx_addr] <= byte_received;
    end
end

// ------------------------------------------------------------------------
// SPI module
// ------------------------------------------------------------------------
// We feed one byte at a time into the SPI module.

SPIMaster master (
    .sysClk(sysClk),
    .sClk(clk),                     // Routed out of the module.
    .reset(reset),
    .tx_en(send),                   // Remains active as long as there are bytes to transmit.
    .mosi(mosi),
    .miso(miso),
    .tx_byte(byte_to_slave),
    .byte_tx_complete(byte_sent),
    .rx_byte(byte_from_slave)
);

endmodule

