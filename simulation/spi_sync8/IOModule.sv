`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// The Slave module is just for testing. 
// This module will typically ...

// Half duplex
// Transmits N bytes from a buffer and receives M bytes into a buffer.
// It uses a SPIMaster to perform the bit transmissions.
// When both byte-counts reach zero then the IO Trx is complete
//
// Call *reset* first
// 
module IOModule
#(
    parameter CLK_DIVIDER = 3,
    parameter DATA_WIDTH = 8,
    parameter TX_BYTES = 4, // 16 bytes
    parameter RX_BYTES = 4  // 16 bytes
)
(
    input  logic sysClk,        // system domain clock
    input  logic reset,         // Reset for a new Trx (active low)
    input  logic send,          // Initiate data transmission (active low)
    output logic io_complete,   // Last byte sent and/or received

    // Data IO
    input  logic [TX_BYTES-1:0]   tx_addr,  // Address of tx buffer byte
    input  logic [DATA_WIDTH-1:0] tx_byte,  // Data to write to tx buffer
    input  logic                  tx_wr,    // Write byte to buffer (active low)

    input  logic [RX_BYTES-1:0]   rx_addr,  // Address of rx buffer byte
    output logic [DATA_WIDTH-1:0] rx_byte,  // Data read from rx buffer
    input  logic                  rx_rd,    // read byte from buffer (active low)

    // SPI IO
    output logic spiClk,    // SPI Clock output
    output logic mosi,      // output (1 bit at a time) routed to Slave
    input  logic miso,      // Bit from Slave
    output logic cs         // CS directed at Slave
);

/*verilator public_module*/

// How many SPI clocks between each byte.
logic [3:0] gapCnt;

// ------------------------------------------------------------------------
// IO buffers
// ------------------------------------------------------------------------
// Send buffer
logic [TX_BYTES-1:0] tx_byte_cnt;  // Start at count and decrements to 0.
// Always starts at 0 and counts up.
logic [TX_BYTES-1:0] tx_addr_idx;
logic [TX_BYTES-1:0] tx_str_addr;
logic tx_rd;
logic [DATA_WIDTH-1:0] byte_to_send;

logic byte_sent;

// Use either the address given externally or the internal
// address (tx_str_addr).
assign tx_addr_idx = ~tx_wr ? tx_addr : tx_str_addr;

Memory #(
    .WORDS(TX_BYTES),
    .DATA_WIDTH(`DATA_WIDTH)
) tx_buf (
    .clk_i(sysClk),
    .data_i(tx_byte),
    .addr_i(tx_addr_idx),
    .wr_i(tx_wr),
    .rd_i(tx_rd),
    .data_o(byte_to_send)
);

// Receive buffer
logic rx_wr;
logic [DATA_WIDTH-1:0] byte_from_slave;

logic [RX_BYTES-1:0] rx_str_addr;

Memory #(
    .WORDS(TX_BYTES),
    .DATA_WIDTH(`DATA_WIDTH)
) rx_buf (
    .clk_i(sysClk),
    .data_i(byte_from_slave),
    .addr_i(rx_str_addr),
    .wr_i(rx_wr),
    .rd_i(rx_rd),
    .data_o(rx_byte)
);

// ------------------------------------------------------------------------
// SPI module
// ------------------------------------------------------------------------
logic [3:0] sysClkCnt;

logic mastSpiClk;
logic p_mastSpiClk;

// The SPI clock is fraction of the system clock.
// Instead of a divider I'm using a counter for a bit
// more resolution.
// assign mastSpiClk = sysClkCnt[CLK_DIVIDER];

SPIMaster master (
    .sysClk(sysClk),
    .spiClk(mastSpiClk),
    .outSpiClk(spiClk),          // Gated clock
    .reset(reset),
    .tx_en(spi_send),                   // Assert when ready to send byte
    .mosi(mosi),
    .miso(miso),
    .tx_byte(byte_to_send),
    .byte_tx_complete(byte_sent),
    .rx_byte(byte_from_slave)
);

// ------------------------------------------------------------------------
// State machine
// ------------------------------------------------------------------------
IOState state;
IOState next_state;
// Once the reset sequence has completed this flag is Set.
logic reset_complete /*verilator public*/;

logic spi_send;
logic p_byte_sent;

logic byte_sent_falling;
assign byte_sent_falling = p_byte_sent == 1'b1 && byte_sent == 1'b0;

logic p_spiClk;
logic spiClk_falling;
assign spiClk_falling = p_spiClk == 1'b1 && spiClk == 1'b0;

// Only write the received byte on the last spiClk cycle
// and when the slave has finished sending it.
assign rx_wr = ~(spiClk_falling && byte_sent);

always_comb begin
    next_state = IOReset;
    reset_complete = 1'b1;  // Default: Reset is complete
    tx_rd = 1'b1;
    spi_send = 1'b1;
    io_complete = 1'b0;     // Default: IO Transfer not complete
    cs = 1'b1;

    case (state)
        IOBoot: begin
            next_state = IOBoot;

            reset_complete = 1'b0;
            if (~reset)
                next_state = IOReset;
        end

        IOReset: begin
            next_state = IOIdle;
            reset_complete = 1'b0;
        end

        IOIdle: begin
            next_state = IOIdle;

            if (~send) begin
                next_state = IOBegin;
            end
        end

        IOBegin: begin
            next_state = IOBegin;
            cs = 1'b0;
            // Wait for the rising edge of the master clock.
            if (p_mastSpiClk == 1'b0 && mastSpiClk == 1'b1) begin
                next_state = IOSend;
                // Fetch byte from buffer
                tx_rd = 1'b0;
            end
        end

        IOSend: begin
            next_state = IOSend;
            cs = 1'b0;

            // The byte is ready. Send data via SPI Master
            spi_send = 1'b0;
            
            if (byte_sent_falling) begin
                next_state = IONext;
                // Pause SPI
                spi_send = 1'b1;

                if (tx_addr_idx == tx_byte_cnt - 1)
                    next_state = IOComplete;
            end
        end

        IONext: begin
            next_state = IOSend;
            cs = 1'b0;

            tx_rd = 1'b0;
        end

        IOComplete: begin
            next_state = IOIdle;

            io_complete = 1'b1;
        end

        default: begin
        end
    endcase
end

always_ff @(posedge sysClk) begin
    p_byte_sent = byte_sent;
    p_spiClk = spiClk;
    p_mastSpiClk = mastSpiClk;

    if (~reset) begin
        state <= IOReset;
    end
    else
        state <= next_state;

    case (state)
        IOIdle: begin
            tx_str_addr <= 4'b0000;
            rx_str_addr <= 4'b0000;
            if (~tx_wr)
                tx_byte_cnt <= tx_byte_cnt + 4'b0001;
        end

        IOSend: begin
            if (byte_sent_falling) begin
                tx_str_addr <= tx_str_addr + 4'b0001;
            end
        end

        IONext: begin
            rx_str_addr <= rx_str_addr + 4'b0001;
        end

        IOComplete: begin
            tx_byte_cnt <= 4'b0000;
        end

        default: begin
        end
    endcase

    sysClkCnt <= sysClkCnt + 4'b0001;
    if (sysClkCnt == 4'b0101) begin
        mastSpiClk <= ~mastSpiClk;
        sysClkCnt <= 4'b0000;
    end
end

endmodule

