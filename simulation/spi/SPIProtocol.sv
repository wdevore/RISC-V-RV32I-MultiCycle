`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// Aka SPI_Master from nandland

module SPIProtocol
#(
    parameter SPI_MODE = 0,
    parameter CLKS_PER_HALF_BIT = 2
)
(
    // Control/Data Signals,
    input logic        i_Rst_L,     // FPGA Reset
    input logic        i_Clk,       // FPGA Clock

    // TX (MOSI) Signals
    input  logic [7:0]  i_TX_Byte,        // Byte to transmit on MOSI
    input  logic        i_TX_DV,          // Data Valid Pulse with i_TX_Byte
    output logic        o_TX_Ready,       // Transmit Ready for next byte

    // RX (MISO) Signals
    output logic       o_RX_DV,     // Data Valid pulse (1 clock cycle)
    output logic [7:0] o_RX_Byte,   // Byte received on MISO

    // SPI Interface
    output logic o_SPI_Clk,
    input  logic i_SPI_MISO,
    output logic o_SPI_MOSI
);

/*verilator public_module*/

// SPI Interface (All Runs at SPI Clock Domain)
logic w_CPOL;     // Clock polarity
logic w_CPHA;     // Clock phase

logic [$clog2(CLKS_PER_HALF_BIT*2)-1:0] r_SPI_Clk_Count;
logic r_SPI_Clk;
logic [4:0] r_SPI_Clk_Edges;
logic r_Leading_Edge;
logic r_Trailing_Edge;
logic       r_TX_DV;
logic [7:0] r_TX_Byte;

logic [2:0] r_RX_Bit_Count;
logic [2:0] r_TX_Bit_Count;

// CPOL: Clock Polarity
// CPOL=0 means clock idles at 0, leading edge is rising edge.
// CPOL=1 means clock idles at 1, leading edge is falling edge.
assign w_CPOL  = (SPI_MODE == 2) | (SPI_MODE == 3);

// CPHA: Clock Phase
// CPHA=0 means the "out" side changes the data on trailing edge of clock
//              the "in" side captures data on leading edge of clock
// CPHA=1 means the "out" side changes the data on leading edge of clock
//              the "in" side captures data on the trailing edge of clock
assign w_CPHA  = (SPI_MODE == 1) | (SPI_MODE == 3);

// Purpose: Generate SPI Clock correct number of times when DV pulse comes
always_ff @(posedge i_Clk or negedge i_Rst_L) begin
    if (~i_Rst_L) begin
        o_TX_Ready      <= 1'b0;
        r_SPI_Clk_Edges <= 0;
        r_Leading_Edge  <= 1'b0;
        r_Trailing_Edge <= 1'b0;
        r_SPI_Clk       <= w_CPOL; // assign default state to idle state
        r_SPI_Clk_Count <= 0;
    end
    else begin
        // Default assignments
        r_Leading_Edge  <= 1'b0;
        r_Trailing_Edge <= 1'b0;

        if (i_TX_DV) begin
            o_TX_Ready      <= 1'b0;
            r_SPI_Clk_Edges <= 16;  // Total # edges in one byte ALWAYS 16
        end
        else if (r_SPI_Clk_Edges > 0) begin
            o_TX_Ready <= 1'b0;

            if (r_SPI_Clk_Count == CLKS_PER_HALF_BIT*2-1) begin
                r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1'b1;
                r_Trailing_Edge <= 1'b1;
                r_SPI_Clk_Count <= 0;
                r_SPI_Clk       <= ~r_SPI_Clk;
            end
            else if (r_SPI_Clk_Count == CLKS_PER_HALF_BIT-1) begin
                r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1'b1;
                r_Leading_Edge  <= 1'b1;
                r_SPI_Clk_Count <= r_SPI_Clk_Count + 1'b1;
                r_SPI_Clk       <= ~r_SPI_Clk;
            end
            else begin
                r_SPI_Clk_Count <= r_SPI_Clk_Count + 1'b1;
            end
        end
        else begin
            o_TX_Ready <= 1'b1;
        end

    end
end

// Purpose: Register i_TX_Byte when Data Valid is pulsed.
// Keeps local storage of byte in case higher level module changes the data
always_ff @(posedge i_Clk or negedge i_Rst_L) begin
    if (~i_Rst_L) begin
        r_TX_Byte <= 8'h00;
        r_TX_DV   <= 1'b0;
    end
    else begin
        r_TX_DV <= i_TX_DV; // 1 clock cycle delay
        if (i_TX_DV) begin
            r_TX_Byte <= i_TX_Byte;
        end
    end
end

// Purpose: Generate MOSI data
// Works with both CPHA=0 and CPHA=1
always_ff @(posedge i_Clk or negedge i_Rst_L) begin
    if (~i_Rst_L) begin
        o_SPI_MOSI     <= 1'b0;
        r_TX_Bit_Count <= 3'b111; // send MSb first
    end
    else begin
        // If ready is high, reset bit counts to default
        if (o_TX_Ready) begin
            r_TX_Bit_Count <= 3'b111;
        end
        // Catch the case where we start transaction and CPHA = 0
        else if (r_TX_DV & ~w_CPHA) begin
            o_SPI_MOSI     <= r_TX_Byte[3'b111];
            r_TX_Bit_Count <= 3'b110;
        end
        else if ((r_Leading_Edge & w_CPHA) | (r_Trailing_Edge & ~w_CPHA)) begin
            r_TX_Bit_Count <= r_TX_Bit_Count - 1'b1;
            o_SPI_MOSI     <= r_TX_Byte[r_TX_Bit_Count];
        end
    end
end

// Purpose: Read in MISO data.
always_ff @(posedge i_Clk or negedge i_Rst_L) begin
    if (~i_Rst_L) begin
        o_RX_Byte      <= 8'h00;
        o_RX_DV        <= 1'b0;
        r_RX_Bit_Count <= 3'b111;
    end
    else begin
        // Default Assignments
        o_RX_DV <= 1'b0;

        // Check if ready is high, if so reset bit count to default
        if (o_TX_Ready) begin
            r_RX_Bit_Count <= 3'b111;
        end
        else if ((r_Leading_Edge & ~w_CPHA) | (r_Trailing_Edge & w_CPHA)) begin
            o_RX_Byte[r_RX_Bit_Count] <= i_SPI_MISO;  // Sample data
            r_RX_Bit_Count            <= r_RX_Bit_Count - 1'b1;
            if (r_RX_Bit_Count == 3'b000) begin
                o_RX_DV   <= 1'b1;   // Byte done, pulse Data Valid
            end
        end
    end
end

// Purpose: Add clock delay to signals for alignment.
always_ff @(posedge i_Clk or negedge i_Rst_L) begin
    if (~i_Rst_L) begin
        o_SPI_Clk  <= w_CPOL;
    end
    else
    begin
        o_SPI_Clk <= r_SPI_Clk;
    end
end

endmodule

