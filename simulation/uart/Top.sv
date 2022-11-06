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


// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
SimState state = 0;
SimState next_state = 0;

logic tx_en = 0;
logic [7:0] tx_byte = 8'hA9;
logic tx_out;
logic tx_complete;
logic reset;
logic reset_complete;

always_comb begin
    next_state = SMReset;

    tx_en = 1'b1;

    case (state)
        SMSend: begin
            tx_en = 1'b0;
            next_state = SMSending;
        end

        SMSending: begin
            next_state = SMSending;
        end

        default: begin
        end
    endcase
end

always_ff @(posedge clock) begin
    case (state)
        SMReset: begin
            reset <= 1'b1;
            next_state = SMResetComplete;
        end

        SMResetComplete: begin
            reset_complete <= 1'b1;
            next_state = SMSend;
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

