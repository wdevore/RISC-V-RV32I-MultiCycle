`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// Top creates an IOModule and interfaces with it two buffers accessed by indices.

module Top (
    input logic  Rst_i_n,      // System Reset
    input logic  pllClk_i,     // System High Freq Clock (PLL)

    // Master
    input  logic send /*verilator public*/,
    output logic ready,
    input  logic [7:0] byte_to_slave,   // Data from Master to Slave
    input  logic [7:0] byte_to_master   // Data to send from Slave to Master
);

logic [7:0] byte_from_slave;
logic [7:0] byte_from_master;

// -----------------------------------------------------------
// SPI clocks
// -----------------------------------------------------------
// bit 0 = 1/2 sysClk
// bit 1 = 1/4
// bit 2 = 1/8
// bit 3 = 1/16

// ---------------------------------------------------
// Simulation
// ---------------------------------------------------
// initial begin
// end


// -----------------------------------------------------------
// wires and buses
// -----------------------------------------------------------
logic m_sclk_s;  // Master sclk to slave
logic m_mosi_s;  // Master out to Slave in
logic m_cs_s;    // Master CS/SS to slave

logic s_miso_m;
logic sent;
logic spiClk_o;

// -----------------------------------------------------------
// Master
// -----------------------------------------------------------

SPIMaster master (
    .sysClk(pllClk_i),
    .spiClk_o(spiClk_o),
    .reset(Rst_i_n),
    .tx_en(send),
    .mosi(m_mosi_s),
    .miso(s_miso_m),
    // .miso(m_mosi_s),
    .tx_byte(byte_to_slave),
    .rx_byte(byte_from_slave)
);

SPISlave slave (
    .sysClk(pllClk_i),
    .spiClk(spiClk_o),
    .cs(send),
    .mosi(m_mosi_s),
    .miso(s_miso_m),
    .tx_byte(byte_to_master),
    .rx_byte(byte_from_master)
);

endmodule

