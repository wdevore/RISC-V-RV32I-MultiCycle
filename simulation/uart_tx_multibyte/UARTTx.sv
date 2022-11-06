`default_nettype none
`ifdef SIMULATE
`timescale 10ns/1ns
`endif

// UART transmitter
// Sends a byte using 8N1 format

module UARTTx
#(
    parameter BAUD = 115200,            // 115200 bits per second = 8.68us
    parameter SOURCE_FREQ = 25000000,   // 25MHz = 40ns period
    parameter ACCUMULATOR_WIDTH = 16    // Bit size of accumulator
)
(
    input  logic sourceClk,         // Source clock
    /* verilator lint_off UNUSED */
    input  logic reset,             // Reset
    input  logic tx_en,             // Enable transmission of bits (active low)
    input  logic [7:0] tx_byte,     // Byte to send
    output logic tx_out,            // output (1 bit at a time)
    /* verilator lint_on UNUSED */
    output logic tx_complete        // Signal current byte was sent (active high) for 1 cycle.
);

/*verilator public_module*/

TxState state = 0;  // Default to TxReset.

// Calculate baud tick counter value. We will add this to a counter.
// The counter-rollover will generate a tick.

// This truncates, for example 301
// localparam COUNT_INC = $rtoi($itor(1 << ACCUMULATOR_WIDTH) / SOURCE_FREQ * BAUD);
// This correctly rounds up to 302. See: https://www.fpga4fun.com/SerialInterface2.html
localparam COUNT_INC = ((BAUD<<(ACCUMULATOR_WIDTH-4))+(SOURCE_FREQ>>5))/(SOURCE_FREQ>>4);

// We want an extra bit for rollover therefore no "-1"
logic [ACCUMULATOR_WIDTH:0] baud_counter;
logic baud_tick;
logic baud_half_tick;

// A 3 bit counter to count the bits.
logic [2:0] bitCnt = 0;
logic [7:0] tx_bits;

assign baud_tick = baud_counter[ACCUMULATOR_WIDTH];

always_ff @(posedge sourceClk) begin
    baud_counter <= baud_counter + COUNT_INC[16:0];

    case (state)
        TxReset: begin
            $display("TxReset");
            tx_bits <= 0;
            tx_complete <= 0;
            state <= TxIdle;
        end

        TxIdle: begin
            tx_complete <= 0;

            // UART line idle high
            tx_out <= 1;

            if (~tx_en) begin
                state <= TxStartBit;
                // Begin sending Start bit
                tx_out <= 0;
                tx_bits <= tx_byte;
                baud_counter <= 0;
            end
        end

        TxStartBit: begin
            // and hold for 1 bit period
            if (baud_tick == 1'b1) begin
                state <= TxSending;
                // Begin sending LSb bit
                tx_out <= tx_bits[0];
                baud_counter <= 0;
                bitCnt <= 7;
            end
        end

        TxSending: begin
            tx_out <= tx_bits[0];

            // and hold for 1 bit period
            if (baud_tick == 1'b1) begin
                if (bitCnt == 0) begin
                    state <= TxStopBit;
                    // Begin sending Stop bit
                    tx_out <= 1;
                end
                baud_counter <= 0;
                tx_bits <= tx_bits >> 1;
                bitCnt <= bitCnt - 1;
            end
        end

        TxStopBit: begin
            // and hold for 1 bit period
            if (baud_tick == 1'b1) begin
                state <= TxIdle;
                baud_counter <= 0;
                bitCnt <= 0;
                tx_complete <= 1;
            end
        end

        default: begin
        end
    endcase
end

endmodule

