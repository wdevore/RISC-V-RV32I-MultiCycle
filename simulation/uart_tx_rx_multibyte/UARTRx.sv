`default_nettype none
`ifdef SIMULATE
`timescale 10ns/1ns
`endif

// UART receiver
// Receives a byte using 8N1 format

module UARTRx
(
    input  logic sourceClk,         // Source clock
/* verilator lint_off UNUSED */
    input  logic reset,             // Reset
/* verilator lint_on UNUSED */
    input  logic rx_in,             // Incoming bits
    output logic [7:0] rx_byte,     // Byte received
    output logic rx_complete        // Signal a byte was received (active high) for 1 cycle.
);

/*verilator public_module*/

RxState state = 0;  // Default to RxReset.

// ----------------------------------------------------
// CDC Sync-ed signal for Rx
// ----------------------------------------------------
/* verilator lint_off UNUSED */
logic Rx_risingedge;
/* verilator lint_on UNUSED */
logic Rx_fallingedge;
logic Rx_sync;

CDCSynchron Rx_Sync (
    .sysClk_i(sourceClk),
    .async_i(rx_in),
    .sync_o(Rx_sync),
    .rising_o(Rx_risingedge),
    .falling_o(Rx_fallingedge)
);

// Calculate baud tick counter value. We will add this to a counter.
// The counter-rollover will generate a tick.

// This truncates, for example 301
// localparam COUNT_INC = $rtoi($itor(1 << ACCUMULATOR_WIDTH) / SOURCE_FREQ * BAUD);
// This correctly rounds up to 302. See: https://www.fpga4fun.com/SerialInterface2.html
localparam COUNT_INC = ((`BAUD<<(`ACCUMULATOR_WIDTH-4))+(`SOURCE_FREQ>>5))/(`SOURCE_FREQ>>4);

// We want an extra bit for rollover therefore no "-1"
logic [`ACCUMULATOR_WIDTH:0] baud_counter;
logic baud_tick;
logic baud_half_tick;
logic baud_quarter_tick;

// A 3 bit counter to count the bits.
logic [2:0] bitCnt;
logic [7:0] rx_bits;

assign baud_tick = baud_counter[`ACCUMULATOR_WIDTH];
assign baud_half_tick = baud_counter[`ACCUMULATOR_WIDTH-1];
assign baud_quarter_tick = baud_counter[`ACCUMULATOR_WIDTH-2];

always_ff @(posedge sourceClk) begin
    baud_counter <= baud_counter + COUNT_INC[`ACCUMULATOR_WIDTH:0];

    case (state)
        RxReset: begin
            rx_bits <= 0;
            rx_complete <= 0;
            baud_counter <= 0;
            rx_byte <= 0;
            state <= RxIdle;
        end

        RxIdle: begin
            rx_complete <= 0;
            // Detect Start bit falling edge
            if (Rx_fallingedge) begin
                state <= RxStartBit;
                rx_byte <= 0;
                rx_bits <= 0;
                baud_counter <= 0;
            end
        end

        RxStartBit: begin
            // hold for 1/2 bit period to shift to sample point position
            if (baud_half_tick == 1'b1) begin
                state <= RxHalfBit;
                baud_counter <= 0;
            end
        end

        RxHalfBit: begin
            // hold for 1 bit period to align with bit's approximate
            // half way sample point.
            if (baud_tick == 1'b1) begin
                state <= RxReceiving;
                baud_counter <= 0;
                // Sample first bit
                rx_bits <= {Rx_sync, rx_bits[7:1]};
                bitCnt <= 7;
            end
        end

        RxReceiving: begin
            // hold for 1 bit period
            if (baud_tick == 1'b1) begin
                if (bitCnt == 0) begin
                    state <= RxStopBit;
                end
                else begin
                    // Sample bit
                    rx_bits <= {Rx_sync, rx_bits[7:1]};
                    bitCnt <= bitCnt - 1;
                end

                baud_counter <= 0;
            end
        end

        RxStopBit: begin
            rx_byte <= rx_bits;

            // Check for Idle state.
            // We wait for a 1/4 or full bit period.
            `ifdef ONE_STOP_BIT
            if (baud_quarter_tick == 1'b1 & Rx_sync == 1)
            `elsif TWO_STOP_BITS
            if (baud_tick == 1'b1 & Rx_sync == 1)
            `endif
            begin
                state <= RxComplete;
                baud_counter <= 0;
                bitCnt <= 0;
                // hold "complete" signal for 1 cycle
                rx_complete <= 1;
            end
        end

        RxComplete: begin
            rx_complete <= 0;
            state <= RxIdle;
        end

        default: begin
        end
    endcase
end

endmodule

