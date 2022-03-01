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
    input logic [DATA_WIDTH-1:0] ir_i,    // Instruction register
    input logic reset_i,                  // CPU reset (active low)
    input logic mem_busy_i,               // Memory ready (active high)
    input logic [`FlagSize-1:0] flags_i,  // Flags: V,N,C,Z
    
    // **--**--**--**--**--**--**--**--**--**--**--**--**--
    // Outputs
    // **--**--**--**--**--**--**--**--**--**--**--**--**--
    output logic ir_ld_o,                           // IR load (active low)
    output logic pc_ld_o,                           // PC load (active low)
    output logic pcp_ld_o,                          // PC Prior load (active low)
    output logic flags_ld_o,                        // ALU flags load (active low)
    output logic [`PCSelectSize-1:0] pc_src_o,      // PC source select
    output logic mem_wr_o,                          // Memory write (active low)
    output logic mem_rd_o,                          // Memory read (active low)
    output logic addr_src_o,                        // Memory address source select
    output logic rst_src_o,                         // Reset funct3 source select
    output logic rg_wr_o,                           // Register file write (active low)
    output logic [`AMuxSelectSize-1:0] a_src_o,     // A_Mux source select
    output logic [`BMuxSelectSize-1:0] b_src_o,     // B_Mux source select
    output logic [`ImmSelectSize-1:0] imm_src_o,    // Immediate source select
    output logic alu_ld_o,                          // ALU output register load
    output logic [`ALUOpSize-1:0] alu_op_o,         // ALU operation
    output logic jal_id_o,                          // JAL/R register load
    output logic [`WDSelectSize-1:0] wd_src_o,       // Write-Data source select
    output logic mdr_ld_o

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

// For RV32I the lower 2 bits are always 11 so we could
// ignore them--but we won't.
logic [6:0] ir_opcode = ir_i[6:0];
logic [2:0] funct3 = ir_i[14:12];

// ---------------------------------------------------
// Internal state signals
// ---------------------------------------------------
MatrixState state /*verilator public*/;        // Current state
MatrixState next_state;   // Next state

MatrixState vector_state /*verilator public*/;
MatrixState next_vector_state /*verilator public*/;

InstructionState ir_state;
InstructionState next_ir_state;

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
logic pcp_ld;
logic flags_ld;
logic [`PCSelectSize-1:0] pc_src;

logic ir_ld;
logic mdr_ld;

logic out_ld;
logic out_sel;

logic mem_wr;
logic mem_rd;
logic addr_src;

logic rst_src;

logic rg_wr;

logic [`AMuxSelectSize-1:0] a_src;
logic [`BMuxSelectSize-1:0] b_src;
logic [`WDSelectSize-1:0] wd_src;
logic [`ImmSelectSize-1:0] imm_src;

logic alu_ld;
logic [`ALUOpSize-1:0] alu_op;

logic take_branch;
logic jal_ld;

// ---------------------------------------------------
// Simulation
// ---------------------------------------------------
initial begin
    // Be default the CPU always attempts to start in Reset mode.
    state = Reset;
    // Also configure the reset sequence start state.
    vector_state = Vector0;
    ir_state = ITLoad;
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

    next_ir_state = ITLoad;

    halt = 1'b0;        // Disable halt regardless of state

    // PC
    pc_ld = RgLdDisabled;
    pcp_ld = RgLdDisabled;
    pc_src = PCSrcAluImm;     // Select ALU out direct

    ir_ld = RgLdDisabled;       // Disable IR loading
    mdr_ld = RgLdDisabled;      // Disable load

    // Output 
    out_ld = RgLdDisabled;
    out_sel = 1'b0;        // Reg-File

    // Memory
    mem_wr = 1'b1;      // Disable Write (active low)
    mem_rd = 1'b1;      // Disable read (active low)
    addr_src = 1'b0;    // Select PC as source

    // Reg-File
    rg_wr = 1'b1;      // Disable writing to Register-File

    a_src = ASrcPC;
    b_src = ASrcFour;

    imm_src = 3'b000;
    wd_src = 2'b00;

    alu_ld = RgLdDisabled;
    alu_op = AddOp;    // Default add operation
    flags_ld = RgLdDisabled;
    
    jal_ld = RgLdDisabled;
    take_branch = 1'b0;

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
            rst_src = 1'b1;             // Select funct3 constant

            // ------------------------------------------------------
            // Vector reset sequence
            // ------------------------------------------------------
            case (vector_state)
                Vector0: begin
                    pc_ld = RgLdEnabled;
                    pc_src = PCSrcResetVec; // Select Reset vector constant

                    next_vector_state = Vector1;
                end

                Vector1: begin
                    // PC is loaded with Vector address constant

                                     // Disable loading PC *default*
                    mem_rd = 1'b0;   // Enable read (active low)
                    
                    next_vector_state = Vector2;
                end

                Vector2: begin
                    // The address of the first instruction is now present
                    // on the Pmmu output

                    pc_ld = RgLdEnabled;
                    pc_src = PCSrcResetAdr; // Select Reset addr from mem

                    next_vector_state = Vector3;
                end

                Vector3: begin
                    // The instruction at vector address pointed to by the
                    // Vector address is now present on the Pmmu output
                    ready = 1'b1;
                    resetComplete = 1'b1;

                    mem_rd = 1'b0;      // Enable read (active low)

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

        Fetch: begin
            next_state = Fetch;

            // Memory read enabled *default*
            // Disable Loading PC *default*

            if (mem_busy_i) begin
                $display("%d Fetch busy", $stime);
                // remain in fetch until memory is ready with the data
            end
            else begin
                // $display("%d Fetch to decode", $stime);
                ir_ld = RgLdEnabled;
                pcp_ld = RgLdEnabled;  // Load register prior to incrementing

                next_state = Decode;
            end
        end

        Decode: begin
            // IR is now loaded with an instruction.

            next_state = Execute;

            // Also, take advantage of Decode to increment PC using byte-addressing
            // a_src defaults to ASrcPC = PC
            // b_src defaults to 2'b01 = +4
            // alu_op default to "Add"
            alu_ld = RgLdEnabled;
            pc_ld = RgLdEnabled;
            pc_src = PCSrcAluImm;     // Select ALU direct output

            case (ir_opcode)
                `ITYPE_L: begin
                    // Load type instructions
                    // `ifdef SIMULATE
                    //     $display("OPCODE type: ITYPE_L %x", ir_opcode);
                    // `endif
                end

                `RTYPE: begin
                    // `ifdef SIMULATE
                    //     $display("OPCODE type: RTYPE %x", ir_opcode);
                    // `endif
                    next_ir_state = RType;
                end

                `STYPE: begin
                    // `ifdef SIMULATE
                    //     $display("OPCODE type: STYPE %x", ir_opcode);
                    // `endif
                    next_ir_state = STStore;
                end

                `BTYPE: begin
                    next_ir_state = BType;
                end

                default: begin
                    `ifdef SIMULATE
                        $display("OPCODE type: UNKNOWN %x", ir_opcode);
                    `endif
                end
            endcase
        end

        Execute: begin
            // Remain in Execute until a sub-state moves us.
            next_state = Execute;

            case (ir_state)
                // ---------------------------------------------------
                // I-Type Load
                // rd = M[rs1+imm][0:N]
                // Load a value from memory into a register.
                // ---------------------------------------------------
                ITLoad: begin
                    // This requires an address to fetch from which we
                    // get from the immediate component.

                    // Compute fetch address and load into ALUOut register.
                    alu_ld = RgLdEnabled;
                    a_src = ASrcRsa;  // Select rs1 (aka RsA) source
                    b_src = ASrcImm;  // Select Immediate source
                    // The Immediate function is computed by the Immediate module
                    
                    next_ir_state = ITLDMemAcc;
                end

                ITLDMemAcc: begin
                    // ALUOut now holds the address where the data is.
                    
                    // Setup to read memory using the computed address.
                    mem_rd = 1'b0;
                    // Select the address instead of the PC
                    addr_src = 1'b1;
                    
                    next_ir_state = ITLDMemMdr;
                end

                ITLDMemMdr: begin
                    // Pmmu out now presents the data destine for
                    // the destination register
                    mem_rd = 1'b0;
                    // Maintain source selection
                    addr_src = 1'b1;

                    // Load into MDR
                    mdr_ld = RgLdEnabled;

                    next_ir_state = ITLDMemCmpl;
                end

                ITLDMemCmpl: begin
                    // MDR is now loaded

                    wd_src = 2'b10; // Select MDR output
                    rg_wr = 1'b0;   // Enable loading RegisterFile

                    // This is the last state for this instruction, so
                    // we setup to read the next instruction for the
                    // Fetch state.
                    mem_rd = 1'b0;

                    next_state = Fetch;
                end

                // ---------------------------------------------------
                // S-Type store
                // M[rs1+imm][0:31] = rs2[0:31]
                // Store a register file value to memory
                // ---------------------------------------------------
                STStore: begin
                    // First we compute the destination address
                    alu_ld = RgLdEnabled;
                    a_src = ASrcRsa;  // Select rs1 (aka RsA) source
                    b_src = ASrcImm;  // Select Immediate source
                    // The Immediate function is computed by the Immediate module

                    // Select destination address instead of PC
                    addr_src = 1'b1;

                    next_ir_state = STMemAcc;
                end

                STMemAcc: begin
                    // ALUOut is loaded with the destination address
                    // RsB is loaded with data to write

                    // Read data so the Pmmu can merge bytes/halfword instructions
                    mem_rd = 1'b0;

                    // Maintain source selection
                    addr_src = 1'b1;

                    next_ir_state = STMemWrt;
                end

                STMemWrt: begin
                    // Pmmu out has data for merging if required.

                    // Maintain source selection
                    addr_src = 1'b1;

                    // Avoid reading and writing at the same time.
                    mem_rd = 1'b1;

                    // Write to memory.
                    // Pmmu will merge data if needed.
                    mem_wr = 1'b0;

                    next_ir_state = STMemRrd;
                end

                STMemRrd: begin
                    // This is the last state for this instruction, so
                    // we setup to read the next instruction for the
                    // Fetch state.
                    mem_rd = 1'b0;

                    next_state = Fetch;
                end

                // ---------------------------------------------------
                // R-Type store
                // add, sub, xor, slt, sll etc.
                // ---------------------------------------------------
                RType: begin
                    // First we compute the destination address
                    alu_ld = RgLdEnabled;
                    a_src = ASrcRsa;  // Select rs1 (aka RsA) source
                    b_src = ASrcRsb;  // Select rs2 (aka RsB) source

                    // We ignore the lower 4 bits because this is RV32I base
                    // instructions only.
                    alu_op = {ir_i[14:12], ir_i[31:29]};

                    next_ir_state = RTCmpl;
                end

                RTCmpl: begin
                    // ALUOut is now loaded with the results

                    // Setup for writeback
                    wd_src = 2'b01;
                    rg_wr = 1'b0;

                    // Setup Fetch next instruction the PC is pointing at.
                    mem_rd = 1'b0;

                    next_state = Fetch;
                end

                // ---------------------------------------------------
                // B-Type store
                // Beq, Bne, Blt, Bge, Bltu, Bgeu etc.
                // For example: rd = rs1 + rs2
                // ---------------------------------------------------
                BType: begin
                    // rsa and rsb are now present.

                    // Compute the flags
                    alu_ld = RgLdDisabled; // We don't need the result
                    a_src = ASrcRsa;  // Select rs1 (aka RsA) source
                    b_src = ASrcRsb;  // Select rs2 (aka RsB) source
                    flags_ld = RgLdEnabled;

                    // Perform Subtract
                    alu_op = SubOp;

                    next_ir_state = BTBranch;
                end

                BTBranch: begin
                    // ALU flags are loaded

                    // Compute the branch address in case branch is taken
                    alu_ld = RgLdEnabled;
                    a_src = ASrcPrior;  // Select PC Prior source
                    b_src = ASrcImm;    // Select immediate source

                    // Depending on which branch directive, we interpret the
                    // flags differently.
                    case (funct3)
                        BTBeq: begin
                            take_branch = flags_i[`FLAG_ZERO];
                        end
                        
                        default: begin
                            `ifdef SIMULATE
                                $display("IR: BRANCH DIRECTIVE UNKNOWN");
                            `endif
                        end
                    endcase

                    if (take_branch) begin
                        pc_src = PCSrcAluImm;
                        pc_ld = RgLdEnabled;
                        // Need extra state to "re"-load PC with branch
                        next_ir_state = BTCmpl;
                    end
                    else begin
                        // Branck NOT taken continue to next instruction.
                        // Fetch next instruction the PC is pointing at.
                        mem_rd = 1'b0;
                        next_state = Fetch;
                    end
                end

                BTCmpl: begin
                    // PC now has branch address

                    // Setup Fetch next instruction the PC is pointing at.
                    mem_rd = 1'b0;

                    next_state = Fetch;
                end

                default:
                    `ifdef SIMULATE
                        $display("IR: UNKNOWN");
                    `endif
            endcase
        end

        Halt: begin
            // E instruction trigger a halt
            `ifdef SIMULATE
                $display("Halt");
            `endif

            halt = 1'b1;
            ready = 1'b0;

            // We can only exit this state on a reset.
            next_state = Halt;
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
        if (resetComplete) begin
            state <= next_state;
            ir_state <= next_ir_state;
        end
        else begin
            state <= Reset;
            vector_state <= next_vector_state;
        end
end

// -------------------------------------------------------------
// Route internal signals to outputs
// -------------------------------------------------------------
assign pc_ld_o = pc_ld;
assign pcp_ld_o = pcp_ld;
assign flags_ld_o = flags_ld;
assign pc_src_o = pc_src;
assign ir_ld_o = ir_ld;
assign mem_wr_o = mem_wr;
assign mem_rd_o = mem_rd;
assign addr_src_o = addr_src;
assign rg_wr_o = rg_wr;
assign a_src_o = a_src;
assign b_src_o = b_src;
assign imm_src_o = imm_src;
assign wd_src_o = wd_src;
assign alu_ld_o = alu_ld;
assign jal_id_o = jal_ld;
assign rst_src_o = rst_src;
assign mdr_ld_o = mdr_ld;
assign alu_op_o = alu_op;

`ifdef DEBUG_MODE
assign out_ld_o = out_ld;
assign out_sel_o = out_sel;
assign ready_o = ready;
assign halt_o = halt;
`endif

endmodule
