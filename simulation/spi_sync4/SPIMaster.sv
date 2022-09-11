`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// SPI Master sends a byte then idles the clock as long as tx_en is low.
// When tx_en goes high the clock is idled until it becomes active-low again.

// To send a byte
// - Set byte count input value
// - First byte is placed on the input

// On falling edge data is shifted
// On leading edge data is sampled
// Clocks are only generated for each bit
// CS remains active until all bytes or byte is transferred.

// For the Slave when CS activates it waits for a rising edge to
// sample data.
// On the falling edge it shifts its output register.

module SPIMaster
#(
    parameter CLK_DIVIDER = 4)
(
    input  logic sysClk,            // system domain clock for syncing
    output logic sClk,              // SPI Clock output
    input  logic reset,             // Reset
    input  logic tx_en,             // Enable transmission of bits (active low)
    output logic mosi,              // output (1 bit at a time) routed to slave
    input  logic miso,              // Bit from slave
    input  logic [7:0] tx_byte,     // Byte to send
    output logic byte_tx_complete,  // Signal indicating the current byte was sent (active hight)
    output logic [7:0] rx_byte      // Byte received
);

/*verilator public_module*/

MasterState state;

logic [4:0] sysClkCnt;
logic spiClk;

// The SPI clock is fraction of the system clock.
assign spiClk = sysClkCnt[CLK_DIVIDER];

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

// A 3 bit counter to count the bits as they come in/out.
logic [2:0] bitCnt;
logic [7:0] rx_bits;
logic [7:0] tx_bits;

// ---------------------------------------------------
// Simulation
// ---------------------------------------------------
// initial begin
// end

// The clock is only active during transmission which is
// Transmitting and Complete. Otherwise it idles low for Mode 0
assign sClk = ((state == MSTransmitting) || (state == MSComplete)) & ~tx_en & spiClk;

// On the trailing edge we setup the data for the leading edge.
// This means we shift data to the left (LSb to MSb) "<< 1"
always_ff @(negedge spiClk) begin
    // What ever signals change won't occur until the next *edge*.
    case (state)
        MSIdle: begin
            // tx_byte must be present *before* falling edge
            tx_bits <= tx_byte;
        end

        MSBegin: begin
            mosi <= tx_bits[7];
            tx_bits <= tx_bits << 1;
        end

        MSTransmitting: begin
            mosi <= tx_bits[7];
            tx_bits <= tx_bits << 1;
        end

        MSComplete: begin
            mosi <= tx_bits[7];
            tx_bits <= tx_bits << 1;
        end

        default: begin
        end
    endcase
end

logic [7:0] xx_bits;

// Leading rising edge. Sample a bit on this edge.
// The Slave should also sample on this edge *after* synchronizing.
always_ff @(posedge spiClk) begin
    if (state == MSTransmitting) begin
    end
    // What ever signals change won't occur until the next *edge*.
    case (state)
        MSIdle: begin
            // When tx_en activates the input data should already be present.
            if (~tx_en) begin
                bitCnt <= 3'b111;
                rx_bits <= 8'b0;
                state <= MSBegin;
                byte_tx_complete <= 1'b0;
            end
        end

        MSBegin: begin
            bitCnt <= bitCnt - 3'b001;
            rx_bits <= {rx_bits[6:0], MISO_sync}; // Input
            state <= MSTransmitting;
        end

        MSTransmitting: begin
            if (bitCnt == 3'b000) begin
                state <= MSComplete;
                byte_tx_complete <= 1'b1;
            end
            rx_bits <= {rx_bits[6:0], MISO_sync}; // Input
            bitCnt <= bitCnt - 3'b001;
        end

        MSComplete: begin
            state <= MSIdle;
            rx_byte <= {rx_bits[6:0], MISO_sync}; // Input
            byte_tx_complete <= 1'b0;
        end

        default: begin
        end
    endcase

end

always_ff @(posedge sysClk) begin
    sysClkCnt <= sysClkCnt + 4'b0001;
end

endmodule

