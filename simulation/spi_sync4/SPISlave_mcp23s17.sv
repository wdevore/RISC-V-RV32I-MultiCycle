`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// SPI Slave needs to sync on 3 signals from Master:
// 1) SClk
// 2) MOSI
// 3) /SS (aka /CS)

// Transmit on rising edge of SClk and received on falling edge.

module SPISlave
(
    input  logic sysClk,         // system domain clock (PLL)
    input  logic spiClk,         // SPI Clock input from Master
    input  logic cs,             // /CS
    input  logic mosi,           // output (1 bit at a time)
    output logic miso,
    input  logic [7:0] tx_byte,  // Byte to send
    output logic [7:0] rx_byte   // Byte received
);

/*verilator public_module*/

SlaveState state /*verilator public*/;

// ----------------------------------------------------
// CDC Sync-ed signal for SClk (from master)
// ----------------------------------------------------
logic SClk_risingedge;
logic SClk_fallingedge;
logic SClk_sync;

CDCSynchron SPI_SClk_Sync (
    .sysClk_i(sysClk),
    .async_i(spiClk),
    .sync_o(SClk_sync),
    .rising_o(SClk_risingedge),
    .falling_o(SClk_fallingedge)
);

// ----------------------------------------------------
// CDC Sync-ed signal for MOSI (from master)
// ----------------------------------------------------
logic MOSI_risingedge;
logic MOSI_fallingedge;
logic MOSI_sync;

CDCSynchron SPI_MOSI_Sync (
    .sysClk_i(sysClk),
    .async_i(mosi),
    .sync_o(MOSI_sync),
    .rising_o(MOSI_risingedge),
    .falling_o(MOSI_fallingedge)
);

// ----------------------------------------------------
// CDC Sync-ed signal for /CS (from master)
// ----------------------------------------------------
logic SS_risingedge;
logic SS_fallingedge;
logic SS_sync;

CDCSynchron SPI_SS_Sync (
    .sysClk_i(sysClk),
    .async_i(cs),
    .sync_o(SS_sync),
    .rising_o(SS_risingedge),
    .falling_o(SS_fallingedge)
);

logic [1:0] resetCnt;
logic p_SClk_sync;

// A 3 bit counter to count the bits as they come in/out.
logic [2:0] bitCnt;
logic [7:0] data_out;
logic [1:0] data_cnt;

// On the trailing edge we setup the data for the leading edge.
always_ff @(negedge SClk_sync, negedge SS_sync) begin
    // What ever signals change won't occur until the next *pos* edge.
    case (state)
        SLIdle: begin
            // Make sure the data is present on the output for the next
            // rising edge
            miso <= data_out[7];//tx_byte[7]; // Output bit
        end

        SLTransmitting: begin
            miso <= data_out[bitCnt]; //tx_byte[bitCnt]; // Output bit
        end

        default: begin
        end
    endcase
end

// Leading rising edge. Sample a bit on this edge.
always_ff @(posedge SClk_sync) begin
    // What ever signals change won't occur until the next *neg* edge.
    case (state)
        SLIdle: begin
            if (~SS_sync) begin
                bitCnt <= 3'b110;
                rx_byte <= {rx_byte[6:0], MOSI_sync};
                state <= SLTransmitting;
            end
        end

        SLTransmitting: begin
            if (bitCnt == 3'b000)
                state <= SLIdle;
            else
                bitCnt <= bitCnt - 3'b001;

            rx_byte <= {rx_byte[6:0], MOSI_sync}; // Input
        end

        default: begin
        end
    endcase
end

always_ff @(posedge sysClk) begin
    p_SClk_sync <= SClk_sync;

    // NOTE: This is a hack to simulate an MCP23S17 IO expander.
    if (rx_byte == 8'hA1 && (p_SClk_sync == 1'b1 && SClk_sync == 1'b0) && data_cnt == 2'b00) begin
        data_out <= 8'h99;
        data_cnt <= data_cnt + 1;
    end
    else if (rx_byte == 8'h2A && (p_SClk_sync == 1'b1 && SClk_sync == 1'b0) && data_cnt == 2'b01) begin
        data_out <= 8'hC9;
        data_cnt <= data_cnt + 1;
    end
    else if (data_cnt == 2'b00) begin
        data_out <= 8'hE4;
    end
end


endmodule

