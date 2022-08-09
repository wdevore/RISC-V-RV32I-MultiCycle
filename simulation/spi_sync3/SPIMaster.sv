`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// SPI Master only needs to sync on the Slave's MISO
module SPIMaster
(
    input  logic sysClk_i,            // system domain clock
    input  logic reset_i,
    input  logic send_i_n,            // Transmit data (CS)
    output logic mosi_o,              // output (1 bit at a time)
    input  logic miso_i,
    output logic spiClk_o,
    output logic ss_o_n,
    input  logic [7:0] byte_to_send_i,  // Data to send
    output logic [7:0] byte_received_o  // Data received
);

/*verilator public_module*/

logic [7:0] tx_data = byte_to_send_i;
logic [7:0] rx_data;

MasterState state;

logic [3:0] sysClkCnt;
logic spiClk;

// ----------------------------------------------------
// CDC Sync-ed signal for MISO (from slave)
// ----------------------------------------------------
logic MISO_risingedge;
logic MISO_fallingedge;
logic MISO_sync;

CDCSynchron SPI_MISO_Sync (
    .sysClk_i(spiClk),
    .async_i(miso_i),
    .sync_o(MISO_sync),
    .rising_o(MISO_risingedge),
    .falling_o(MISO_fallingedge)
);

// We handle SPI in 8-bit format,
// so we need a 3 bit counter to count the bits as they come in
logic [2:0] bitCnt;

// ---------------------------------------------------
// Simulation
// ---------------------------------------------------
initial begin
    $display("Master Sim init");
end

// The Master's SPI clock is fraction of the system clock.
assign spiClk = sysClkCnt[2];

// ----------------------------------------------
// TX: Master to Slave
// ----------------------------------------------

// This sync block tracks State and bit count.
always_ff @(posedge spiClk) begin
    case (state)
        MSReset: begin
            ss_o_n <= 1'b1;
            state <= MSIdle;
        end

        MSIdle: begin
            if (~send_i_n) begin
                ss_o_n <= 1'b0;
                bitCnt <= 3'b111;
                state <= MSBegin;
            end
        end

        MSBegin: begin
            bitCnt <= bitCnt - 3'b001;
            state <= MSTransmitting;
        end

        MSTransmitting: begin
            bitCnt <= bitCnt - 3'b001;
            if (bitCnt == 3'b000) begin
                state <= MSComplete;
            end
        end

        MSComplete: begin
            ss_o_n <= 1'b1;
            state <= MSIdle;
        end

        default: begin
        end
    endcase
end

// Data is sampled on the rising edge
always_ff @(posedge spiClk) begin
    case (state)
        MSBegin: begin
            byte_received_o <= {byte_received_o[6:0], miso_i};
        end

        MSTransmitting: begin
            byte_received_o <= {byte_received_o[6:0], miso_i};
        end

        MSComplete: begin
            byte_received_o <= {byte_received_o[6:0], miso_i};
        end

        default: begin
        end
    endcase
end

// Data is shifted out on the falling edge
always_ff @(negedge spiClk) begin
    case (state)
        MSBegin: begin
            mosi_o <= tx_data[bitCnt]; // The bit output
        end

        MSTransmitting: begin
            mosi_o <= tx_data[bitCnt]; // The bit output
        end

        MSComplete: begin
            rx_data <= byte_received_o;
            mosi_o <= 0;
        end

        default: begin
        end
    endcase
end

always_ff @(posedge sysClk_i) begin
    if (~reset_i) begin
        $display("sysClk_i resetting....");
        sysClkCnt <= 4'b0000;
    end
    else
        sysClkCnt <= sysClkCnt + 4'b0001;
end

// CPOL = 0 means clock is held low when not active.
assign spiClk_o = (~ss_o_n) ? spiClk : 1'b0;

endmodule

