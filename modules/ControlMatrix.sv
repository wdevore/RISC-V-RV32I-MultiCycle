`default_nettype none

module ControlMatrix
#(
    parameter DATA_WIDTH = 32
)
(
    input logic clk_i,
    input logic [DATA_WIDTH-1:0] ir_i,  // Instruction register
    input logic reset_i,                // CPU reset (active low)
    input logic mem_busy_i,             // Memory ready (active high)
    
    // **--**--**--**--**--**--**--**--**--**--**--**--**--
    // Outputs
    // **--**--**--**--**--**--**--**--**--**--**--**--**--
    output logic ir_ld_o,                           // IR load (active low)
    output logic pc_ld_o,                           // PC load (active low)
    output logic [PCSelectSize-1:0] pc_src_o,       // PC source select
    output logic mem_wr_o,                          // Memory write (active low)
    output logic mem_rd_o,                          // Memory read (active low)
    output logic [AddrSelectSize-1:0] addr_src_o,   // Memory address source select
    output logic rg_wr_o,                           // Register file write (active low)
    output logic [AMuxSelectSize-1:0] a_src_o,      // A_Mux source select
    output logic [BMuxSelectSize-1:0] b_src_o,      // B_Mux source select
    output logic [ImmSelectSize-1:0] imm_src_o,     // Immediate source select
    output logic alu_id_o,                          // ALU output register load
    output logic jal_id_o,                          // JAL/R register load
    output logic [WDSelectSize-1:0] wd_src_o,       // Write-Data source select

    // **--**--**--**--**--**--**--**--**--**--**--**--**--
    // DEBUGGING Outputs
    // **--**--**--**--**--**--**--**--**--**--**--**--**--
    `ifndef RELEASE_MODE
    output logic out_ld_o,
    output logic out_sel_o,
    output logic ready_o,              // Active high
    output logic halt_o                // Active high
    `endif
);

localparam AMuxSelectSize = 2;
localparam BMuxSelectSize = 2;
localparam ImmSelectSize = 3;
localparam PCSelectSize = 2;
localparam WDSelectSize = 2;
localparam AddrSelectSize = 1;

// ---------------------------------------------------
// IR decode
// ---------------------------------------------------
// `define OPCODE ir_i[15:12]    // op-code field
`define OPCODE ir_i[31:0]    // op-code field

`define REG_SRC1 ir_i[2:0]
`define REG_SRC2 ir_i[5:3]
`define REG_DEST ir_i[8:6]

`define ALUOp  ir_i[15:12]

// ---------------------------------------------------
// Internal state signals
// ---------------------------------------------------
MatrixState state /*verilator public*/;        // Current state
MatrixState next_state /*verilator public*/;   // Next state

MatrixState vector_state;
MatrixState next_vector_state;

// ---------------------------------------------------
// External Functional states (non RISC-V) signals
// ---------------------------------------------------
logic halt;
logic ready; // The "ready" flag is Set when the CPU has completed its reset activities.

// ---------------------------------------------------
// Internal signals
// ---------------------------------------------------
// Once the reset sequence has completed this flag is Set.
logic resetComplete;

logic pc_ld;
logic [PCSelectSize-1:0] pc_src;       // MUX_PC selector

logic ir_ld;

logic out_ld;
logic out_sel;

logic mem_wr;
logic mem_rd;
logic [AddrSelectSize-1:0] addr_src;     // MUX_ADDR selector

logic reg_we;

logic [AMuxSelectSize-1:0] a_src;
logic [BMuxSelectSize-1:0] b_src;
logic [ImmSelectSize-1:0] imm_src;
logic [WDSelectSize-1:0] wd_src;

logic alu_ld;
logic jal_ld;

// ---------------------------------------------------
// Simulation
// ---------------------------------------------------
initial begin
    // Be default the CPU always attempts to start in Reset mode.
    state = Reset;
    // Also configure the reset sequence start state.
    vector_state = Vector1;
end

// -------------------------------------------------------------
// Combinational control signals
// -------------------------------------------------------------
always_comb begin
    // ======================================
    // Initial/Default conditions on a *state* or *vector_state* change
    // ======================================
    ready = 1'b1;           // Default: CPU is ready
    resetComplete = 1'b1;   // Default: Reset is complete

    next_state = Reset;
    next_vector_state = Vector1;
    
    halt = 1'b0;        // Disable halt regardless of state

    // PC
    pc_ld =  1'b1;      // Disable PC loading
    pc_src = 2'b00;     // Select ALU out direct

    // Misc: Stack, Output
    ir_ld = 1'b1;       // Disable IR loading

    // Output 
    out_ld = 1'b1;      // Disable output loading
    out_sel = 1'b0;     // Reg-File

    // Memory
    mem_wr = 1'b1;      // Disable Write (active low)
    mem_rd = 1'b0;      // Enable read (active low)
    addr_src = 1'b0;    // Select PC as source

    // Reg-File
    reg_we = 1'b1;      // Disable writing to Register-File

    a_src = 2'b00;
    b_src = 2'b00;
    imm_src = 3'b000;
    wd_src = 2'b00;
    alu_ld = 1'b1;
    jal_ld = 1'b1;

    // ======================================
    // Main state machine
    // ======================================
    case (state)
        // CPU is in a reset state waiting for the Reset flag to deactivate (High)
        // While in this state the CPU continuosly loads the Reset-Vector.
        Reset: begin
            // `ifdef SIMULATE
            //     $display("%d Reset", $stime);
            // `endif

            ready = 1'b0;               // CPU is not ready while resetting.
            resetComplete = 1'b0;       // Reset not complete

            
            // ------------------------------------------------------
            // Vector reset sequence
            // ------------------------------------------------------
            case (vector_state)
                Vector1: begin
                    `ifdef SIMULATE
                        $display("%d ###### Vector1 state ######", $stime);
                    `endif
                                        // Memory read enabled *default*
                                        // Select PC as source *default*
                    pc_ld = 1'b0;       // Enable loading PC
                    pc_src = 2'b10;     // Select Reset vector constant

                    next_vector_state = Vector2;
                end

                Vector2: begin
                    `ifdef SIMULATE
                        $display("%d ###### Vector2 state ######", $stime);
                    `endif

                    // PC is now loaded with Reset-Vector address

                    ready = 1'b1;
                    resetComplete = 1'b1;
                    
                    next_state = Fetch;
                end

                default: begin
                    `ifdef SIMULATE
                        $display("%d ###### default Vector state ######", $stime);
                    `endif
                    next_vector_state = Vector1;
                end
            endcase
        end

        BugHalt: begin
            `ifdef SIMULATE
                $display("%d BugHalt", $stime);
            `endif

            halt = 1'b1;
            ready = 1'b0;

            // We can only exit this state on a reset.
            next_state = BugHalt;
        end

        Fetch: begin
            // `ifdef SIMULATE
            //     $display("%d Fetch", $stime);
            // `endif

            // Memory read enabled *default*
            // Disable Loading PC *default*

            if (mem_busy_i) begin
                $display("%d Fetch busy", $stime);
                // remain in fetch until memory is ready with the data
                next_state = Fetch;
            end
            else begin
                $display("%d Fetch to decode", $stime);
                ir_ld = 1'b0;   // Enable IR loading
                next_state = Decode;
            end
        end

        Decode: begin
            `ifdef SIMULATE
                $display("%d Decode : {%b}", $stime, `OPCODE);
            `endif

            // IR is now loaded with 1st instruction.

            case (`OPCODE)
                0: begin // No operation (a.k.a. do nothing)
                    // Simply loop back to fetching the next instruction
                    `ifdef SIMULATE
                        $display("%d OPCODE: NOP", $stime);
                    `endif
                end
            endcase

                next_state = Fetch;

        end

        default:
            next_state = Reset;

    endcase // End (state)
end

// -------------------------------------------------------------
// Sequence control (sync). Move to the next state on the
// rising edge of the next clock.
// -------------------------------------------------------------
always_ff @(posedge clk_i) begin
    if (!reset_i) begin
        state <= Reset;
        vector_state <= Vector1;
    end
    else
        if (resetComplete)
            state <= next_state;
        else begin
            state <= Reset;
            vector_state <= next_vector_state;
        end
end

// -------------------------------------------------------------
// Route internal signals to outputs
// -------------------------------------------------------------
assign pc_ld_o = pc_ld;
assign pc_src_o = pc_src;
assign ir_ld_o = ir_ld;
assign mem_wr_o = mem_wr;
assign mem_rd_o = mem_rd;
assign addr_src_o = addr_src;
assign halt_o = halt;
assign rg_wr_o = reg_we;
assign out_ld_o = out_ld;
assign out_sel_o = out_sel;
assign ready_o = ready;
assign a_src_o = a_src;
assign b_src_o = b_src;
assign imm_src_o = imm_src;
assign wd_src_o = wd_src;
assign alu_id_o = alu_ld;
assign jal_id_o = jal_ld;

endmodule
