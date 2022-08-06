`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

module SPIProtocol
(
    input logic  sysClk_i,    // PLL

    // SPI Interface
    input  logic SPI_Clk_i,    // externally generated clock for this protocol
    input  logic SPI_CS_i_n,   // Chip select SSEL
    input  logic SPI_MOSI_i,
    output logic SPI_MISO_o,
    output logic byte_received_o,
    // We use the LSB of the data received to control an LED
    output logic LED_o
);

/*verilator public_module*/

// ----------------------------------------------------
// CDC Sync-ed signals for Spi Clock
// ----------------------------------------------------
logic SCK_risingedge;
logic SCK_fallingedge;
logic SCK_sync;

// We need syncs for spiClk, CS and MOSI
CDCSynchron SPI_Clk_Sync (
    .sysClk_i(sysClk_i),
    .async_i(SPI_Clk_i),
    .sync_o(SCK_sync),
    .rising_o(SCK_risingedge),
    .falling_o(SCK_fallingedge)
);

// ----------------------------------------------------
// CDC Sync-ed signals for CS or SSEL
// ----------------------------------------------------
logic SSEL_startmessage; // message starts at falling edge
logic SSEL_endmessage;   // message stops at rising edge
logic SSEL_sync;
logic SSEL_active;

CDCSynchron SPI_SSEL_Sync (
    .sysClk_i(sysClk_i),
    .async_i(SPI_CS_i_n),
    .sync_o(SSEL_sync),
    .rising_o(SSEL_endmessage),
    .falling_o(SSEL_startmessage)
);

assign SSEL_active = ~SSEL_sync; // SSEL is active low

// ----------------------------------------------------
// CDC Sync-ed signals for MOSI
// ----------------------------------------------------
logic MOSI_risingedge;
logic MOSI_fallingedge;
logic MOSI_data;

CDCSynchron SPI_MOSI_Sync (
    .sysClk_i(sysClk_i),
    .async_i(SPI_MOSI_i),
    .sync_o(MOSI_data),
    .rising_o(MOSI_risingedge),
    .falling_o(MOSI_fallingedge)
);

// ----------------------------------------------
// RX: Master to Slave
// ----------------------------------------------

// We handle SPI in 8-bit format,
// so we need a 3 bits counter to count the bits as they come in
logic [2:0] bitcnt;
logic byte_received;  // high when a byte has been received
logic [7:0] byte_data_received;

always_ff @(posedge sysClk_i) begin
    if (~SSEL_active) begin
        // Start the Rx process
        bitcnt <= 3'b000;
    end
    else if (SCK_risingedge) begin
        bitcnt <= bitcnt + 3'b001;

        // implement a shift-left register (since we receive the data MSB first)
        byte_data_received <= {byte_data_received[6:0], MOSI_data};
    end

    // We know when a byte has been received if bit count = 7 on the
    // final rising-edge while CS is active.
    byte_received <= SSEL_active && SCK_risingedge && (bitcnt == 3'b111);

    if (byte_received)
        LED_o <= byte_data_received[0];
end

// ----------------------------------------------
// TX: Slave to Master
// ----------------------------------------------
logic [7:0] byte_data_sent;
logic [7:0] cnt;

always_ff @(posedge sysClk_i) begin
    if (SSEL_startmessage)
        cnt <= cnt + 8'h1;  // count the messages

    if (SSEL_active) begin
        if (SSEL_startmessage)
            byte_data_sent <= cnt;  // first byte sent in a message is the message count
        else if (SCK_fallingedge) begin
            if (bitcnt == 3'b000)
                byte_data_sent <= 8'h00;  // after that, we send 0s
            else
                byte_data_sent <= {byte_data_sent[6:0], 1'b0};
        end
    end
end

assign SPI_MISO_o = SPI_MOSI_i;//byte_data_sent[7];  // send MSB first
assign byte_received_o = byte_received;// && SSEL_endmessage;

// we assume that there is only one slave on the SPI bus
// so we don't bother with a tri-state buffer for MISO
// otherwise we would need to tri-state MISO when SSEL is inactive

endmodule

