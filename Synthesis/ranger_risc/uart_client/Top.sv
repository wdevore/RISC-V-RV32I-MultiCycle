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
localparam FlagSize = 4;

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
// N = 18 = 48Hz
// ------------------------------------------------------------------------
`define N 18
logic [24:0] counter;

// Manaully controlled clock via UART commands
logic man_clock;

logic cpu_clock;
assign cpu_clock = clock_select == 1'b1 ? run_clock : man_clock;

// Init to the Manual clock
logic clock_select;

logic run_clock;
assign run_clock = counter[`N];

assign led = cpu_clock;

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
assign blade1[0] = ~reg_out[0];
assign blade1[1] = ~reg_out[1];
// Yellow LEDs
assign blade1[2] = ~reg_out[2];
assign blade1[3] = ~reg_out[3];
// Green LEDs
assign blade1[4] = ~reg_out[4];
assign blade1[5] = ~reg_out[5];

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
    .cm_to_alu_flags_ld_o(cm_to_alu_flags_ld),
    .wd_src_out_o(wd_src_out),
    .cm_to_pc_src_o(cm_to_pc_src),
    .cm_to_wd_src_o(cm_to_wd_src),
    .alu_flags_cm_o(alu_flags_cm),
    .cm_to_addr_src_o(cm_to_addr_src),
    .cm_to_rsa_ld_o(cm_to_rsa_ld),
    .take_branch_o(take_branch),
    .mdr_out_o(mdr_out),
    .alu_out_o(alu_out)
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
logic [DATA_WIDTH-1:0] wd_src_out;
PCSrc cm_to_pc_src;
WDMuxSrc cm_to_wd_src;
logic [FlagSize-1:0] alu_flags_cm;
logic cm_to_addr_src;
logic cm_to_rsa_ld;
logic take_branch;
logic [DATA_WIDTH-1:0] mdr_out;
logic [DATA_WIDTH-1:0] alu_out;

`endif

// ------------------------------------------------------------------------
// State machine controlling module
// ------------------------------------------------------------------------
ControlState state = CSReset;
ControlState next_state = CSReset;

logic [1:0] cnt_byte;
logic [3:0] cnt_reset_hold;

logic [5:0] cnt_status_req_byte;
// N bytes of status (5:5:6)
logic [7:0] status_bytes [1:0];

always_ff @(posedge clk) begin
    counter <= counter + 1;

    case (state)
        CSReset: begin
            // Hold CPU in reset while Top module starts up.
            reset <= 1'b0;

            cnt_byte <= 0;
            cnt_reset_hold <= 0;
            tx_en <= 1;         // Disable transmission
            man_clock <= 0;
            clock_select <= 0;
            next_state <= CSReset1;
        end

        CSReset1: begin
            reset <= 1'b0;
            man_clock <= ~man_clock;
            
            next_state <= CSResetComplete;
        end

        CSResetComplete: begin
            reset <= 1'b1;
            
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
            man_clock <= ~man_clock;
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
            man_clock <= ~man_clock;
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
            man_clock <= 1;
            next_state <= CSSend;
        end

        CSCPUClockFall: begin
            man_clock <= 0;
            next_state <= CSSend;
        end

        CSCPUClockToggle: begin
            man_clock <= 1;
            next_state <= CSCPUClockFall;
        end

        CSClockControlMan: begin
            clock_select <= 0;
            next_state <= CSSend;
        end

        CSClockControlRun: begin
            clock_select <= 1;
            next_state <= CSSend;
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
                6'b000000: begin    // byte 0
                    // Concat portions into 1 byte
                    // status(5) + 3 bits of vector_state(5)
                    // 4321 0 432
                    // 0000_0|000
                    tx_byte <= {mat_state, vector_state[4:2]};
                end
                6'b000001: begin    // byte 1
                    // Concat portions into 1 byte
                    // vector_state(5) + ir_state
                    // 10 54 3210
                    // 00|00_0000
                    tx_byte <= {vector_state[1:0], ir_state[5:0]};
                end
                6'b000010: begin    // byte 2
                    tx_byte <= {cpu_clock, ready, halt, cm_to_ir_ld, cm_to_pc_ld, cm_to_pcp_ld, cm_to_mem_rd, cm_to_alu_ld};
                end
                // ----- PC reg --------------------
                // 3      2 2      1 1      
                // 1      4 3      6 5      8 7      0
                // 00000000_00000000_00000000_00000000
                6'b000011: begin    // byte 3
                    tx_byte <= pc_out[0:7];
                end
                6'b000100: begin    // byte 4
                    tx_byte <= pc_out[8:15];
                end
                6'b000101: begin    // byte 5
                    tx_byte <= pc_out[16:23];
                end
                6'b000110: begin    // byte 6
                    tx_byte <= pc_out[24:31];
                end
                // ----- IR reg --------------------
                6'b000111: begin    // byte 7
                    tx_byte <= ir_out[0:7];
                end
                6'b001000: begin    // byte 8
                    tx_byte <= ir_out[8:15];
                end
                6'b001001: begin    // byte 9
                    tx_byte <= ir_out[16:23];
                end
                6'b001010: begin    // byte 10
                    tx_byte <= ir_out[24:31];
                end
                // ----- PC Prior reg --------------------
                6'b001011: begin    // byte 11
                    tx_byte <= pc_prior_out[0:7];
                end
                6'b001100: begin    // byte 12
                    tx_byte <= pc_prior_out[8:15];
                end
                6'b001101: begin    // byte 13
                    tx_byte <= pc_prior_out[16:23];
                end
                6'b001110: begin    // byte 14
                    tx_byte <= pc_prior_out[24:31];
                end
                // ----- a_mux_out reg --------------------
                6'b001111: begin    // byte 15
                    tx_byte <= a_mux_out[0:7];
                end
                6'b010000: begin    // byte 16
                    tx_byte <= a_mux_out[8:15];
                end
                6'b010001: begin    // byte 17
                    tx_byte <= a_mux_out[16:23];
                end
                6'b010010: begin    // byte 18
                    tx_byte <= a_mux_out[24:31];
                end
                // ----- b_mux_out reg --------------------
                6'b010011: begin    // byte 19
                    tx_byte <= b_mux_out[0:7];
                end
                6'b010100: begin    // byte 20
                    tx_byte <= b_mux_out[8:15];
                end
                6'b010101: begin    // byte 21
                    tx_byte <= b_mux_out[16:23];
                end
                6'b010110: begin    // byte 22
                    tx_byte <= b_mux_out[24:31];
                end
                // ----- imm_ext_out reg --------------------
                6'b010111: begin    // byte 23
                    tx_byte <= imm_ext_out[0:7];
                end
                6'b011000: begin    // byte 24
                    tx_byte <= imm_ext_out[8:15];
                end
                6'b011001: begin    // byte 25
                    tx_byte <= imm_ext_out[16:23];
                end
                6'b011010: begin    // byte 26
                    tx_byte <= imm_ext_out[24:31];
                end
                // ----- addr_mux_to_pmmu reg --------------------
                6'b011011: begin    // byte 27
                    tx_byte <= addr_mux_to_pmmu[0:7];
                end
                6'b011100: begin    // byte 28
                    tx_byte <= addr_mux_to_pmmu[8:15];
                end
                6'b011101: begin    // byte 29
                    tx_byte <= addr_mux_to_pmmu[16:23];
                end
                6'b011110: begin    // byte 30
                    tx_byte <= addr_mux_to_pmmu[24:31];
                end
                // ----- bits 2 --------------------
                6'b011111: begin    // byte 31
                    tx_byte <= {cm_to_mdr_ld, cm_to_rg_wr, cm_to_mem_wr, cm_to_alu_flags_ld, cm_to_addr_src, cm_to_rsa_ld, io_wr, take_branch};
                end
                // ----- wd_src_out reg --------------------
                6'b100000: begin    // byte 32
                    tx_byte <= wd_src_out[0:7];
                end
                6'b100001: begin    // byte 33
                    tx_byte <= wd_src_out[8:15];
                end
                6'b100010: begin    // byte 34
                    tx_byte <= wd_src_out[16:23];
                end
                6'b100011: begin    // byte 35
                    tx_byte <= wd_src_out[24:31];
                end
                // ----- pc_src --------------------
                6'b100100: begin    // byte 36
                    tx_byte <= cm_to_pc_src;
                end
                // ----- wd_src mux --------------------
                6'b100101: begin    // byte 37
                    tx_byte <= cm_to_wd_src;
                end
                // ----- alu flags --------------------
                6'b100110: begin    // byte 38
                    tx_byte <= alu_flags_cm;
                end
                // ----- data_out --------------------
                6'b100111: begin    // byte 39
                    tx_byte <= data_out;
                end
                // ----- bits 3 --------------------
                6'b101000: begin    // byte 40
                    tx_byte <= {clock_select, {7{1'b0}}};
                end
                // ----- mdr_out reg --------------------
                6'b101001: begin    // byte 41
                    tx_byte <= mdr_out[0:7];
                end
                6'b101010: begin    // byte 42
                    tx_byte <= mdr_out[8:15];
                end
                6'b101011: begin    // byte 43
                    tx_byte <= mdr_out[16:23];
                end
                6'b101100: begin    // byte 44
                    tx_byte <= mdr_out[24:31];
                end
                // ----- alu_out reg --------------------
                6'b101101: begin    // byte 45
                    tx_byte <= alu_out[0:7];
                end
                6'b101110: begin    // byte 46
                    tx_byte <= alu_out[8:15];
                end
                6'b101111: begin    // byte 47
                    tx_byte <= alu_out[16:23];
                end
                6'b110000: begin    // byte 48
                    tx_byte <= alu_out[24:31];
                end
                
            endcase
        end

        CSStatusSending: begin
            tx_en <= 1; // Disable transmission
            
            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                if (cnt_status_req_byte == 6'b110000) begin
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

                    8'h6A:  begin // "j"
                        next_state <= CSClockControlMan;
                    end

                    8'h6B:  begin // "k"
                        next_state <= CSClockControlRun;
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

                        8'h6A, 8'h6B:  begin // "k"
                            tx_byte <= 8'h4B;  // "K"
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
                        8'h6A, 8'h6B:  begin
                            tx_byte <= 8'h6B;  // "k"
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

endmodule

