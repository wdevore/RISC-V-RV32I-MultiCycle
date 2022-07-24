`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// With CS signal
module SPIMaster
#(
    parameter SPI_MODE /*verilator public*/ = 0,
    parameter CLKS_PER_HALF_BIT /*verilator public*/ = 2,
    parameter MAX_BYTES_PER_CS /*verilator public*/ = 1,
    parameter CS_INACTIVE_CLKS /*verilator public*/ = 1
)
(
    // Control/Data Signals,
    input logic        i_Rst_L,     // FPGA Reset
    input logic        i_Clk,       // FPGA Clock

    // TX (MOSI) Signals
    input  logic [$clog2(MAX_BYTES_PER_CS+1)-1:0] i_TX_Count,  // # bytes per CS low
    input  logic [7:0]  i_TX_Byte,       // Byte to transmit on MOSI
    input  logic        i_TX_DV,         // Data Valid Pulse with i_TX_Byte
    output logic        o_TX_Ready,      // Transmit Ready for next byte w_Master_Ready

    // RX (MISO) Signals
    output logic [$clog2(MAX_BYTES_PER_CS+1)-1:0] o_RX_Count,  // Index RX byte
    output logic       o_RX_DV,     // Data Valid pulse (1 clock cycle)
    output logic [7:0] o_RX_Byte,   // Byte received on MISO

    // SPI Interface
    output logic o_SPI_Clk,
    input  logic i_SPI_MISO,
    output logic o_SPI_MOSI,
    output logic o_SPI_CS_n
);

/*verilator public_module*/

localparam IDLE        = 2'b00;
localparam TRANSFER    = 2'b01;
localparam CS_INACTIVE = 2'b10;

logic [1:0] r_SM_CS;
logic r_CS_n;
/* verilator lint_off LITENDIAN */
logic [$clog2(CS_INACTIVE_CLKS)-1:0] r_CS_Inactive_Count;
/* verilator lint_on LITENDIAN */

// How many bytes to transmit within a single active chip select.
logic [$clog2(MAX_BYTES_PER_CS+1)-1:0] r_TX_Count;
logic w_Master_Ready;

// SPI master instance
SPIProtocol #(
    .SPI_MODE(SPI_MODE),
    .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)
) SPI_Protocol_Inst (
    // Control/Data Signals,
    .i_Rst_L(i_Rst_L),     // FPGA Reset
    .i_Clk(i_Clk),         // FPGA Clock

    // TX (MOSI) Signals
    .i_TX_Byte(i_TX_Byte),         // Byte to transmit
    // TX_DV is controlled by an external source indicating that
    // data is available to transmit.
    .i_TX_DV(i_TX_DV),             // Data Valid Pulse 
    .o_TX_Ready(w_Master_Ready),   // Transmit Ready for Byte

    // RX (MISO) Signals
    .o_RX_DV(o_RX_DV),       // Data Valid pulse (1 clock cycle)
    .o_RX_Byte(o_RX_Byte),   // Byte received on MISO

    // SPI Interface
    .o_SPI_Clk(o_SPI_Clk),
    .i_SPI_MISO(i_SPI_MISO),
    .o_SPI_MOSI(o_SPI_MOSI)
);

// Purpose: Control CS line using State Machine
always_ff @(posedge i_Clk or negedge i_Rst_L) begin
    if (~i_Rst_L) begin
        r_SM_CS <= IDLE;
        r_CS_n  <= 1'b1;   // Resets to high
        r_TX_Count <= 0;
        r_CS_Inactive_Count <= CS_INACTIVE_CLKS;
    end
    else begin
        case (r_SM_CS)
            IDLE: begin
                if (r_CS_n & i_TX_DV) begin // Start of transmission
                    r_TX_Count <= i_TX_Count - 1'b1; // Register TX Count
                    r_CS_n     <= 1'b0;       // Drive CS low
                    r_SM_CS    <= TRANSFER;   // Transfer bytes
                end
            end

            TRANSFER: begin
                // Wait until SPI is done transferring do next thing
                if (w_Master_Ready) begin
                    // Check if done with a burst of transactions
                    // We can tell if we haven't finish by inspecting the
                    // count. Count is decreasing until it reaches 0.
                    if (r_TX_Count > 0) begin
                        // Wait for the next Data-valid pulse to occur.
                        if (i_TX_DV) begin
                            // Decrement. Now the Protocol will work on
                            // the next Byte--if there is one.
                            r_TX_Count <= r_TX_Count - 1'b1;
                        end
                    end
                    else begin
                         // We are done sending byte(s), Set CS high
                        r_CS_n  <= 1'b1;
                        // How long we remain inactive between CSs
                        // before transitioning to the IDLE state.
                        r_CS_Inactive_Count <= CS_INACTIVE_CLKS;
                        r_SM_CS             <= CS_INACTIVE;
                    end
                end
            end

            CS_INACTIVE: begin
                if (r_CS_Inactive_Count > 0) begin
                    r_CS_Inactive_Count <= r_CS_Inactive_Count - 1'b1;
                end
                else begin
                    r_SM_CS <= IDLE;
                end
            end

            default: begin
                r_CS_n  <= 1'b1; // we done, so set CS high
                r_SM_CS <= IDLE;
            end
        endcase
    end
end

// Purpose: Keep track of RX_Count
always @(posedge i_Clk) begin
    if (r_CS_n) begin
        o_RX_Count <= 0;
    end
    else if (o_RX_DV) begin
        o_RX_Count <= o_RX_Count + 1'b1;
    end
end

assign o_SPI_CS_n = r_CS_n;

// TX ready is active if in the IDLE or
// we are in the process of sending bytes and Protocol is ready and we haven't finished sending bytes.
assign o_TX_Ready = ((r_SM_CS == IDLE) | (r_SM_CS == TRANSFER && w_Master_Ready == 1'b1 && r_TX_Count > 0)) & ~i_TX_DV;

endmodule

