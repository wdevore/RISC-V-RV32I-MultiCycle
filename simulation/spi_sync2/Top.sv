`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// This example has two SPI devices "master" and "slave".
// Data is sent between both.
// The slave's Tx data is purposefully shifted to simulate a
// different clock domain.

module Top (
    input logic  Rst_i_n,      // System Reset
    input logic  pllClk_i,     // System High Freq Clock (PLL)

    // Master
    input  logic send_i_n /*verilator public*/,
    output logic ready,
    input  logic [7:0] byte_to_slave,   // Data from Master to Slave
    input  logic [7:0] byte_to_master   // Data to send from Slave to Master
);

logic [2:0] bitCnt;
logic tx_complete;
logic [7:0] byte_from_slave;
logic [7:0] byte_from_master;

// -----------------------------------------------------------
// SPI clocks
// -----------------------------------------------------------
logic [3:0] spiMCnt; // 1/Nth PLL
logic [3:0] spiSCnt = 4'b0001; // delayed by 1 PLL cycle
logic sysMstClk;
logic sysSlvClk;

// bit 0 = 1/2 sysClk
// bit 1 = 1/4
// bit 2 = 1/8
// bit 3 = 1/16

assign sysMstClk = spiMCnt[1];
assign sysSlvClk = spiSCnt[1];

assign ready = m_ss_s;

// ---------------------------------------------------
// Simulation
// ---------------------------------------------------
initial begin
    $display("Top Sim init");
    m_ss_s = 1'b1;
end


// -----------------------------------------------------------
// wires and buses
// -----------------------------------------------------------
logic m_sclk_s;  // Master sclk to slave
logic m_mosi_s;  // Master out to Slave in
logic m_cs_s;    // Master CS/SS to slave

logic s_miso_m;
logic m_ss_s;
// logic slave_ready;
logic slave_transmitting;

// -----------------------------------------------------------
// Master
// -----------------------------------------------------------

SPIMaster master (
    .sysClk_i(sysMstClk),
    .reset_i(Rst_i_n),
    // .ready_o(ready),
    .send_i_n(send_i_n),
    .ss_o_n(m_ss_s),
    .mosi_o(m_mosi_s),
    .miso_i(s_miso_m),
    .spiClk_o(m_sclk_s),
    .byte_to_send_i(byte_to_slave),
    .byte_received_o(byte_from_slave),
    .tx_complete_o(tx_complete)
);

SPISlave slave (
    .sysClk_i(sysSlvClk),
    .reset_i(Rst_i_n),
    // .ready_o(slave_ready),
    .transmitting_o(slave_transmitting),
    .mosi_i(m_mosi_s),
    .miso_o(s_miso_m),
    .sclk_i(m_sclk_s),
    .ss_i_n(m_ss_s),
    .byte_to_send_i(byte_to_master),
    .byte_received_o(byte_from_master),
    .tx_complete_o(tx_complete)
);

always_ff @(posedge pllClk_i) begin
    spiMCnt <= spiMCnt + 4'b0001;
    spiSCnt <= spiSCnt + 4'b0001;
end

endmodule

