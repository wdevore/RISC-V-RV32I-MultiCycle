`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// SPI Master sends a byte then idles the clock as long as tx_en is low.
// When tx_en goes high the clock is idled until it becomes active-low again.

// To send a byte
// - Set byte count input value
// - First byte is placed on the input
// - tx_en is asserted
// - The clock when the last bit is sent or tx_en is deasserted.

module SPIMaster
(
    input  logic sysClk,         // system domain clock for syncing
    output logic spiClk_o,       // SPI Clock output
    input  logic reset,          // Reset
    input  logic tx_en,          // Enable transmission of bits (active low)
    output logic mosi,           // output (1 bit at a time) routed to slave
    input  logic miso,           // Bit from slave
    input  logic [7:0] tx_byte,  // Byte to send
    output logic [7:0] rx_byte   // Byte received
);

/*verilator public_module*/

MasterState state;

logic [4:0] sysClkCnt;
logic spiClk;

// The SPI clock is fraction of the system clock.
// Clocks are 1/4 the PLL.
assign spiClk = sysClkCnt[4];

// resetCnt allows CDC synchronizers to propagate.
logic [1:0] resetCnt;

// A 3 bit counter to count the bits as they come in/out.
logic [2:0] bitCnt;
logic [7:0] rx_bits;
MasterState prev_state;
logic prev_clk;
logic prev_spiClk_o;
logic rising_edge;
logic falling_edge;

// ----------------------------------------------------
// CDC Sync-ed signal for MISO (from slave)
// ----------------------------------------------------
logic MISO_risingedge;
logic MISO_fallingedge;
logic MISO_sync;

CDCSynchron SPI_MISO_Sync (
    .sysClk_i(sysClk),
    .async_i(miso),
    .sync_o(MISO_sync),
    .rising_o(MISO_risingedge),
    .falling_o(MISO_fallingedge)
);

always_comb begin
    case (prev_state)
        MSIdle: begin
            if (state == MSBegin) begin
                $display("Idle -> Begin");
                // Setup data
                mosi = tx_byte[bitCnt];
            end
        end

        MSBegin: begin
            if (state == MSTransmitting) begin
                $display("MSBegin -> MSTransmitting %d", bitCnt);
                // Setup data
                mosi = tx_byte[bitCnt];
            end
        end

        MSTransmitting: begin
                $display("MSBegin -> MSTransmitting %d", bitCnt);
                // Setup data
                mosi = tx_byte[bitCnt];
        end

        default: begin
        end
    endcase
end

// assign rx_byte = (state == MSComplete) ? {rx_bits[6:0], MISO_sync} : 0;
// assign rx_byte = {rx_bits[6:0], MISO_sync};

// The clock is only active during transmission which is
// Transmitting and Complete. Otherwise it idles low for Mode 0
assign spiClk_o = (state == MSTransmitting || state == MSComplete) && !tx_en && spiClk;

assign rising_edge = prev_clk == 1'b0 && spiClk == 1'b1;
assign falling_edge = prev_clk == 1'b1 && spiClk == 1'b0;

// States and main counters
always_ff @(posedge sysClk) begin
    sysClkCnt <= sysClkCnt + 1;
    resetCnt <= resetCnt + 1;
    prev_state <= state;
    prev_clk <= spiClk;
    prev_spiClk_o <= spiClk_o;

    case (state)
        MSReset: begin
            if (resetCnt == 2'b10) begin
                state <= MSIdle;
            end
        end

        MSIdle: begin
            if (~tx_en && rising_edge) begin
                state <= MSBegin;
                bitCnt <= 3'b111;
            end
        end

        MSBegin: begin
            if (rising_edge) begin
                state <= MSTransmitting;
            end
        end

        MSTransmitting: begin
            if (bitCnt == 3'b000 && rising_edge) begin
                state <= MSComplete;
            end
            if (falling_edge) begin
                bitCnt <= bitCnt - 3'b001;
            end
        end

        MSComplete: begin
            if (rising_edge) begin
                state <= SLIdle;
            end
        end

        default: begin
        end
    endcase

end

endmodule

