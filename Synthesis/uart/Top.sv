`default_nettype none

module Top (
    input  logic clk ,          // 25MHz Clock from board
    input  logic pm6a0,         // rx_in
    output logic pm6a1,         // tx_out
    output logic [5:0] blade1,  // Display Tx/Rx status
    output logic [11:0] tile1
);

// This module takes the incoming byte and displays it on the 7seg
// and responds with "Ok" via the Tx pin.
logic tx_en;
logic [7:0] tx_byte;
logic tx_out;
logic tx_complete;

UARTTx uart_tx (
    .sourceClk(clk),
    .reset(reset),
    .tx_en(tx_en),
    .tx_byte(tx_byte),
    .tx_out(pm6a1),
    .tx_complete(tx_complete)
);

logic rx_complete;
logic p_rx_complete;
logic [7:0] rx_byte;

UARTRx uart_rx (
    .sourceClk(clk),
    .reset(reset),
    .rx_in(pm6a0),
    .rx_byte(rx_byte),
    .rx_complete(rx_complete)
);

// ------------------------------------------------------------------------
// Blade
// ------------------------------------------------------------------------
assign blade1[0] = pm6a0; // Tx = Red
assign blade1[1] = 1'b1;
assign blade1[2] = pm6a1; // Rx = Yellow
assign blade1[3] = 1'b1;
assign blade1[4] = 1'b1;
assign blade1[5] = 1'b1;

// ------------------------------------------------------------------------
// 7Seg
// ------------------------------------------------------------------------
logic [3:0] digitOnes;
logic [3:0] digitTens;

SevenSeg segs(
  .clk(clk),
  .digitL(4'b0),
  .digitM(digitTens),
  .digitR(digitOnes),
  .tile1(tile1)
);

logic [7:0] display_byte;
assign digitOnes = (display_byte)       % 16;
assign digitTens = (display_byte / 16)  % 16;

// ------------------------------------------------------------------------
// State machine controlling module
// ------------------------------------------------------------------------
ControlState state = 0;
ControlState next_state = 0;

logic reset;
logic [1:0] cnt_byte;

always_ff @(posedge clk) begin
    case (state)
        CSReset: begin
            reset <= 1'b1;
            cnt_byte <= 0;
            tx_en <= 1;         // Disable transmission
            p_rx_complete <= 0;
            next_state <= CSReset1;
        end

        CSReset1: begin
            reset <= 1'b0;
            next_state <= CSResetComplete;
        end

        CSResetComplete: begin
            reset <= 1'b1;
            next_state <= CSIdle;
        end

        CSIdle: begin
            // Wait for a byte to arrive then store it.
            if (~p_rx_complete & rx_complete) begin
                // An ASCII byte has arrived. Convert and display it
                // 0x30->0x39 and 0x61->0x66
                //   0 -> 9          a -> b 
                if (rx_byte > 8'h39)
                    display_byte <= rx_byte - 8'h57;
                else
                    display_byte <= rx_byte - 8'h30;
                
                next_state <= CSSend;
            end
            p_rx_complete <= rx_complete;
        end

        CSSend: begin
            tx_en <= 0; // Enable transmission
            next_state <= CSSending;

            // Send "Ok" string back.
            case (cnt_byte)
                2'b00:
                    tx_byte <= 8'h4F;  // "O"
                2'b01:
                    tx_byte <= 8'h6B;  // "k"
                2'b10:
                    tx_byte <= 8'h0D;  // Carriage return
                2'b11:
                    tx_byte <= 8'h0A;  // Line Feed
            endcase
        end

        CSSending: begin
            tx_en <= 1; // Disable transmission
            
            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                if (cnt_byte == 2'b11) begin
                    next_state <= CSIdle;
                    cnt_byte <= 0;
                end
                else begin
                    next_state <= CSSend;
                    cnt_byte <= cnt_byte + 1;
                end
            end
        end

        default: begin
        end
    endcase

    state <= next_state;
end

endmodule

