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
    output logic miso
);

/*verilator public_module*/

SlaveState state /*verilator public*/;
logic [7:0] rx_byte;

// ----------------------------------------------------
// CDC Sync-ed signal for SClk (from master)
// ----------------------------------------------------
logic SClk_risingedge;
logic SClk_fallingedge;
logic SClk_sync;            // Not used

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

// Previous value of SS_sync
logic p_SS_sync;

// A 3 bit counter to count the bits as they come in/out.
logic [2:0] bitCnt;
logic [7:0] data_out;

// Detect the final falling edge of the SPI clock.
logic final_fall;
assign final_fall = state == SLIdle && SClk_fallingedge;

// Detect falling edge of CS
logic ss_sync_fall;
assign ss_sync_fall = p_SS_sync == 1'b1 && SS_sync == 1'b0;

always_ff @(posedge sysClk) begin
    if (SClk_fallingedge) begin
        case (state)
            SLTransmitting: begin
                miso <= data_out[7];  // Output bit for next rising edge
                data_out <= data_out << 1;
            end

            default: begin
            end
        endcase
    end

    if (SClk_risingedge) begin
        case (state)
            // On the first rising edge of SPI clock transition
            // to transmission cycle.
            SLIdle: begin
                state <= SLTransmitting;
            end

            SLTransmitting: begin
                // Once count == 0 we transition back to idle and repeat.
                if (bitCnt == 3'b000)
                    state <= SLIdle;
                else
                    bitCnt <= bitCnt - 3'b001;
            end

            default: begin
            end
        endcase

        rx_byte <= {rx_byte[6:0], MOSI_sync}; // Input from Master
    end
end

// Detect the start and end of the transmission cycle.
logic load_tx_byte;
assign load_tx_byte = ss_sync_fall | final_fall;

logic [1:0] delayCnt;
logic data_loaded;
logic [1:0] data_cnt;

always_ff @(posedge sysClk) begin
    p_SS_sync <= SS_sync;

    // Note: The first bit needs to setup prior to entering
    // SLTransmitting. Doesn't matter how you do it as long as
    // it is done.
    // You can either pre-shift data_out AND set
    // miso to the MSB manually, and keep in mind this must happen at
    // THE SAME TIME.
    // For example:
    //    data_out <= 8'h79 << 1;
    //    miso <= 1'b0;
    // OR
    // You use an extra sysClk to setup miso and data_out.
    // See Alt-B below
    //
    // If this was an actual hardware device, that device would sense
    // the CS assertion and begin setting up the first bit *prior*
    // to the first rising edge (i.e. the first rising edge) and
    // hopefully early enough to let the data bit settle.

    // NOTE: This is a hack to simulate an MCP23S17 IO expander.
    if (data_cnt == 2'b00 && load_tx_byte) begin // or data_load_falling
        data_out <= 8'h79 << 1;
        miso <= 1'b0;
        data_cnt <= data_cnt + 1;
    end
    if (data_cnt == 2'b01 && load_tx_byte) begin
        data_out <= 8'h99 << 1;
        miso <= 1'b1;
        data_cnt <= data_cnt + 1;
    end
    if (data_cnt == 2'b10 && load_tx_byte) begin
        data_out <= 8'hE4 << 1;
        miso <= 1'b1;
        // data_out <= 8'h62;
        data_cnt <= data_cnt + 1;
    end

    // Reset the counter at the start and end
    if (load_tx_byte) begin
        // data_loaded <= 1'b1;         // <- Alt-B
        bitCnt <= 3'b110;
    end

    // ---- Alt-B ------------
    // if (data_loaded) begin
    //     delayCnt <= delayCnt + 1;
    //     if (delayCnt == 2'b01) begin
    //         delayCnt <= 0;
    //         data_loaded <= 1'b0;
    //         miso <= data_out[7];  // Output bit
    //         data_out <= data_out << 1;
    //     end
    // end
end

endmodule

