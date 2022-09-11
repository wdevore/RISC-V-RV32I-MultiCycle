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

// A 3 bit counter to count the bits as they come in/out.
logic [2:0] bitCnt;

// When tx_en activates the input data should already be present.

// On the trailing edge we setup the data for the leading edge.
always_ff @(negedge SClk_sync, negedge SS_sync) begin
    // What ever signals change won't occur until the next *pos* edge.
    case (state)
        SLIdle: begin
            // if (~SS_sync) begin
                // Make sure the data is present on the output for the next
                // rising edge
                miso <= tx_byte[7]; // Output bit
            // end
        end

        SLTransmitting: begin
            miso <= tx_byte[bitCnt]; // Output bit
        end

        // SLComplete: begin
        //     miso <= tx_byte[bitCnt]; // Output bit
        // end

        default: begin
        end
    endcase
end

// Leading rising edge. Sample a bit on this edge.
// The Slave should also sample on this edge.
always_ff @(posedge SClk_sync) begin
    // What ever signals change won't occur until the next *neg* edge.
    case (state)
        SLIdle: begin
            // bitCnt <= 3'b111;
            if (~SS_sync) begin
                bitCnt <= 3'b110;
                rx_byte <= {rx_byte[6:0], MOSI_sync};
                state <= SLTransmitting;
            end
        end

        // SLBegin: begin
        //     // $display("B");
        //     // bitCnt <= 3'b111;
        //     rx_byte <= {rx_byte[6:0], MOSI_sync}; // Input
        //     bitCnt <= bitCnt - 3'b001;
        // end

        SLTransmitting: begin
            if (bitCnt == 3'b000)
                state <= SLIdle;
            else
                bitCnt <= bitCnt - 3'b001;

            rx_byte <= {rx_byte[6:0], MOSI_sync}; // Input
        end

        // SLComplete: begin
        //     // bitCnt <= bitCnt - 3'b001;
        //         state <= SLIdle;
        // end

        default: begin
        end
    endcase
end

// always_ff @(posedge sysClk) begin
//     resetCnt <= resetCnt + 1;
//     $display("resetcnt %2b, %d", resetCnt, state);

//     case (state)
//         SLReset: begin
//             if (resetCnt == 2'b10) begin
//                 state <= SLIdle;
//             end
//         end

//         // SLIdle: begin
//         //     if (~SS_sync) begin
//         //         state <= SLBegin;
//         //     end
//         // end

//         // SLBegin: begin
//         //     if (SClk_sync == 1'b1)
//         //         state <= SLTransmitting;
//         // end

//         // SLTransmitting: begin
//         //     if (bitCnt == 3'b000) begin
//         //         state <= SLComplete;
//         //     end
//         // end

//         // SLComplete: begin
//         //     if (SClk_fallingedge) begin
//         //         state <= SLIdle;
//         //     end
//         // end

//         default: begin
//         end
//     endcase
// end

endmodule

