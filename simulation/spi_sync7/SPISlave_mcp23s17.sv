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

// Detect the start and end of the transmission cycle.
logic load_tx_byte;
assign load_tx_byte = ss_sync_fall | final_fall;

always_ff @(posedge sysClk) begin
    // On a falling edge SPI clock and while transmitting
    // we output the MSB bit
    if (SClk_fallingedge) begin
        if (state == SLTransmit) begin
            miso <= miso_val;
            state <= SLShift;
        end
    end
    
    // Then we shift the next bit into MSB position.
    if (state == SLShift) begin
        data_out <= data_out_val;
        state <= SLTransmit;
    end

    if (SClk_risingedge) begin
        case (state)
            // On the first rising edge of SPI clock transition
            // to transmission cycle.
            SLIdle: begin
                state <= SLTransmit;
            end

            SLTransmit: begin
                // Once count == 0 we transition back to Idle and repeat.
                // We don't transition out of Idle until we detect a
                // new rising SPI clock edge.
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

logic [1:0] delayCnt;
// logic data_loaded;
logic [1:0] data_cnt;
logic [7:0] data_out_val;
logic [1:0] data_select;

logic data1;
logic data2;
logic data3;
assign data1 = data_cnt == 2'b00 && load_tx_byte;
assign data2 = data_cnt == 2'b01 && load_tx_byte;
assign data3 = data_cnt == 2'b10 && load_tx_byte;

always_comb begin
    data_select = 2'b11; // state == SLTransmitting && SClk_fallingedge
    if (data1) begin // or data_load_falling
        data_select = 2'b00;
    end
    else if (data2) begin
        data_select = 2'b01;
    end
    else if (data3) begin
        data_select = 2'b10;
    end
end

Mux4 #(.DATA_WIDTH(8)) data_out_mux
(
    .select_i(data_select),
    .data0_i(8'h79 << 1),
    .data1_i(8'h99 << 1),
    .data2_i(8'hE4 << 1),
    .data3_i(data_out << 1),
    .data_o(data_out_val)
);

logic miso_val;
Mux4 #(.DATA_WIDTH(1)) miso_mux
(
    .select_i(data_select),
    .data0_i(1'b0),
    .data1_i(1'b1),
    .data2_i(1'b1),
    .data3_i(data_out[7]),
    .data_o(miso_val)
);

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
    // to the first rising edge of the spiClk and
    // hopefully early enough to let the data bit settle.

    // NOTE: This is a hack to simulate an MCP23S17 IO expander.
    if (data1) begin // or data_load_falling
        data_out <= data_out_val;
        miso <= miso_val;
        data_cnt <= data_cnt + 1;
    end
    if (data2) begin
        data_out <= data_out_val;
        miso <= miso_val;
        data_cnt <= data_cnt + 1;
    end
    if (data3) begin
        data_out <= data_out_val;
        miso <= miso_val;
        // data_out <= 8'h62;
        data_cnt <= data_cnt + 1;
    end

    // Reset the counter to 7-1=6
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

