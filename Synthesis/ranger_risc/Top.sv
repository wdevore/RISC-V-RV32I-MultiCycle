`default_nettype none

// The softcore is hardcoded with the code to run.
// Make sure you have your ".ram" file placed in ????

// The IRQ signal is sourced by a Pico RP2040

module Top (
    input  logic clk,           // 25MHz Clock from board
    input  logic pm6b3,         // interrupt request (Active low)
    output logic led,
    output logic [5:0] blade1
);

// ------------------------------------------------------------------------
// Slow cpu clock domain: CoreClk/(2^(N+1))
// N = 14 = 762Hz
// ------------------------------------------------------------------------
`define N 14
logic [24:0] cpu_counter;
logic cpu_clock;

assign cpu_clock = cpu_counter[`N];

assign led = cpu_counter[22];

// ------------------------------------------------------------------------
// LED Blade driven by cpu parallel out port
// ------------------------------------------------------------------------
logic data_wr;
logic [7:0] data_out;
logic [7:0] reg_out;

Register #(.DATA_WIDTH(8)) par_port
(
   .clk_i(cpu_clock),
   .ld_i(data_wr),
   .data_i(data_out),
   .data_o(reg_out)
);

assign blade1[0] = reg_out[0];
assign blade1[1] = reg_out[1];
assign blade1[2] = reg_out[2];
assign blade1[3] = reg_out[3];
assign blade1[4] = reg_out[4];
assign blade1[5] = reg_out[5];

// ------------------------------------------------------------------------
// Softcore processors
// ------------------------------------------------------------------------
logic irq_trigger;  // Active low
logic reset;

RangerRiscProcessor cpu(
    .clk_i(cpu_clock),
    .reset_i(reset),
    .irq_i(pm6b3),
    .data_out(data_out),
    .data_wr(data_wr)
);

// ------------------------------------------------------------------------
// State machine controlling module
// ------------------------------------------------------------------------
logic state = CSReset;
logic next_state = CSReset;

always_ff @(posedge clk) begin
    cpu_counter <= cpu_counter + 1;

    case (state)
        CSReset: begin
            reset <= 1'b1;
            next_state <= CSReset1;
        end

        CSReset1: begin
            reset <= 1'b0;      // Trigger reset
            next_state <= CSResetComplete;
        end

        CSResetComplete: begin
            reset <= 1'b1;
        end

        default: begin
        end
    endcase

    state <= next_state;
end

endmodule

