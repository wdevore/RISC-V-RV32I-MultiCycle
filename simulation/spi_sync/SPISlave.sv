`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// SPI Slave needs to sync on 3 signals from Master:
// 1) SClk
// 2) MOSI
// 3) /SS

// Transmit on rising edge of SClk and received on falling edge.

module SPISlave
(
    input  logic sysClk_i,            // system domain clock (PLL)
    input  logic reset_i,
    output logic transmitting_o,
    input  logic mosi_i,              // output (1 bit at a time)
    output logic miso_o,
    input  logic sclk_i,
    input  logic ss_i_n,
    input  logic [7:0] byte_to_send_i,  // Data to send
    output logic [7:0] byte_received_o, // Data received
    output logic tx_complete_o
);

/*verilator public_module*/

logic [7:0] tx_data = byte_to_send_i;
logic [7:0] rx_data;

TxState state /*verilator public*/;
TxState next_state /*verilator public*/;
logic mosi;
logic [7:0] byte_received;

// ^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*
// Slave sync signals
// ^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*

// ----------------------------------------------------
// CDC Sync-ed signal for SClk (from master)
// ----------------------------------------------------
logic SClk_risingedge;
logic SClk_fallingedge;
logic SClk_sync;

CDCSynchron SPI_SClk_Sync (
    .sysClk_i(sysClk_i),
    .async_i(sclk_i),
    .sync_o(SClk_sync),
    .rising_o(SClk_risingedge),
    .falling_o(SClk_fallingedge)
);

// ----------------------------------------------------
// CDC Sync-ed signal for MOSI (from master)
// ----------------------------------------------------
logic MOSI_risingedge;
logic MOSI_fallingedge;
logic MOSI_sync;

CDCSynchron SPI_MOSI_Sync (
    .sysClk_i(sysClk_i),
    .async_i(mosi_i),
    .sync_o(MOSI_sync),
    .rising_o(MOSI_risingedge),
    .falling_o(MOSI_fallingedge)
);

// ----------------------------------------------------
// CDC Sync-ed signal for /SS (from master)
// ----------------------------------------------------
logic SS_risingedge;
logic SS_fallingedge;
logic SS_sync;

CDCSynchron SPI_SS_Sync (
    .sysClk_i(sysClk_i),
    .async_i(ss_i_n),
    .sync_o(SS_sync),
    .rising_o(SS_risingedge),
    .falling_o(SS_fallingedge)
);

// We handle SPI in 8-bit format,
// so we need a 3 bits counter to count the bits as they come in
logic [2:0] bitCnt;

// ---------------------------------------------------
// Simulation
// ---------------------------------------------------
initial begin
    $display("Sim init");

    // Be default the CPU always attempts to start in Reset mode.
    state = Idle;
    next_state = Idle;
    bitCnt = 3'b111;
end

// ----------------------------------------------
// TX: Slave to Master
// ----------------------------------------------
always_comb begin
    transmitting_o = 1'b1;   // not transmitting
    next_state = Idle;
    miso_o = 1'b0;

    case (state)
        Idle: begin
            if (~SS_sync)
                next_state = Transmitting;
            else
                next_state = Idle;
        end

        Transmitting: begin
            transmitting_o = 1'b0;

            miso_o = tx_data[bitCnt];

            if (bitCnt == 3'b000) begin
                next_state = Idle;
            end
            else begin
                next_state = Transmitting;
            end
        end

        default: begin
            next_state = Idle;
        end
    endcase
end

// This SPI module is the Slave and as such we synchronize on
// the Synced SPI clock and not the incoming SPI clock.
// The Slave may be in a different clock domain so we need to
// use the sync signal instead. The other way is to FIFOs if
// that desirable or the only option.
always_ff @(posedge SClk_sync) begin
    state <= next_state;

    case (state) 
        Idle: begin
            // Maintain bit count at Most-Significant-bit (MSb)
            bitCnt <= 3'b111;
        end

        Transmitting: begin
            // Count down from MSb to LSb
            bitCnt <= bitCnt - 3'b001;
        end

        default: begin
        end
    endcase
end

`ifdef MODE0
always_ff @(negedge SClk_sync) begin  // Mode 0
`elsif MODE1
always_ff @(posedge SClk_fallingedge) begin  // Mode 1
`endif
    if (state == Idle) begin
        byte_received_o <= 8'b00000000;
    end
    else if (state == Transmitting) begin
        // Receive on the falling edge
        // We use Shift-left register (since we receive the data MSb first)
        byte_received_o <= {byte_received_o[6:0], MOSI_sync};
    end
end

endmodule

