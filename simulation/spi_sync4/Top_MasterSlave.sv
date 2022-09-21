`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// This directly creates and controls a Master and Slave.
// Make **sure** you use the Top_MasterSlave.sv AND SPI_tb_MasterSlave.cpp
// And adjust the makefile accordingly.

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

logic m_mosi_s;  // Master out to Slave in
logic s_miso_m;
logic spiClk_o;

// -----------------------------------------------------------
// IO Module
// -----------------------------------------------------------
// IOModule io (
//     .sysClk(),          // system domain clock
//     .reset(),           // Reset for a new Trx (active low)
//     .send(),            // Initiate data transmission (active low)

//     // Data IO
//     .tx_addr(),         // Address of tx buffer byte
//     .tx_byte(),         // Data to write to tx buffer
//     .rx_addr(),         // Address of rx buffer byte
//     .rx_byte(),         // Data read from rx buffer

//     // SPI IO
//     .spiClk(),    // SPI Clock output
//     .mosi(),      // output (1 bit at a time) routed to Slave
//     .miso(),      // Bit from Slave
//     .cs()         // CS directed at Slave
// );

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

