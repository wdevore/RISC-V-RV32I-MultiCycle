`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// Top interfaces with the fpga

`define TX_BYTES 4
`define RX_BYTES 4

module Top (
    input  logic clk,        // 25MHz
    output logic led,
    output logic [5:0] blade1
);

// Div 5 bits to get ~500KHz
// 5'b11111
logic [4:0] divider;
logic spiClk;
assign spiClk = divider[4];

// -----------------------------------------------------------
// IO Module
// -----------------------------------------------------------
logic [`TX_BYTES-1:0] tx_addr;
logic [`DATA_WIDTH-1:0] tx_byte;
logic tx_wr;
logic [`RX_BYTES-1:0] rx_addr;
logic [`DATA_WIDTH-1:0] rx_byte;
logic rx_rd;
logic mosi;
logic miso;
logic cs;
logic send;
logic io_complete;

// -----------------------------------------------------------------
// Slave that interacts with Pico. It detects certain sequences and
// responds
// -----------------------------------------------------------------
SPISlave slave (
    .sysClk(clk),
    .spiClk(spiClk),
    .cs(cs),
    .mosi(mosi),
    .miso(miso)
);

// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
IOState state;
IOState next_state;
logic reset_complete /*verilator public*/;

logic [1:0] tx_byte_cnt;
logic [2:0] send_cnt;

always_comb begin
    next_state = SMBoot;
    reset_complete = 1'b1;   // Default: Reset is complete

    tx_wr = 1'b1;
    tx_byte = 8'h00;
    rx_rd = 1'b1;

    case (state)
        SMBoot: begin
            reset_complete = 1'b0;
            if (~Rst_i_n) begin
                next_state = SMReset;
            end
        end

        SMReset: begin
            next_state = IOIdle;
        end

        SMIdle: begin
            next_state = IOIdle;

            if (send_cnt == 3'b000)
                next_state = SMBeginWrite;
        end

        SMBeginWrite: begin
            tx_wr = 1'b1;
            if (tx_byte_cnt == 2'b11)
                next_state = SMSend;
            else
                next_state = SMWrite;
        end

        SMWrite: begin
            next_state = SMBeginWrite;
            
            tx_wr = 1'b0;

            // Write bytes to IO module
            case (tx_byte_cnt)
                2'b00: begin
                    tx_byte = 8'hA1;
                end
                2'b01: begin
                    tx_byte = 8'h2A;
                end
                2'b10: begin
                    tx_byte = 8'h32;
                end

                default: begin
                end
            endcase
        end

        SMSend: begin
            next_state = SMSend;
            if (io_complete) begin
                next_state = IOIdle;
            end
        end

        default: begin
        end
    endcase
end


always_ff @(posedge clk) begin
    divider <= divider + 5'b00001;
end

endmodule

