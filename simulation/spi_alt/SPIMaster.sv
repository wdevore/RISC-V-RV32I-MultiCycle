`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// Usage:
// First write a byte to the module's internal buffer.
// On rising-edge of write begin transmitting and receiving.
// When data is fully sent then set complete signal.

module SPIMaster
(
    input logic  sysClk_i,            // system domain clock
    input  logic wr_i_n,              // Write enable
    input  logic [7:0] byte_to_send,  // Data to send
    output logic [7:0] byte_received, // Data received
    output logic tx_complete_o,
);

/*verilator public_module*/

logic [7:0] tx_data;
logic [7:0] rx_data;

TxState state /*verilator public*/;
TxState next_state /*verilator public*/;

// ----------------------------------------------------
// Rx: CDC Sync-ed signal for SClk
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
// Rx: CDC Sync-ed signal for CS or SSEL
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
// Rx: CDC Sync-ed signal for MOSI
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

// ----------------------------------------------------
// Tx: CDC Sync-ed signal for MISO (from slave)
// ----------------------------------------------------
logic MISO_risingedge;
logic MISO_fallingedge;
logic MISO_data;

CDCSynchron SPI_MOSI_Sync (
    .sysClk_i(sysClk_i),
    .async_i(SPI_MISO_i),
    .sync_o(MISO_data),
    .rising_o(MISO_risingedge),
    .falling_o(MISO_fallingedge)
);

// ----------------------------------------------
// RX: Master to Slave
// ----------------------------------------------

// We handle SPI in 8-bit format,
// so we need a 3 bits counter to count the bits as they come in
logic [2:0] bitcnt;
logic byte_received;  // high when a byte has been received
logic [7:0] byte_data_received;

always_ff @(posedge SCK_sync) begin
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

always_ff @(posedge SCK_sync) begin
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

always_ff @(posedge SCK_sync) begin
    if (!reset_i) begin
        state <= Reset;
    end
    else
        if (resetComplete) begin
            state <= next_state;
        end
        else begin
            state <= Reset;
        end

    if (~wr_i_n) begin
        tx_data <= byte_to_send;
        state <= Transmitting;
    end
end


assign SPI_MISO_o = SPI_MOSI_i;//byte_data_sent[7];  // send MSB first
assign byte_received_o = byte_received;// && SSEL_endmessage;


endmodule

