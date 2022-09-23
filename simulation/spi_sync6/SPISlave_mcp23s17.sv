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
logic p_SS_sync;

// A 3 bit counter to count the bits as they come in/out.
logic [2:0] bitCnt;
logic [7:0] data_out;
logic [1:0] data_cnt;

logic final_fall;
assign final_fall = state == SLIdle && SClk_fallingedge;

logic ss_sync_fall;
assign ss_sync_fall = p_SS_sync == 1'b1 && SS_sync == 1'b0;

always_ff @(posedge sysClk) begin
    if (SClk_fallingedge) begin
        case (state)
            SLTransmitting: begin
                miso <= data_out[7];  // Output bit for rising edge
                data_out <= data_out << 1;
                $display("SLTransmitting (%b) [%d], %8h", data_out[7], bitCnt, data_out);
            end

            default: begin
            end
        endcase
    end

    if (SClk_risingedge) begin
        case (state)
            SLIdle: begin
                state <= SLTransmitting;
                $display("idle rising B");
            end

            SLTransmitting: begin
                if (bitCnt == 3'b000) begin
                    state <= SLIdle;
                    bitCnt <= 3'b110;
                    $display("tx rising A");
                end
                else
                    bitCnt <= bitCnt - 3'b001;
            end

            default: begin
            end
        endcase

        rx_byte <= {rx_byte[6:0], MOSI_sync}; // Input
    end
end

logic load_tx_byte;
assign load_tx_byte = ss_sync_fall | final_fall;

logic [1:0] delayCnt;
logic data_loaded;

always_ff @(posedge sysClk) begin
    p_SClk_sync <= SClk_sync;
    p_SS_sync <= SS_sync;

    // NOTE: This is a hack to simulate an MCP23S17 IO expander.
    if (data_cnt == 2'b00 && load_tx_byte) begin // or data_load_falling
        data_out <= 8'h79;
        data_cnt <= data_cnt + 1;
    end
    if (data_cnt == 2'b01 && load_tx_byte) begin
        data_out <= 8'h99;
        data_cnt <= data_cnt + 1;
    end
    if (data_cnt == 2'b10 && load_tx_byte) begin
        data_out <= 8'hE4;
        // data_out <= 8'h62;
        data_cnt <= data_cnt + 1;
    end
    if (data_cnt == 2'b11 && load_tx_byte) begin
        data_out <= 8'hE4;
        data_cnt <= data_cnt + 1;
    end

    if (load_tx_byte) begin
        data_loaded <= 1'b1;
        bitCnt <= 3'b110;
    end

    if (data_loaded) begin
        delayCnt <= delayCnt + 1;
        if (delayCnt == 2'b01) begin
            delayCnt <= 0;
            data_loaded <= 1'b0;
            miso <= data_out[7];  // Output bit
            data_out <= data_out << 1;
        end
    end
end

endmodule

