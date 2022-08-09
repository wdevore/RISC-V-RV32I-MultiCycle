`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// CPOL = 1, CPHA = 1
`define SPI_MODE 0
// 6.25 MHz
`define CLKS_PER_HALF_BIT 4
// 25 MHz
`define MAIN_CLK_DELAY 2
// 2 bytes per chip select
`define MAX_BYTES_PER_CS 2
// Adds delay between bytes
`define CS_INACTIVE_CLKS 10

module Top (
    // Signals from Cpp testbench
    input  logic r_Clk,
    input  logic r_Rst_L,
    input  logic [7:0] r_Master_TX_Byte,
    input  logic r_Master_TX_DV,
    input  logic [1:0] r_Master_TX_Count,
    output logic w_Master_TX_Ready,
    output logic w_SPI_CS_n
);

logic w_SPI_Clk;
logic w_SPI_MOSI;

// Master Specific
logic w_Master_RX_DV;
logic [7:0] w_Master_RX_Byte;
logic [$clog2(`MAX_BYTES_PER_CS+1)-1:0] w_Master_RX_Count;

// SPI master instance
SPIMaster #(
    .SPI_MODE(`SPI_MODE),
    .CLKS_PER_HALF_BIT(`CLKS_PER_HALF_BIT),
    .MAX_BYTES_PER_CS(`MAX_BYTES_PER_CS),
    .CS_INACTIVE_CLKS(`CS_INACTIVE_CLKS)
) SPI_Master_Inst (
    // Control/Data Signals,
    .i_Rst_L(r_Rst_L),     // FPGA Reset
    .i_Clk(r_Clk),         // FPGA Clock

    // TX (MOSI) Signals
    .i_TX_Count(r_Master_TX_Count),   // Number of bytes per CS
    .i_TX_Byte(r_Master_TX_Byte),     // Byte to transmit
    .i_TX_DV(r_Master_TX_DV),         // Data Valid Pulse 
    .o_TX_Ready(w_Master_TX_Ready),   // Transmit Ready for Byte

    // RX (MISO) Signals
    .o_RX_Count(w_Master_RX_Count), // Index of RX'd byte
    .o_RX_DV(w_Master_RX_DV),       // Data Valid pulse (1 clock cycle)
    .o_RX_Byte(w_Master_RX_Byte),   // Byte received on MISO

    // SPI Interface
    .o_SPI_Clk(w_SPI_Clk),
    .i_SPI_MISO(w_SPI_MOSI),
    .o_SPI_MOSI(w_SPI_MOSI),
    .o_SPI_CS_n(w_SPI_CS_n)
);


endmodule

