`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// SPI Master only needs to sync on the Slave's MISO
module SPIMaster
(
    input  logic sysClk_i,            // system domain clock (PLL)
    input  logic reset_i,
    input  logic send_i_n,            // Transmit data
    output logic mosi_o,              // output (1 bit at a time)
    input  logic miso_i,
    output logic spiClk_o,
    output logic ss_o_n,
    input  logic [7:0] byte_to_send_i,  // Data to send
    output logic [7:0] byte_received_o, // Data received
    output logic tx_complete_o
);

/*verilator public_module*/

logic [7:0] tx_data = byte_to_send_i;
logic [7:0] rx_data;

TxState state /*verilator public*/;
TxState next_state /*verilator public*/;
// logic miso;

logic [3:0] sysClkCnt;
logic spiClk;

// ^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*
// Master sync signals
// ^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*

// ----------------------------------------------------
// CDC Sync-ed signal for MISO (from slave)
// ----------------------------------------------------
logic MISO_risingedge;
logic MISO_fallingedge;
// logic MISO_sync;

// CDCSynchron SPI_MISO_Sync (
//     .sysClk_i(spiClk),
//     .async_i(miso_i),
//     .sync_o(MISO_sync),
//     .rising_o(MISO_risingedge),
//     .falling_o(MISO_fallingedge)
// );

// We handle SPI in 8-bit format,
// so we need a 3 bit counter to count the bits as they come in
logic [2:0] bitCnt;

// ---------------------------------------------------
// Simulation
// ---------------------------------------------------
initial begin
    $display("Sim init");
    state = Reset;
    next_state = Idle;
end

assign spiClk = sysClkCnt[2];

// ----------------------------------------------
// TX: Master to Slave
// ----------------------------------------------
always_comb begin
    ss_o_n = 1'b1;  // Not transmitting
    next_state = Reset;
    
    case (state)
        Reset: begin
            // Put stuff here that needs to be done
            // prior to idling.
            next_state = Idle;
        end

        Idle: begin
            // On falling edge of Idle state we begin placing the bit on MISO
            // As soon as the send signal is sensed we transition
            // to Transmitting.
            
            if (~send_i_n)
                next_state = BeginTx;
            else
                next_state = Idle;
        end

        BeginTx: begin
            ss_o_n = 1'b0;   // /ss is active low when transmitting
            next_state = Transmitting;
        end

        Transmitting: begin
            ss_o_n = 1'b0;   // /ss is active low when transmitting
            // We know we are complete when the count reaches 0
            // otherwise we keep transmitting. The bit count is
            // incremented in the sync block because it is a synchronous
            // counter.
            if (bitCnt == 3'b000)
                next_state = Complete;
            else
                next_state = Transmitting;
        end

        // The Complete state does nothing for now. You can remove it
        // if you don't need it.
        Complete: begin
            // ss_o_n = 1'b0;   // /ss is active low when transmitting
            next_state = Idle;
        end

        default: begin
            next_state = Idle;
        end
    endcase
end

// Reset is synchronous with the SPI clock and not the system clock
// because "state" is also managed by the SPI clock and we can't
// mix states between clocks--not good--Verilator knows better than
// to allow you to do that :-)
always_ff @(posedge spiClk) begin
    if (~reset_i) begin
        state <= Idle;
    end
    else begin
        // $display("move from (%d) to next state: %d", state, next_state);
        state <= next_state;
    end

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

always_ff @(posedge sysClk_i) begin
    if (~reset_i) begin
        sysClkCnt <= 4'b0000;
    end
    else
        sysClkCnt <= sysClkCnt + 4'b0001;
end

// Data shifted out on falling edge.
always_ff @(negedge spiClk) begin     // Mode 0
    if (state == Transmitting) begin
        mosi_o <= tx_data[bitCnt]; // The bit output
    end
end

// Data sampled on rising edge
always_ff @(posedge spiClk) begin     // Mode 0
    if (state == Idle) begin
        byte_received_o <= 8'b00000000;
    end
    else if (bitCnt > 3'b000) begin
        byte_received_o <= {byte_received_o[6:0], miso_i};
    end
end

// CPOL = 0
// assign spiClk_o = (~ss_o_n) ? spiClk : 1'b0;
assign spiClk_o = spiClk;

endmodule

