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
    output logic load_tx_byte,
    output logic [2:0] state,
    output logic [1:0] data_select,
    output logic bitFlag,
    output logic [1:0] current_data_select,
    output logic cds_loaded,
    output logic data1
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

// Previous value of SS_sync
logic p_SS_sync;

// A 3 bit counter to count the bits as they come in/out.
logic [2:0] bitCnt;
logic [7:0] data_out;

// Detect the final falling edge of the SPI clock.
// logic final_fall;
assign final_fall = state == SLIdle && SClk_fallingedge;

// Detect falling edge of CS
logic ss_sync_fall;
assign ss_sync_fall = SS_fallingedge; //p_SS_sync == 1'b1 && SS_sync == 1'b0;

always_ff @(posedge sysClk) begin
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
                byte_sent <= 1;
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

    if (bitFlag) begin
        state <= SLLoad;
    end

    if (state == SLLoad) begin
        data_out <= data_out_val;
        miso <= miso_val;
        byte_sent <= 1'b1;
        state <= SLIdle;
    end

    // We only send a byte if we detect a certain 2 byte sequence.
    // Sequence is: 0x41, 0x0A
    // if (bitFlag) begin
    //     // if (rx_buf[0] == 8'h41 && rx_buf[1] == 8'h0A) begin
    //         data_out <= data_out_val;
    //         miso <= miso_val;
    //         byte_sent <= 1'b1;
    //     // end
    //     // if (rx_buf[0] == 8'h41 && rx_buf[1] == 8'h00) begin
    //     //     data_out <= data_out_val;
    //     //     miso <= miso_val;
    //     //     byte_sent <= 1'b1;
    //     // end
    // end

    if (load_tx_byte) begin
        bitCnt <= 3'b110;
    end

end

assign bitFlag = data1 && cds_loaded;
//data1;
//bufCnt == 2'b01 && final_fall;

// assign data_select[1] = rx_buf[0] == 8'h41 && rx_buf[1] == 8'h0A;
// Detect the start and end of the transmission cycle.
logic load_tx_byte;
assign load_tx_byte = ss_sync_fall | final_fall;

logic [1:0] data_cnt;

logic [7:0] rx_buf [2:0];
// logic [1:0] bufCnt;
// logic byte_sent;

// Just some meaningless data that we can check from an actual Pico.
localparam [7:0] io_con_response = 8'h28;
localparam [7:0] io_dir_response = 8'hF9;

logic data1;
logic data2;
assign data1 = (rx_buf[0] == 8'h41 && rx_buf[1] == 8'h0A);
assign data2 = (rx_buf[0] == 8'h41 && rx_buf[1] == 8'h00);

logic [7:0] data_out_val;
// logic [1:0] data_select;
logic [1:0] current_data_select;
logic cds_loaded;

always_comb begin
    data_select = 2'b11; // state == SLTransmitting && SClk_fallingedge
    if (data1) begin // or data_load_falling
        data_select = 2'b00;
    end
    // else if (data2) begin
    //     data_select = 2'b01;
    // end
end

// Mux4 #(.DATA_WIDTH(8)) data_out_mux
// (
//     .select_i(current_data_select),
//     .data0_i(io_con_response << 1),
//     .data1_i(io_dir_response << 1),
//     .data2_i(8'b0),
//     .data3_i(data_out << 1),
//     .data_o(data_out_val)
// );

assign data_out_val = bitFlag ? io_con_response << 1 : 0;
assign miso_val = bitFlag ? io_con_response[7] << 1 : 0;

logic miso_val;
// Mux4 #(.DATA_WIDTH(1)) miso_mux
// (
//     .select_i(current_data_select),
//     .data0_i(io_con_response[7]),
//     .data1_i(io_dir_response[7]),
//     .data2_i(1'b0),
//     .data3_i(data_out[7]),
//     .data_o(miso_val)
// );

// Mux4 #(.DATA_WIDTH(1)) miso_mux
// (
//     .select_i(data_select),
//     .data0_i(io_con_response[7]),
//     .data1_i(io_dir_response[7]),
//     .data2_i(1'b0),
//     .data3_i(data1),
//     .data_o(miso_val)
// );

assign rx_bufI = rx_buf[0];

always_ff @(posedge sysClk) begin
    p_SS_sync <= SS_sync;

    if (ss_sync_fall) begin
        cds_loaded <= 0;
    end

    if (final_fall) begin
        // cds_loaded <= 0;
        // Capture byte
        rx_buf[bufCnt] <= rx_byte;
        bufCnt <= bufCnt + 2'b01;
        if (bufCnt == 2'b10)
            bufCnt <= 2'b00;
    end

    if (data1 && ~cds_loaded) begin
        current_data_select <= data_select;
        cds_loaded <= 1;
    end
end

endmodule

