`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// Half duplex
// Transmits N bytes from a buffer and receives M bytes into a buffer.
// It uses a SPIMaster to perform the bit transmissions.
// IOModule does not contain a buffer. It accesses each byte from Input parameter.

// When both byte-counts reach zero then the IO Trx is complete
module IOModule
(
    input  logic sysClk,                // system domain clock
    input  logic reset,
    input  logic send,                  // Transmit data (active low)
    input  logic [3:0] tx_byte_cnt,     // How many bytes to send
    input  logic [7:0] byte_to_send,    // Data to send based on Index
    output logic tx_byte_index,         // Index for byte to Tx
    input  logic [3:0] rx_byte_cnt,     // How many bytes to receive
    output logic rx_byte_index,         // Index of byte received
    output logic [7:0] byte_received,   // Data received
    output logic wr_byte                // Signal to store byte (active low)
);

/*verilator public_module*/



endmodule

