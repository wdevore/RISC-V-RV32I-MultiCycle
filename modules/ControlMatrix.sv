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

/*verilator public_module*/     // <-- redudant

// For RV32I the lower 2 bits are always 11 so we could
// ignore them--but we won't.
logic [6:0] ir_opcode = ir_i[6:0];
logic [2:0] funct3 = ir_i[14:12];
// Used for Jal optimization
logic [4:0] dstRg = ir_i[11:7];
logic is_word_size = funct3[1:0] == `WORD_SIZE;

// The Shift operations have additional info in the upper
// 3 bits. R-Types call this funct7 but I-Types alias it.
logic [2:0] funct7up = ir_i[31:29];

// ---------------------------------------------------
// Internal state signals
// ---------------------------------------------------
MatrixState state /*verilator public*/;  // Current state
MatrixState next_state;                  // Next state

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
    rg_wr = RgLdDisabled;      // Disable writing to Register-File

    a_src = ASrcPC;
    b_src = BSrcFour;

    imm_src = 3'b000;
    wd_src = WDSrcImm;

    alu_ld = RgLdDisabled;
    alu_op = AddOp;    // Default add operation
    flags_ld = RgLdDisabled;
    
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
                pcp_ld = RgLdEnabled;  // Load register PC-prior before incrementing PC

                next_state = Decode;
            end
        end

        Decode: begin
            // IR is now loaded with an instruction.

            next_state = Execute;

            // Also, take advantage of Decode to increment PC (PC+4). This is the
            // default ALU setup above. So we just enable the loads
            alu_ld = RgLdEnabled;
            pc_ld = RgLdEnabled;
            pc_src = PCSrcAluImm;     // Select ALU direct output

            // Set next InsRtuction state
            case (ir_opcode)
                `ITYPE_E: begin
                    if (ir_i[20] == 1'b1)
                        next_ir_state = ITEbreak;
                    else begin
                        next_ir_state = ITECall;
                    end
                end

                `RTYPE: begin
                    next_ir_state = RType;
                end

                `ITYPE: begin
                    next_ir_state = ITALU;
                end

                `ITYPE_L: begin
                    // Default: Load type instructions
                    // `ifdef SIMULATE
                    //     $display("OPCODE type: ITYPE_L %x", ir_opcode);
                    // `endif
                end

                `ITYPE_J: begin
                    next_ir_state = ITJalr;
                end

                `STYPE: begin
                    next_ir_state = STStore;
                end

                `BTYPE: begin
                    next_ir_state = BType;
                end
                
                `JTYPE: begin
                    next_ir_state = JTJal;
                end

                `UTYPE_L: begin
                    next_ir_state = UType;
                end

                `UTYPE_A: begin
                    next_ir_state = UTypeAui;
                end

                default: begin
                    `ifdef SIMULATE
                        $display("OPCODE type: UNKNOWN %x", ir_opcode);
                    `endif
                end
            endcase
        end

        Execute: begin
            // PC now equals PC_prior + 4

            // Remain in Execute until a sub-state moves us.
            next_state = Execute;

            case (ir_state)
                // ---------------------------------------------------
                // R-Type ALU
                // add, sub, xor, slt, sll etc.
                // ---------------------------------------------------
                RType: begin
                    // First we compute the results
                    alu_ld = RgLdEnabled;
                    a_src = ASrcRsa;  // Select rs1 (aka RsA) source
                    b_src = BSrcRsb;  // Select rs2 (aka RsB) source

                    // We ignore the lower 4 bits because this is RV32I base
                    // instructions only.
                    alu_op = {funct3, funct7up};

                    // ------ Optimization ------
                    // If the destination register is x0 then
                    // we don't need a writeback cycle so just
                    // transition to fetch.
                    // This effectively is a NOP
                    if (dstRg == 5'b00000) begin
                        mem_rd = 1'b0;
                        next_state = Fetch;
                    end
                    else
                        next_ir_state = RTCmpl;
                end

                RTCmpl: begin
                    // ALUOut is now loaded with the results

                    // Setup for writeback
                    wd_src = WDSrcALUOut;
                    rg_wr = RgLdEnabled;

                    // Setup Fetch next instruction the PC is pointing at.
                    mem_rd = 1'b0;

                    next_state = Fetch;
                end

                // ---------------------------------------------------
                // I-Type ALU immediate
                // addi, xori, ori andi, ssli, srli, srai, slti, sltiu
                // ---------------------------------------------------
                ITALU: begin
                    // Compute results
                    alu_ld = RgLdEnabled;
                    a_src = ASrcRsa;
                    b_src = BSrcImm;

                    // We only need the 3 upper bits when the I-Type is
                    // slli, (srli, srai) in order to further narrow
                    // the operation, otherwise use zero.
                    if (funct3 == ITSlli || funct3 == ITSrli)
                        alu_op = {funct3, funct7up};
                    else
                        alu_op = {funct3, 3'b000};

                    // ------ Optimization ------
                    // If the destination register is x0 then
                    // we don't need a writeback cycle so just
                    // transition to fetch.
                    // This effectively is a NOP
                    if (dstRg == 5'b00000) begin
                        mem_rd = 1'b0;
                        next_state = Fetch;
                    end
                    else
                        next_ir_state = ITALUCmpl;
                end

                ITALUCmpl: begin
                    // ALUOut has results

                    // Setup for writeback
                    wd_src = WDSrcALUOut;
                    rg_wr = RgLdEnabled;


                    // Setup Fetch next instruction the PC is pointing at.
                    mem_rd = 1'b0;

                    next_state = Fetch;
                end

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
                    b_src = BSrcImm;  // Select Immediate source
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

                    wd_src = WDSrcMDR;
                    rg_wr = RgLdEnabled;   // Enable loading RegisterFile

                    // This is the last state for this instruction, so
                    // we setup to read the next instruction for the
                    // Fetch state.
                    mem_rd = 1'b0;

                    next_state = Fetch;
                end

                // ---------------------------------------------------
                // I-Type jalr
                // ---------------------------------------------------
                ITJalr: begin
                    // Compute the jump address: PC = rs1 + imm
                    a_src = ASrcRsa;
                    b_src = BSrcImm;

                    // Load PC
                    pc_src = PCSrcAluImm;
                    pc_ld = RgLdEnabled;

                    // ------ Optimization ------
                    // If the destination register is x0 then
                    // we don't need a writeback cycle so just
                    // transition to complete.
                    if (dstRg == 5'b00000)
                        next_ir_state = PreFetch;
                    else
                        next_ir_state = ITJalrRtr;
                end

                ITJalrRtr: begin
                    // Compute the return address: rd = PC+4.
                    a_src = ASrcPrior;
                    b_src = BSrcFour;

                    // Setup for writeback
                    wd_src = WDSrcImm;
                    rg_wr = RgLdEnabled;

                    next_ir_state = PreFetch;
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
                    b_src = BSrcImm;  // Select Immediate source
                    // The Immediate function is computed by the Immediate module

                    // Select destination address instead of PC
                    addr_src = 1'b1;

                    if (is_word_size)
                        next_ir_state = STMemWrt;
                    else
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
                    // Pmmu out has data for merging(byte/halfword) if required.

                    // Maintain source selection
                    addr_src = 1'b1;

                    // Avoid reading and writing at the same time.
                    mem_rd = 1'b1;

                    // Write to memory.
                    // Pmmu will merge data if needed.
                    mem_wr = 1'b0;

                    next_ir_state = PreFetch;
                end

                // ---------------------------------------------------
                // B-Type branch
                // Beq, Bne, Blt, Bge, Bltu, Bgeu etc.
                // ---------------------------------------------------
                BType: begin
                    // rsa and rsb are now present.

                    // Compute the flags
                    a_src = ASrcRsa;  // Select rs1 (aka RsA) source
                    b_src = BSrcRsb;  // Select rs2 (aka RsB) source
                    // Save them
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
                    b_src = BSrcImm;    // Select immediate source

                    // Depending on which branch directive, we interpret the
                    // flags differently.
                    case (funct3)
                        BTBeq: begin
                            // Branch if Z=1
                            take_branch = flags_i[`FLAG_ZERO];
                        end

                        BTBne: begin
                            // Branch if Z=0
                            take_branch = ~flags_i[`FLAG_ZERO];
                        end

                        BTBlt: begin
                            // If the two operands are considered signed
                            // then N!=V is interpreted as "rs1 is less than rs2"
                            take_branch = flags_i[`FLAG_NEGATIVE] ^ flags_i[`FLAG_OVERFLOW];
                        end

                        BTBge: begin
                            // If the two operands are considered signed
                            // then N==V is interpreted as "rs1 >= rs2"
                            take_branch = flags_i[`FLAG_NEGATIVE] == flags_i[`FLAG_OVERFLOW];
                        end

                        BTBltu: begin
                            // The two operands are considered unsigned, 
                            // We interpret C=1, for example, "3 < FFFFFFFE".
                            take_branch = flags_i[`FLAG_CARRY];
                        end

                        BTBgeu: begin
                            // The two operands are considered unsigned, 
                            // We interpret C=0, for example, "FFFFFFFE >= 5".
                            take_branch = ~flags_i[`FLAG_CARRY];
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
                        next_ir_state = PreFetch;
                    end
                    else begin
                        // Branch NOT taken continue to next instruction.
                        // Fetch next instruction the PC is pointing at.
                        mem_rd = 1'b0;
                        next_state = Fetch;
                    end
                end

                // ---------------------------------------------------
                // J-Type jal
                // ---------------------------------------------------
                JTJal: begin
                    // Compute the jump address: PC += imm
                    a_src = ASrcPrior;
                    b_src = BSrcImm;

                    // Load PC
                    pc_src = PCSrcAluImm;
                    pc_ld = RgLdEnabled;

                    // ------ Optimization ------
                    // If the destination register is x0 then
                    // we don't need a writeback cycle so just
                    // transition to complete.
                    if (dstRg == 5'b00000)
                        next_ir_state = PreFetch;
                    else
                        next_ir_state = JTJalRtr;
                end

                JTJalRtr: begin
                    // Compute the return address: rd = PC+4.
                    a_src = ASrcPrior;
                    b_src = BSrcFour;

                    // Setup for writeback
                    wd_src = WDSrcImm;
                    rg_wr = RgLdEnabled;

                    next_ir_state = PreFetch;
                end

                // ---------------------------------------------------
                // U-Type lui
                // ---------------------------------------------------
                UType: begin
                    // rd = imm
                    a_src = ASrcZero;
                    b_src = BSrcImm;

                    // Setup for writeback
                    wd_src = WDSrcImm;
                    rg_wr = RgLdEnabled;

                    next_ir_state = PreFetch;
                end

                // ---------------------------------------------------
                // U-Type auipc
                // ---------------------------------------------------
                UTypeAui: begin
                    // rd = PC + imm
                    a_src = ASrcPrior;
                    b_src = BSrcImm;

                    // Setup for writeback
                    wd_src = WDSrcImm;
                    rg_wr = RgLdEnabled;

                    next_ir_state = PreFetch;
                end

                // ---------------------------------------------------
                // I-Type ecall, ebreak 
                // ---------------------------------------------------
                ITEbreak: begin
                    ready = 1'b0; // Signal the great unknown!
                    halt = 1'b1;
                    next_ir_state = ITEbreak;
                end

                ITECall: begin
                    next_ir_state = ITECall;
                end

                PreFetch: begin
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
