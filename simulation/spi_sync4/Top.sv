`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// Top creates an IOModule.

module Top (
    input logic  Rst_i_n,      // System Reset
    input logic  pllClk_i,     // System High Freq Clock (PLL)

    // Master
    input  logic send /*verilator public*/,
    output logic ready,
    output logic byte_sent,
    input  logic [7:0] byte_to_slave,   // Data from Master to Slave
    input  logic [7:0] byte_to_master   // Data to send from Slave to Master
);

logic [7:0] byte_from_slave;
logic [7:0] byte_from_master;

// -----------------------------------------------------------
// wires and buses
// -----------------------------------------------------------
logic m_sclk_s;  // Master sclk to slave
logic m_mosi_s;  // Master out to Slave in
logic m_cs_s;    // Master CS/SS to slave

logic s_miso_m;
logic spiClk_o;

// -----------------------------------------------------------
// Master
// -----------------------------------------------------------

SPIMaster master (
    .sysClk(pllClk_i),
    .sClk(spiClk_o),
    .reset(Rst_i_n),
    .tx_en(send),
    .mosi(m_mosi_s),
    .miso(s_miso_m),
    .tx_byte(byte_to_slave),
    .byte_tx_complete(byte_sent),
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

