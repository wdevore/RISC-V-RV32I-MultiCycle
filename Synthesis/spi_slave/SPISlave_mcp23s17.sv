`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// SPI Slave needs to sync on 3 signals from Master:
// 1) SClk
// 2) MOSI
// 3) /SS (aka /CS)

// Transmit on rising edge of SClk and received on falling edge.

module SPISlave
(
    input  logic sysClk,         // system domain clock (PLL)
    input  logic spiClk,         // SPI Clock input from Master
    input  logic cs,             // /CS
    input  logic mosi,           // output (1 bit at a time)
    output logic miso,

    // output logic [2:0] state
);

// The initializer is required as per this bug:
// https://github.com/YosysHQ/yosys/issues/188
// Without it you need to hack it by routing "state" to
// a port OR use a reset sequence on boot up.
logic [2:0] state = 0;

logic [7:0] rx_byte;

// ----------------------------------------------------
// CDC Sync-ed signal for SClk (from master)
// ----------------------------------------------------
logic SClk_risingedge;
logic SClk_fallingedge;
logic SClk_sync;            // Not used

CDCSynchron SPI_SClk_Sync (
    .sysClk_i(sysClk),
    .async_i(spiClk),
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
    .sysClk_i(sysClk),
    .async_i(mosi),
    .sync_o(MOSI_sync),
    .rising_o(MOSI_risingedge),
    .falling_o(MOSI_fallingedge)
);

// ----------------------------------------------------
// CDC Sync-ed signal for /CS (from master)
// ----------------------------------------------------
logic SS_risingedge;
logic SS_fallingedge;
logic SS_sync;

CDCSynchron SPI_SS_Sync (
    .sysClk_i(sysClk),
    .async_i(cs),
    .sync_o(SS_sync),
    .rising_o(SS_risingedge),
    .falling_o(SS_fallingedge)
);

// A 3 bit counter to count the bits as they come in/out.
logic [2:0] bitCnt;
logic shift;
logic load_data;

ParallelLoadShiftReg shift_data (
    .clk(sysClk),
    .load(load_data),  // Active low
    .reset(1'b1),
    .shift(shift),      // Active low
    .data_in(data_out_val),
    .data_out(miso)
);

logic [1:0] bufCnt;

// Detect the final falling edge of the SPI clock.
logic final_fall;
assign final_fall = state == SLIdle && SClk_fallingedge;

always_ff @(posedge sysClk) begin
    shift <= 1'b1;  // Disable shift
    load_data <= 1'b1; // Disable load
    data_select <= 3;

    if (SS_fallingedge) begin
        bufCnt <= 0;
        rx_buf[0] <= 8'hFF;
        rx_buf[1] <= 8'hFF;
        state <= SLIdle;
    end

    // The code just tests that a byte can be sent regardless.
    // To use it set <"state" = SLCSLoad> above.
    // if (state == SLCSLoad) begin
    //     data_select <= 0;
    //     state <= SLCSLoad2;
    //     load_data <= 1'b0;  // Enable load
    // end

    // if (state == SLCSLoad2) begin
    //     data_select <= 3;
    //     state <= SLIdle;
    // end

    // -------------------------
    // Main shifting output
    // -------------------------
    if (SClk_fallingedge) begin
        if (state == SLTransmit) begin
            shift <= 1'b0;  // Enable shift
            state <= SLShift;
        end
    end

    // A state to shift the next bit into MSB position.
    if (state == SLShift) begin
        state <= SLTransmit;
    end

    if (SClk_risingedge) begin
        case (state)
            // On the first rising edge of SPI clock transition
            // to Transmit cycle.
            SLIdle: begin
                state <= SLTransmit;
            end

            // On any succeeding rising edge check for bit count.
            SLTransmit: begin
                // Once count == 0 we transition back to idle and repeat.
                if (bitCnt == 3'b000)
                    state <= SLIdle;
                else
                    bitCnt <= bitCnt - 3'b001;
            end

            default: begin
            end
        endcase

        rx_byte <= {rx_byte[6:0], MOSI_sync}; // Input from Master
    end

    // ----------------------------------------
    // Detect pattern and setup response
    if (pattern1 && state == SLIdle) begin
        state <= SLLoad;
        data_select <= 0;  // Select io_con_response
        load_data <= 1'b0; // Enable load
    end

    if (pattern2 && state == SLIdle) begin
        state <= SLLoad;
        data_select <= 1;  // select io_dir_response
        load_data <= 1'b0; // Enable load
    end

    // Optional 3rd pattern
    // if (pattern3 && state == SLIdle) begin
    //     state <= SLLoad;
    //     data_select <= 2;
    // end

    // Setup response
    if (state == SLLoad) begin
        // The data_select value doesn actually matter because
        // The parallel register has just been loaded.
        // So use the default which is 3.
        state <= SLIdle;
        // TODO Clear buffers. Need a better scheme
        rx_buf[0] <= 8'hFF;
        rx_buf[1] <= 8'hFF;
    end
    // ----------------------------------------

    // At the end of each received byte transfer it to the buffer.
    if (final_fall) begin
        // Capture byte into buffer
        rx_buf[bufCnt] <= rx_byte;

        bufCnt <= bufCnt + 2'b01;
        if (bufCnt == 2'b10)
            bufCnt <= 2'b00;

        // (optional) Clear byte buffer just for clarity.
        rx_byte <= 0;
    end

    if (start_end) begin
        // Reset counter to N-1 because first bit is already
        // at the output for transmission.
        bitCnt <= 3'b110;
    end

end

logic [7:0] data_out_val; // Wire that routes to Parallel Register
logic [1:0] data_select;

Mux4 #(.DATA_WIDTH(8)) data_out_mux
(
    .select_i(data_select),
    .data0_i(io_con_response),
    .data1_i(io_dir_response),
    .data2_i(io_ipo_response),
    .data3_i(8'b0),
    .data_o(data_out_val)
);

// Detect the start and end of a transmission cycle.
logic start_end;
assign start_end = SS_fallingedge | final_fall;

logic [7:0] rx_buf [2:0];

// Just some meaningless data that we can check
localparam [7:0] io_con_response = 8'h28;
localparam [7:0] io_dir_response = 8'hF9;
localparam [7:0] io_ipo_response = 8'hE4;

logic pattern1;
logic pattern2;
// logic pattern3;
assign pattern1 = (rx_buf[0] == 8'h41 && rx_buf[1] == 8'h0A);
assign pattern2 = (rx_buf[0] == 8'h41 && rx_buf[1] == 8'h0F);
// assign pattern3 = (rx_buf[0] == 8'h41 && rx_buf[1] == 8'h00);


endmodule

