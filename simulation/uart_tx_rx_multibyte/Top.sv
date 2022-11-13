`default_nettype none
`ifdef SIMULATE
`timescale 10ns/1ns
`endif

module Top (
    input logic  clock       // System High Freq Clock
);


UARTTx uart_tx (
    .sourceClk(clock),
    .reset(reset),
    .tx_en(tx_en),
    .tx_byte(tx_byte),
    .tx_out(tx_out),
    .tx_complete(tx_complete)
);

UARTRx uart_rx (
    .sourceClk(clock),
    .reset(reset),
    .rx_in(tx_out),
    .rx_byte(rx_byte),
    .rx_complete(rx_complete)
);


// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
SimState state = 0;
SimState next_state;

logic tx_en;
logic [7:0] tx_byte;
logic tx_out;
logic tx_complete;

/* verilator lint_off UNUSED */
logic rx_complete;
logic [7:0] rx_byte;

logic reset;
logic reset_complete;
/* verilator lint_on UNUSED */
logic [1:0] cnt_byte;

always_ff @(posedge clock) begin
    case (state)
        SMReset: begin
            reset <= 1'b1;
            cnt_byte <= 0;
            tx_en <= 1;
            next_state <= SMResetComplete;
        end

        SMSend: begin
            tx_en <= 0;
            next_state <= SMSending;
            case (cnt_byte)
                2'b00:
                    tx_byte <= 8'hA9;  // 10101001 = -__-_-_-
                2'b01:
                    tx_byte <= 8'hF2;  // 11110010 = _-__----
                2'b10:
                    tx_byte <= 8'h18;  // 00011000 = ___--___
                2'b11:
                    tx_byte <= 8'h81;  // 10000001 = -______-
            endcase
        end

        SMSending: begin
            tx_en <= 1;
            if (tx_complete) begin
                next_state <= SMSend;
                if (cnt_byte == 2'b11) begin
                    next_state <= SMStop;
                end
                cnt_byte <= cnt_byte + 1;
            end
            else
                next_state <= SMSending;
        end

        SMStop: begin
            next_state <= SMStop;
        end

        SMResetComplete: begin
            reset_complete <= 1'b1;
            next_state <= SMSend;
        end

        default: begin
        end
    endcase

    if (~reset)
        state <= SMReset;
    else
        state <= next_state;
end

endmodule

