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

    output logic [7:0] rx_byte,
    output logic [1:0] bufCnt,
    output logic [7:0] rx_bufI,
    output logic byte_sent,
    output logic final_fall,
    output logic SClk_fallingedge,
    output logic SClk_risingedge,
    output logic SClk_sync,
    output logic MOSI_sync,
    output logic reset_cnt,
    output logic [2:0] state,
    output logic [1:0] data_select,
    output logic bitFlag,
    output logic [1:0] current_data_select,
    output logic cds_loaded,
    output logic pattern1,
    output logic [7:0] data_out
    
);

/*verilator public_module*/

SlaveState state /*verilator public*/;
// logic [7:0] rx_byte;

// ----------------------------------------------------
// CDC Sync-ed signal for SClk (from master)
// ----------------------------------------------------
// logic SClk_risingedge;
// logic SClk_fallingedge;
// logic SClk_sync;            // Not used

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
// logic MOSI_sync;

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

// A 3 bit counter to count the bits as they come in/out.
logic [2:0] bitCnt;
// logic [7:0] data_out;

// Detect the final falling edge of the SPI clock.
// logic final_fall;
assign final_fall = state == SLIdle && SClk_fallingedge;

always_ff @(posedge sysClk) begin
    if (SS_fallingedge) begin
        bufCnt <= 0;
        rx_buf[0] <= 8'hFF;
        rx_buf[1] <= 8'hFF;
        state <= SLCSLoad;//SLIdle;
    end

    if (state == SLCSLoad) begin
        data_select <= 0;
        state <= SLCSLoad2;
    end

    if (state == SLCSLoad2) begin
        data_out <= data_out_val;
        miso <= miso_val;
        data_select <= 3;
        state <= SLIdle;
    end

    // -------------------------
    // Main shifting output
    // -------------------------
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
            // to Transmit cycle.
            SLIdle: begin
                state <= SLTransmit;
            end

            // On any succeeding rising edge check for bit count.
            SLTransmit: begin
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

    // ----------------------------------------
    // Detect pattern and setup response
    if (pattern1 && state == SLIdle) begin
        state <= SLLoad;
        data_select <= 0;
    end

    if (pattern2 && state == SLIdle) begin
        state <= SLLoad;
        data_select <= 1;
    end

    if (pattern3 && state == SLIdle) begin
        state <= SLLoad;
        data_select <= 2;
    end

    // Setup response
    if (state == SLLoad) begin
        data_select <= 3;
        data_out <= data_out_val;
        miso <= miso_val;
        state <= SLIdle;
        // Clear buffers. TODO need a better scheme
        rx_buf[0] <= 8'hFF;
        rx_buf[1] <= 8'hFF;
    end
    // ----------------------------------------

    if (final_fall) begin
        // Capture byte into buffer
        rx_buf[bufCnt] <= rx_byte;
        bufCnt <= bufCnt + 2'b01;
        if (bufCnt == 2'b10)
            bufCnt <= 2'b00;
    end

    if (reset_cnt) begin
        bitCnt <= 3'b110;
    end

end

logic [7:0] data_out_val;
Mux4 #(.DATA_WIDTH(8)) data_out_mux
(
    .select_i(data_select),
    .data0_i(io_con_response<<1),
    .data1_i(io_dir_response<<1),
    .data2_i(io_ipo_response<<1),
    .data3_i(data_out << 1),
    .data_o(data_out_val)
);

logic miso_val;
Mux4 #(.DATA_WIDTH(1)) miso_mux
(
    .select_i(data_select),
    .data0_i(io_con_response[7]),
    .data1_i(io_dir_response[7]),
    .data2_i(io_ipo_response[7]),
    .data3_i(data_out[7]),
    .data_o(miso_val)
);

// Detect the start and end of the transmission cycle.
logic reset_cnt;
assign reset_cnt = SS_fallingedge | final_fall;

logic [7:0] rx_buf [2:0];

// Just some meaningless data that we can check from an actual Pico.
localparam [7:0] io_con_response = 8'h28;
localparam [7:0] io_dir_response = 8'hF9;
localparam [7:0] io_ipo_response = 8'hE4;

logic pattern1;
logic pattern2;
logic pattern3;
assign pattern1 = (rx_buf[0] == 8'h41 && rx_buf[1] == 8'h0A);
assign pattern2 = (rx_buf[0] == 8'h41 && rx_buf[1] == 8'h0F);
assign pattern3 = (rx_buf[0] == 8'h41 && rx_buf[1] == 8'h00);

logic cds_loaded;

assign rx_bufI = rx_buf[0];

endmodule

