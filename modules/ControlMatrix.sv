`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

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
    output logic addr_src_o,                        // Memory address source select
    output logic rst_src_o,                         // Reset funct3 source select
    output logic rg_wr_o,                           // Register file write (active low)
    output logic [AMuxSelectSize-1:0] a_src_o,      // A_Mux source select
    output logic [BMuxSelectSize-1:0] b_src_o,      // B_Mux source select
    output logic [ImmSelectSize-1:0] imm_src_o,     // Immediate source select
    output logic alu_id_o,                          // ALU output register load
    output logic [ALUOpSize-1:0] alu_op_o,                    // ALU operation
    output logic jal_id_o,                          // JAL/R register load
    output logic [WDSelectSize-1:0] wd_src_o        // Write-Data source select

    // **--**--**--**--**--**--**--**--**--**--**--**--**--
    // DEBUGGING Outputs
    // **--**--**--**--**--**--**--**--**--**--**--**--**--
    `ifdef DEBUG_MODE
    output logic out_ld_o,
    output logic out_sel_o,
    output logic ready_o,              // Active high
    output logic halt_o                // Active high
    `endif
);

/* verilator public_module */

localparam AMuxSelectSize = 2;
localparam BMuxSelectSize = 2;
localparam ImmSelectSize = 3;
localparam PCSelectSize = 2;
localparam WDSelectSize = 2;
localparam ALUOpSize = 3;

// **__--**__--**__--**__--**__--**__--**__--**__--**__--**__--
// IR decoding. This is the largest section.
// Break down the Instruction in a group of logic blocks
// and wires.
// **__--**__--**__--**__--**__--**__--**__--**__--**__--**__--
// `define RD ir_i[11:7]
// `define FUNCT3  ir_i[14:12]
// `define RS1 ir_i[19:15]
// `define RS2 ir_i[24:20]
// `define FUNCT7 ir_i[31:25]

// For RV32I the lower 2 bits are always 11 so we could
// ignore them--but we won't.
logic [6:0] ir_opcode = ir_i[6:0];

// logic [2:0] funct3 = ir_i[14:12];   // R,I,S,B Types
// logic [6:0] funct7 = ir_i[31:25];   // R       Type
// logic [4:0] rd = ir_i[11:7];        // R,I,U,J Types
// logic [4:0] rs1 = ir_i[19:15];      // R,I,S,B Types
// logic [4:0] rs2 = ir_i[24:20];      // R,S,B   Types

// ---------------------------------------------------
// Internal state signals
// ---------------------------------------------------
MatrixState state /*verilator public*/;        // Current state
MatrixState next_state;   // Next state

MatrixState vector_state /*verilator public*/;
MatrixState next_vector_state /*verilator public*/;

// ---------------------------------------------------
// External Functional states (non RISC-V) signals
// ---------------------------------------------------
logic halt;     // Debug only
logic ready /*verilator public*/;    // The "ready" flag is Set when the CPU has completed its reset activities.

// ---------------------------------------------------
// Internal signals
// ---------------------------------------------------
// Once the reset sequence has completed this flag is Set.
logic resetComplete /*verilator public*/;

logic pc_ld;
logic [PCSelectSize-1:0] pc_src;

logic ir_ld;

logic out_ld;
logic out_sel;

logic mem_wr;
logic mem_rd;
logic addr_src;

logic rst_src;

logic reg_we;

logic [AMuxSelectSize-1:0] a_src;
logic [BMuxSelectSize-1:0] b_src;
logic [WDSelectSize-1:0] wd_src;
logic [ImmSelectSize-1:0] imm_src;

logic alu_ld;
logic [ALUOpSize-1:0] alu_op;
logic jal_ld;

// ---------------------------------------------------
// Simulation
// ---------------------------------------------------
initial begin
    // Be default the CPU always attempts to start in Reset mode.
    state = Reset;
    // Also configure the reset sequence start state.
    vector_state = Vector0;
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
    next_vector_state = Vector0;
    
    halt = 1'b0;        // Disable halt regardless of state

    // PC
    pc_ld =  1'b1;      // Disable PC loading
    pc_src = 2'b00;     // Select ALU out direct

    ir_ld = 1'b1;       // Disable IR loading

    // Output 
    out_ld = 1'b1;      // Disable output loading
    out_sel = 1'b0;     // Reg-File

    // Memory
    mem_wr = 1'b1;      // Disable Write (active low)
    mem_rd = 1'b1;      // Disable read (active low)
    addr_src = 1'b0;    // Select PC as source

    // Reg-File
    reg_we = 1'b1;      // Disable writing to Register-File

    a_src = 2'b00;
    b_src = 2'b01;
    imm_src = 3'b000;
    wd_src = 2'b00;

    alu_ld = 1'b1;
    alu_op = 3'b000;    // Default add operation
    jal_ld = 1'b1;

    rst_src = 1'b0;     // Default to IR funct3 source

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
            rst_src = 1'b1;

            // ------------------------------------------------------
            // Vector reset sequence
            // ------------------------------------------------------
            case (vector_state)
                Vector0: begin
                                        // Memory read enabled *default*
                                        // Select PC as source *default*
                    pc_ld = 1'b0;       // Enable loading PC
                    pc_src = 2'b10;     // Select Reset vector constant

                    next_vector_state = Vector1;
                end

                Vector1: begin
                                        // Disable loading PC *default*
                    mem_rd = 1'b0;      // Enable read (active low)
                    
                    next_vector_state = Vector2;
                end

                Vector2: begin
                    // The address of the first instruction is now present
                    // on the Pmmu output

                    pc_ld = 1'b0;       // Enable loading PC
                    pc_src = 2'b11;     // Select Reset addr from mem

                    next_vector_state = Vector3;
                end

                Vector3: begin
                    // PC is loaded with Reset address contained
                    // in the bottom memory location

                                        // Disable loading PC *default*
                    mem_rd = 1'b0;      // Enable read (active low)

                    next_vector_state = Vector4;
                end

                Vector4: begin
                    // The instruction at vector address pointed to by the
                    // Vector address is now present on the Pmmu output
                    ready = 1'b1;
                    resetComplete = 1'b1;

                    // Vector4 is an artifical "Fetch" that is specific
                    // to the Reset state. This causes the IR to load
                    // twice, but that is okay because once the Fetch/Decode
                    // cycle starts there will only be one instead of two.
                    ir_ld = 1'b0;   // Enable IR loading

                    next_state = Fetch;
                end

                default: begin
                    `ifdef SIMULATE
                        $display("%d ###### default Vector state ######", $stime);
                    `endif
                    next_vector_state = Vector0;
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
            // Memory read enabled *default*
            // Disable Loading PC *default*

            if (mem_busy_i) begin
                $display("%d Fetch busy", $stime);
                // remain in fetch until memory is ready with the data
                next_state = Fetch;
            end
            else begin
                // $display("%d Fetch to decode", $stime);
                ir_ld = 1'b0;   // Enable IR loading
                next_state = Decode;
            end
        end

        Decode: begin
            // IR is now loaded with 1st instruction.

            case (ir_opcode)
                `ITYPE_L: begin
                    // Load instructions
                    // Signals that drive sequence
                end

                `RTYPE: begin
                    `ifdef SIMULATE
                        $display("%d OPCODE type: RTYPE", $stime);
                    `endif
                end

                `STYPE: begin
                    `ifdef SIMULATE
                        $display("%d OPCODE type: STYPE", $stime);
                    `endif
                end

                default: begin
                    // `ifdef SIMULATE
                    //     $display("%d OPCODE type: UNKNOWN", $stime);
                    // `endif
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
        vector_state <= Vector0;
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
assign rg_wr_o = reg_we;
assign a_src_o = a_src;
assign b_src_o = b_src;
assign imm_src_o = imm_src;
assign wd_src_o = wd_src;
assign alu_id_o = alu_ld;
assign jal_id_o = jal_ld;
assign rst_src_o = rst_src;

`ifdef DEBUG_MODE
assign out_ld_o = out_ld;
assign out_sel_o = out_sel;
assign ready_o = ready;
assign halt_o = halt;
`endif

endmodule
