`default_nettype none

// --------------------------------------------------------------------------
// ALU
// The ALU only sees two N-bits pieces of data.
// It doesn't care if one of them is sourced from an Immediate path or
// register path. The operation could be: "A op B" or "A op Imm", yet the
// ALU wouldn't know or care, it simply appears as "A op B".
// In other words the operands have already been prepared prior.
// --------------------------------------------------------------------------
module ALU
#(
    parameter DATA_WIDTH = 32
)
(
    input  logic   [DATA_WIDTH-1:0] a_i,  // rs1
    input  logic   [DATA_WIDTH-1:0] b_i,  // rs2 or (Immediate and/or Extended)
    input  ALU_Ops func_op_i,             // Operation
    output logic   [DATA_WIDTH-1:0] y_o   // Results output
);

logic [DATA_WIDTH-1:0] ORes;

// ^^^---^^^---^^^---^^^---^^^---^^^---^^^---^^^---^^^---^^^---^^^---^^^---
// Shift right arithmetic (insert high-order sign bit into empty bits)
// vvv---vvv---vvv---vvv---vvv---vvv---vvv---vvv---vvv---vvv---vvv---vvv---
// To do this we create a (2*DATA_WIDTH) bit signed extended version of a_i
logic [2*DATA_WIDTH-1:0] sext_a;

// I add the lint_off directive because the upper 32 bits aren't used.
// They are merely assigned for shifting.
/* verilator lint_off UNUSED */
logic [2*DATA_WIDTH-1:0] sra;
/* verilator lint_on UNUSED */

always_comb begin
    // Initial conditions
    ORes = {DATA_WIDTH{1'b0}};
    sext_a = 0;
    sra = 0;

    case (func_op_i)
        AddOp: begin
            // If Carry or Borrow is involved
            // {cF, ORes} = a_i + b_i + carbor_flag_i;
            // Using ternary correctly expands flag to data width without
            // issuing warnings
            // {cF, ORes} = a_i + b_i + (carbor_flag_i ? 1 :0);
            // Or this style using replication
            // {cF, ORes} = a_i + b_i + {{DATA_WIDTH-1{1'b0}},carbor_flag_i}; // carbor_flag_i = carry

            // RISC-V doesn't work with Carry/Borrow directly
            ORes = a_i + b_i;
        end
        
        SubOp: begin  // As if the Carry == 0
            ORes = a_i - b_i;
        end
        
        AndOp: begin
            ORes = a_i & b_i;
        end
        
        OrOp: begin
            ORes = a_i | b_i;
        end
        
        XorOp: begin
            ORes = a_i ^ b_i;
        end
        
        SltuOp: begin   // Set less than unsigned
            // Upper filled with zeroes
            ORes ={31'b0, a_i < b_i};
        end
        
        SltOp: begin    // Set less than signed
            // If both sign bits are set then we need to compare.
            // Otherwise we check the lhs (i.e. a_i)
            // if a_i sign bit is set then that implies that b_i isn't which means
            // a_i must be < b_i because signed numbers will always be smaller than
            // unsigned.
            // And the inverse applies with similar math rules.
            ORes = a_i[31] == b_i[31] ? {31'b0, a_i < b_i} : {31'b0, a_i[31]};
        end
        
        SllOp: begin    // Shift left logical a_i by b_i amount
            ORes = a_i << b_i;
        end

        SrlOp: begin    // Shift right logical a_i by b_i amount
            ORes = a_i >> b_i;
        end

        SraOp: begin    // Shift right arithmetic
            sext_a = {{32{a_i[31]}}, a_i};  // Sign extend to 64 bits.
            sra = sext_a >> b_i;    // Shift and pull in sign bits from upper 32 bits
            ORes = sra[31:0];       // Truncate back to 32 bits for ouput
        end

        default: begin
            `ifdef SIMULATE
                $display("%d *** ALU UNKNOWN OP: %04b", $stime, func_op_i);
            `endif

            ORes = {DATA_WIDTH{1'bx}};
        end
    endcase
end

assign y_o = ORes;

endmodule
