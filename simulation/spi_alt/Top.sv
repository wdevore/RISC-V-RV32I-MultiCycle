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
    input  logic SPI_CS_i_n,   // Chip select SSEL

    input  logic [7:0] byte_to_slave,   // Data from Master to Slave
    input  logic [7:0] byte_from_slave, // Data from Slave to Master

    // We use the LSB of the data received to control an LED
    output logic LED_o
);

logic [2:0] bitCnt;

// -----------------------------------------------------------
// SPI clocks
// -----------------------------------------------------------
logic [3:0] spiMCnt; // 1/Nth PLL
logic [3:0] spiMSpiCnt;
logic [3:0] spiSCnt;
logic sysMstClk;
logic masSPIClk;
logic sysSlvClk;    // delayed by 1 PLL cycle

// bit 0 = 1/2 sysClk
// bit 1 = 1/4
// bit 2 = 1/8
// bit 3 = 1/16

assign sysMstClk = spiMCnt[1];
assign sysSlvClk = spiSCnt[1];
assign masSPIClk = spiMSpiCnt[2];

// -----------------------------------------------------------
// wires and buses
// -----------------------------------------------------------
logic m_sclk_s;  // Master sclk to slave
logic m_mosi_s;  // Master out to Slave in
logic s_miso_m;  // Slave out to Master in
logic m_cs_s;    // Master CS/SS to slave

// -----------------------------------------------------------
// Master
// -----------------------------------------------------------
logic [7:0] master_byte_rx;
logic master_bit_rx;

SPIProtocol master (
    .sysClk_i(sysMstClk),
    .SPI_Clk_i(SPI_Clk_i),

    .SPI_CS_i_n(SPI_CS_i_n),
    
    .SPI_MOSI_i(byte_to_slave[bitCnt]), // Bit sent out
    .SPI_MISO_o(s_miso_m),              // Bit received in

    .byte_received_o(byte_received_o),
    .LED_o(LED_o)
);

// -----------------------------------------------------------
// Slave
// -----------------------------------------------------------
SPIProtocol slave (
    .sysClk_i(sysSlvClk),

    .SPI_Clk_i(SPI_Clk_i),
    .SPI_CS_i_n(SPI_CS_i_n),
    .SPI_MOSI_i(byte_from_slave[bitCnt]),  // Bit sent out
    .SPI_MISO_o(master_bit_rx),          // Bit received in

    .byte_received_o(byte_received_o),
    .LED_o(LED_o)
);

always_ff @(posedge sysMstClk) begin
    if (~Rst_i_n) begin
        bitCnt <= 3'b111;
    end
    else begin
        if (~SPI_CS_i_n) begin
            // build byte one bit at a time
            master_byte_rx <= {master_byte_rx[6:0], master_bit_rx};
        end
        bitCnt <= bitCnt - 3'b001;
    end
end

always_ff @(posedge pllClk_i) begin
    if (~Rst_i_n) begin
        spiMCnt <= 4'b0001; // Master is ahead 1 cycle
        spiSCnt <= 4'b0000;
        spiMSpiCnt <= 4'b0001;
    end
    else begin
        spiMCnt <= spiMCnt + 4'b0001;
        spiSCnt <= spiSCnt + 4'b0001;
        spiMSpiCnt <= spiMSpiCnt + 4'b0001;
    end
end

endmodule

