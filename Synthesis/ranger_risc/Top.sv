`default_nettype none

// The softcore is hardcoded with the code to run.
// Make sure you have your ".ram" file placed in ????

// The IRQ signal is sourced by a Pico RP2040

module Top (
    input  logic clk,           // 25MHz Clock from board
    input  logic pm6a0,         // rx_in
    output logic pm6a1,         // tx_out
    input  logic pm6b3,         // interrupt request (Active low)
    output logic led,
    output logic [5:0] blade1,
    output logic [11:0] tile1
);

localparam DATA_WIDTH = 32;
localparam PCSelectSize = 3;

// ------------------------------------------------------------------------
// UART
// ------------------------------------------------------------------------
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
logic [7:0] rx_byte;

UARTRx uart_rx (
    .sourceClk(clk),
    .reset(reset),
    .rx_in(pm6a0),
    .rx_byte(rx_byte),
    .rx_complete(rx_complete)
);

// ------------------------------------------------------------------------
// Slow cpu clock domain: CoreClk/(2^(N+1))
// N = 14 = 762Hz
// ------------------------------------------------------------------------
`define N 22
logic [24:0] counter;
logic cpu_clock;

// assign cpu_clock = counter[`N];

assign led = counter[`N];

// ------------------------------------------------------------------------
// LED Blade driven by cpu parallel out port
// ------------------------------------------------------------------------
logic io_wr;
logic [7:0] data_out;
logic [7:0] reg_out;

Register #(.DATA_WIDTH(8)) par_port
(
   .clk_i(cpu_clock),
   .ld_i(io_wr),        // Active Low (LED is on)
   .data_i(data_out),
   .data_o(reg_out)
);

// 1'b0 = LED is on. So for Active high signals we invert signal to turn on.

// Red LEDs
assign blade1[0] = ~ready;
assign blade1[1] = ~halt;
// Yellow LEDs
assign blade1[2] = reset;
assign blade1[3] = ~cpu_clock;
// Green LEDs
assign blade1[4] = io_wr; //reg_out[4];
assign blade1[5] = reset;//reg_out[5];

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
// Softcore processor
// ------------------------------------------------------------------------
logic irq_trigger;  // Active low
logic reset;

RangerRiscProcessor cpu(
    .clk_i(cpu_clock),
    .reset_i(reset),
    .irq_i(pm6b3),
    .data_out(data_out),
    .io_wr(io_wr),
    // ------------- debug outputs ----------------
    .ready_o(ready),
    .halt_o(halt),
    .state_o(mat_state),
    .vector_state_o(vector_state),
    .ir_state_o(ir_state),
    .pc_out_o(pc_out),
    .pc_prior_out_o(pc_prior_out),
    .ir_out_o(ir_out),
    .a_mux_out_o(a_mux_out),
    .b_mux_out_o(b_mux_out),
    .imm_ext_out_o(imm_ext_out),
    .addr_mux_to_pmmu_o(addr_mux_to_pmmu),
    .cm_to_ir_ld_o(cm_to_ir_ld),
    .cm_to_pc_ld_o(cm_to_pc_ld),
    .cm_to_pcp_ld_o(cm_to_pcp_ld),
    .cm_to_mem_rd_o(cm_to_mem_rd),
    .cm_to_alu_ld_o(cm_to_alu_ld),
    .cm_to_mdr_ld_o(cm_to_mdr_ld),
    .cm_to_rg_wr_o(cm_to_rg_wr),
    .cm_to_mem_wr_o(cm_to_mem_wr),
    .cm_to_alu_flags_ld_o(cm_to_alu_flags_ld)
);

`ifdef DEBUG_MODE
logic ready;                // Active high
logic halt;                 // Active high
MatrixState mat_state;      // 5 bits
ResetState vector_state;    // 5 bits
InstructionState ir_state;  // 6 bits
logic [DATA_WIDTH-1:0] pc_out;
logic [DATA_WIDTH-1:0] pc_prior_out;
logic [DATA_WIDTH-1:0] ir_out;
logic [DATA_WIDTH-1:0] a_mux_out;
logic [DATA_WIDTH-1:0] b_mux_out;
logic [DATA_WIDTH-1:0] imm_ext_out;
logic [DATA_WIDTH-1:0] addr_mux_to_pmmu;
logic cm_to_ir_ld;
logic cm_to_pc_ld;
logic cm_to_pcp_ld;
logic cm_to_mem_rd;
logic cm_to_alu_ld;
logic cm_to_mdr_ld;
logic cm_to_rg_wr;
logic cm_to_mem_wr;
logic cm_to_alu_flags_ld;

`endif

// ------------------------------------------------------------------------
// State machine controlling module
// ------------------------------------------------------------------------
ControlState state = CSReset;
ControlState next_state = CSReset;

logic [1:0] cnt_byte;
logic [3:0] cnt_reset_hold;

logic [4:0] cnt_status_req_byte;
// N bytes of status (5:5:6)
logic [7:0] status_bytes [1:0];

always_ff @(posedge clk) begin
    case (state)
        CSReset: begin
            // Hold CPU in reset while Top module starts up.
            reset <= 1'b0;

            cnt_byte <= 0;
            cnt_reset_hold <= 0;
            tx_en <= 1;         // Disable transmission
            cpu_clock <= 0;
            
            next_state <= CSReset1;
        end

        CSReset1: begin
            reset <= 1'b0;
            cpu_clock <= ~cpu_clock;
            
            next_state <= CSResetComplete;
        end

        CSResetComplete: begin
            reset <= 1'b1;
            // cpu_clock <= ~cpu_clock;
            
            next_state <= CSIdle;
        end

        // -------------------------------
        // CPU reset sequence
        // -------------------------------
        // Asserts "reset" for 2^4 clock cycles
        CSCPUResetAssert: begin
            reset <= 1'b0;
            cnt_reset_hold <= 0;
            tx_en <= 1;         // Disable transmission
            cpu_clock <= ~cpu_clock;
            next_state <= CSCPUResetDeassert;
        end

        CSCPUResetDeassert: begin
            if (cnt_reset_hold == 4'b1111) begin
                reset <= 1'b1;
                next_state <= CSSend;
            end
            else begin
                cnt_reset_hold <= cnt_reset_hold + 1;
            end
            cpu_clock <= ~cpu_clock;
        end

        // For manually controlling Reset with clocks
        CSResetAssertToggle: begin
            reset <= ~reset;
            next_state <= CSSend;
        end

        // -------------------------------
        // CPU rising/falling sequence
        // -------------------------------
        CSCPUClockRise: begin
            cpu_clock <= 1;
            next_state <= CSSend;
        end

        CSCPUClockFall: begin
            cpu_clock <= 0;
            next_state <= CSSend;
        end

        CSCPUClockToggle: begin
            cpu_clock <= 1;
            next_state <= CSCPUClockFall;
        end

        // -------------------------------
        // Status sequence
        // -------------------------------
        CSStatusRequest: begin
            cnt_status_req_byte <= 0;
            next_state <= CSStatusSend;
        end

        CSStatusSend: begin
            tx_en <= 0; // Enable transmission
            next_state <= CSStatusSending;

            case (cnt_status_req_byte)
                5'b00000: begin
                    // Concat portions into 1 byte
                    // status(5) + 3 bits of vector_state(5)
                    // 4321 0 432
                    // 0000_0|000
                    tx_byte <= {mat_state, vector_state[4:2]};
                end
                5'b00001: begin
                    // Concat portions into 1 byte
                    // vector_state(5) + ir_state
                    // 10 54 3210
                    // 00|00_0000
                    tx_byte <= {vector_state[1:0], ir_state[5:0]};
                end
                5'b00010: begin
                    tx_byte <= {cpu_clock, ready, halt, cm_to_ir_ld, cm_to_pc_ld, cm_to_pcp_ld, cm_to_mem_rd, cm_to_alu_ld};
                end
                // ----- PC reg --------------------
                // 3      2 2      1 1      
                // 0      4 3      6 5      8 7      0
                // 00000000_00000000_00000000_00000000
                5'b00011: begin
                    tx_byte <= pc_out[0:7];
                end
                5'b00100: begin
                    tx_byte <= pc_out[8:15];
                end
                5'b00101: begin
                    tx_byte <= pc_out[16:23];
                end
                5'b00110: begin
                    tx_byte <= pc_out[24:30];
                end
                // ----- IR reg --------------------
                5'b00111: begin
                    tx_byte <= ir_out[0:7];
                end
                5'b01000: begin
                    tx_byte <= ir_out[8:15];
                end
                5'b01001: begin
                    tx_byte <= ir_out[16:23];
                end
                5'b01010: begin
                    tx_byte <= ir_out[24:30];
                end
                // ----- PC Prior reg --------------------
                5'b01011: begin
                    tx_byte <= pc_prior_out[0:7];
                end
                5'b01100: begin
                    tx_byte <= pc_prior_out[8:15];
                end
                5'b01101: begin
                    tx_byte <= pc_prior_out[16:23];
                end
                5'b01110: begin
                    tx_byte <= pc_prior_out[24:30];
                end
                // ----- a_mux_out reg --------------------
                5'b01111: begin
                    tx_byte <= a_mux_out[0:7];
                end
                5'b10000: begin
                    tx_byte <= a_mux_out[8:15];
                end
                5'b10001: begin
                    tx_byte <= a_mux_out[16:23];
                end
                5'b10010: begin
                    tx_byte <= a_mux_out[24:30];
                end
                // ----- b_mux_out reg --------------------
                5'b10011: begin
                    tx_byte <= b_mux_out[0:7];
                end
                5'b10100: begin
                    tx_byte <= b_mux_out[8:15];
                end
                5'b10101: begin
                    tx_byte <= b_mux_out[16:23];
                end
                5'b10110: begin
                    tx_byte <= b_mux_out[24:30];
                end
                // ----- imm_ext_out reg --------------------
                5'b10111: begin
                    tx_byte <= imm_ext_out[0:7];
                end
                5'b11000: begin
                    tx_byte <= imm_ext_out[8:15];
                end
                5'b11001: begin
                    tx_byte <= imm_ext_out[16:23];
                end
                5'b11010: begin
                    tx_byte <= imm_ext_out[24:30];
                end
                // ----- addr_mux_to_pmmu reg --------------------
                5'b11011: begin
                    tx_byte <= addr_mux_to_pmmu[0:7];
                end
                5'b11100: begin
                    tx_byte <= addr_mux_to_pmmu[8:15];
                end
                5'b11101: begin
                    tx_byte <= addr_mux_to_pmmu[16:23];
                end
                5'b11110: begin
                    tx_byte <= addr_mux_to_pmmu[24:30];
                end
                5'b11111: begin
                    tx_byte <= {cm_to_mdr_ld, cm_to_rg_wr, cm_to_mem_wr, cm_to_alu_flags_ld, {4{1'b0}}};
                end
            endcase
        end

        CSStatusSending: begin
            tx_en <= 1; // Disable transmission
            
            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                if (cnt_status_req_byte == 5'b11111) begin
                    next_state <= CSIdle;
                    cnt_status_req_byte <= 0;
                end
                else begin
                    next_state <= CSStatusSend;
                    cnt_status_req_byte <= cnt_status_req_byte + 1;
                end
            end
        end

        // -------------------------------
        // UART Rx/Tx sequence
        // -------------------------------
        CSIdle: begin
            if (rx_complete) begin
                display_byte <= rx_byte;
                
                case (rx_byte)
                    8'h72:  // "r"
                        next_state <= CSCPUResetAssert;

                    8'h7A:  begin // "z"
                        next_state <= CSCPUClockRise;
                    end

                    8'h78:  begin // "x"
                        next_state <= CSCPUClockFall;
                    end

                    8'h63:  begin // "c"
                        next_state <= CSCPUClockToggle;
                    end

                    8'h65:  begin // "e"
                        next_state <= CSResetAssertToggle;
                    end

                    8'h73:  begin // "s"
                        next_state <= CSStatusRequest;
                    end

                    default: begin
                        next_state <= CSSend;
                    end
                endcase

            end
        end

        CSSend: begin
            tx_en <= 0; // Enable transmission
            next_state <= CSSending;

            case (cnt_byte)
                2'b00:
                    case (display_byte)
                        8'h72, 8'h65:  begin // "r", "e"
                            tx_byte <= 8'h52;  // "R"
                        end
                        8'h7A, 8'h78, 8'h63:  begin // "z", "x", "c"
                            tx_byte <= 8'h43;  // "C"
                        end

                        default: begin
                            tx_byte <= 8'h4F;  // "O"
                        end
                    endcase
                2'b01:
                    case (display_byte)
                        8'h72:  begin // "r"
                            tx_byte <= 8'h73;  // "s"
                        end
                        8'h7A:  begin // "z"
                            tx_byte <= 8'h72;  // "r"
                        end
                        8'h78:  begin // "x"
                            tx_byte <= 8'h66;  // "f"
                        end
                        8'h63:  begin // "c"
                            tx_byte <= 8'h74;  // "t"
                        end
                        8'h65:  begin // "e"
                            tx_byte <= 8'h61;  // "a"
                        end

                        default: begin
                            tx_byte <= 8'h6B;  // "k"
                        end
                    endcase
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

always_ff @(posedge clk) begin
    counter <= counter + 1;
end

endmodule

