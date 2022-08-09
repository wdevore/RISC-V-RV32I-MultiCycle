`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// SPI Slave needs to sync on 3 signals from Master:
// 1) SClk
// 2) MOSI
// 3) /SS

// Transmit on rising edge of SClk and received on falling edge.

module SPISlave
(
    input  logic sysClk_i,            // system domain clock (PLL)
    input  logic reset_i,
    input  logic mosi_i,              // output (1 bit at a time)
    output logic miso_o,
    input  logic sclk_i,
    input  logic ss_i_n,
    input  logic [7:0] byte_to_send_i,  // Data to send
    output logic [7:0] byte_received_o  // Data received
);

/*verilator public_module*/

logic [7:0] tx_data = byte_to_send_i;

SlaveState state /*verilator public*/;
logic [7:0] rx_data;

logic [2:0] sysClkCnt;

// spiClk_internal is either the SClk_sync or internalClk.
// It is designed to provide 1 extra clock so the Slave
// can transition back to the Idle state after reaching
// the Complete state.
// This is because the Master stops the clock after it has
// sent the last bit, however, the Slave needs a little
// bit more time because of synchronizing.
// So dataComplete indicates when we can switch to the internal
// clock.
// The internal clock is actually the system clock.
logic spiClk_internal;
logic dataComplete;

// The internal clock activates just shortly after
// reaching the Complete state. This happens when the
// clock reaches 111.
logic internalClk;
assign internalClk = sysClkCnt == 3'b111;

// ----------------------------------------------------
// CDC Sync-ed signal for SClk (from master)
// ----------------------------------------------------
logic SClk_risingedge;
logic SClk_fallingedge;
logic SClk_sync;

CDCSynchron SPI_SClk_Sync (
    .sysClk_i(sysClk_i),
    .async_i(sclk_i),
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
    .sysClk_i(sysClk_i),
    .async_i(mosi_i),
    .sync_o(MOSI_sync),
    .rising_o(MOSI_risingedge),
    .falling_o(MOSI_fallingedge)
);

// ----------------------------------------------------
// CDC Sync-ed signal for /SS (from master)
// ----------------------------------------------------
logic SS_risingedge;
logic SS_fallingedge;
logic SS_sync;

CDCSynchron SPI_SS_Sync (
    .sysClk_i(sysClk_i),
    .async_i(ss_i_n),
    .sync_o(SS_sync),
    .rising_o(SS_risingedge),
    .falling_o(SS_fallingedge)
);

// We handle SPI in 8-bit format,
// so we need a 3 bits counter to count the bits as they come in
logic [2:0] bitCnt;

// ---------------------------------------------------
// Simulation
// ---------------------------------------------------
initial begin
    $display("Slave Sim init");
end

// ----------------------------------------------
// TX: Slave to Master
// ----------------------------------------------
assign spiClk_internal = (dataComplete) ? internalClk : SClk_sync;

// This sync block tracks State and bit count.
always_ff @(posedge spiClk_internal) begin
    dataComplete = 1'b0;

    case (state)
        SLIdle: begin
            if (~SS_sync) begin
                bitCnt <= 3'b111;
                state <= SLBegin;
            end
        end

        SLBegin: begin
            bitCnt <= bitCnt - 3'b001;
            state <= SLTransmitting;
        end

        SLTransmitting: begin
            bitCnt <= bitCnt - 3'b001;
            if (bitCnt == 3'b000) begin
                state <= SLComplete;
                dataComplete = 1'b1;
            end
        end

        SLComplete: begin
            state <= SLIdle;
        end

        default: begin
        end
    endcase
end

// Data is sampled on the rising edge
always_ff @(posedge spiClk_internal) begin
    case (state)
        SLIdle: begin
            byte_received_o <= {byte_received_o[6:0], MOSI_sync};
        end

        SLBegin: begin
            byte_received_o <= {byte_received_o[6:0], MOSI_sync};
        end

        SLTransmitting: begin
            byte_received_o <= {byte_received_o[6:0], MOSI_sync};
        end

        SLComplete: begin
            rx_data <= byte_received_o;
        end

        default: begin
        end
    endcase
end

// Data is shifted out on the falling edge
always_ff @(negedge spiClk_internal) begin
    case (state)
        SLBegin: begin
            miso_o <= tx_data[bitCnt]; // The bit output
        end

        SLTransmitting: begin
            miso_o <= tx_data[bitCnt]; // The bit output
        end

        SLComplete: begin
            miso_o <= 0;
        end

        default: begin
        end
    endcase
end

always_ff @(posedge sysClk_i) begin
    sysClkCnt <= sysClkCnt + 2'b01;
end

endmodule

