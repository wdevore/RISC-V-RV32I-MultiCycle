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
assign data_out = state == SLIdle ? io_con_response << 1 : data_out << 1;

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
                // data_out <= data_out << 1;
            end

            default: begin
            end
        endcase
    end

    if (SClk_risingedge) begin
        case (state)
            // On the first rising edge of SPI clock, transition
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

logic data_loaded;
logic [1:0] data_cnt;

logic [7:0] rx_buf [2:0];
logic [1:0] bufCnt;
logic byte_sent;

// Just some meaningless data that we can check from an actual Pico.
localparam [7:0] io_con_response = 8'h28;
localparam [7:0] io_dir_response = 8'hF9;

always_ff @(posedge sysClk) begin
    p_SS_sync <= SS_sync;

    if (final_fall) begin
        // Capture byte
        rx_buf[bufCnt] <= rx_byte;
        bufCnt <= bufCnt + 2'b01;
    end

    // We only send a byte if we detect a certain 2 byte sequence.
    // Sequence is: 0x41, 0x0A
    if (bufCnt == 2'b10 & ~byte_sent) begin
        if (rx_buf[0] == 8'h41 && rx_buf[1] == 8'h0A) begin
            // data_out <= io_con_response << 1;
            miso <= io_con_response[7];
            byte_sent <= 1'b1;
        end
        if (rx_buf[0] == 8'h41 && rx_buf[1] == 8'h00) begin
            // data_out <= io_dir_response << 1;
            miso <= io_dir_response[7];
            byte_sent <= 1'b1;
        end
    end


    if (load_tx_byte) begin
        bitCnt <= 3'b110;
    end
end

endmodule

