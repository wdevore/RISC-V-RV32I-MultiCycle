`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// Top creates an IOModule.
// It writes 3 bytes to the Tx buffer and send them

`define TX_BYTES 4
`define RX_BYTES 4

module Top (
    input logic  Rst_i_n,      // System Reset
    input logic  pllClk_i      // System High Freq Clock (PLL)
);

logic spiClk_o;

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

IOModule io (
    .sysClk(pllClk_i),      // system domain clock
    .reset(Rst_i_n),        // Reset for a new Trx (active low)
    .send(send),            // Initiate data transmission (active low)
    .io_complete(io_complete),

    // Data IO
    .tx_addr(tx_addr),         // Address of tx buffer byte
    .tx_byte(tx_byte),         // Data to write to tx buffer
    .tx_wr(tx_wr),

    .rx_addr(rx_addr),         // Address of rx buffer byte
    .rx_byte(rx_byte),         // Data read from rx buffer
    .rx_rd(rx_rd),

    // SPI IO
    .spiClk(spiClk_o),  // SPI Clock output
    .mosi(mosi),        // output (1 bit at a time) routed to Slave
    .miso(miso),        // Bit from Slave
    .cs(cs)             // CS directed at Slave
);

// -----------------------------------------------------------------
// Simulated target device
// -----------------------------------------------------------------
SPISlave slave (
    .sysClk(pllClk_i),
    .spiClk(spiClk_o),
    .cs(cs),
    .mosi(mosi),
    .miso(miso)
);

// This would be the data the Pico sends as the second byte
localparam [7:0] io_con = 8'h0A;
localparam [7:0] io_dir = 8'h00;

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
                    tx_byte = 8'h41;
                end
                2'b01: begin
                    tx_byte = io_dir; // or io_dir
                end
                2'b10: begin
                    tx_byte = 8'h00;
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

always_ff @(posedge pllClk_i) begin
    send <= 1'b1;

    case (state)
        SMBoot: begin
            $display("SYNC SMBoot");
        end

        SMReset: begin
            $display("SYNC SMReset");
            tx_byte_cnt <= 2'b00;
            tx_addr <= 4'b0000;
            send_cnt <= 3'b000;
        end

        SMWrite: begin
            $display("SYNC SMWrite");
            tx_byte_cnt <= tx_byte_cnt + 2'b01;
            tx_addr <= tx_addr + 4'b0001;
            send_cnt <= send_cnt + 3'b001;
        end

        SMSend: begin
            // De-assert "send" when the last byte is sent.
            if (~io_complete) begin
                send <= 1'b0;
            end
        end

        default: begin
        end
    endcase
end

always_ff @(posedge pllClk_i) begin
    if (~Rst_i_n) begin
        state <= SMReset;
    end
    else begin
        if (reset_complete) begin
            state <= next_state;
        end
    end
end

endmodule

