`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

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
    parameter DATA_WIDTH = 8
)
(
    input  logic   [DATA_WIDTH-1:0] a_i,      // rs1
    input  logic   [DATA_WIDTH-1:0] b_i,      // rs2 or (Immediate and/or Extended)
    input  ALU_Ops func_op_i,                 // Operation
    output logic   [DATA_WIDTH-1:0] y_o,      // Results output
    output logic   [`FlagSize-1:0]  flags_o   // Flags: V,N,C,Z
);

logic [DATA_WIDTH-1:0] ORes;

// ^^^---^^^---^^^---^^^---^^^---^^^---^^^---^^^---^^^---^^^---^^^---^^^---
// Shift right arithmetic (insert high-order sign bit into empty bits)
// vvv---vvv---vvv---vvv---vvv---vvv---vvv---vvv---vvv---vvv---vvv---vvv---
// To do this we create a (2*DATA_WIDTH) bit signed extended version of a_i
logic [2*DATA_WIDTH-1:0] sext_a;

// I add the lint_off directive because the upper 32 bits aren't used.
// They are merely assigned for shifting.
/*verilator lint_off UNUSED*/
logic [2*DATA_WIDTH-1:0] sra;
/*verilator lint_on UNUSED*/

logic [DATA_WIDTH-2:0] lower_bits;
logic carry_borrow_l; // DATA_WIDTH-2
logic carry_borrow_h; // DATA_WIDTH-1

always_comb begin
    // Initial conditions
    ORes = {DATA_WIDTH{1'b0}};
    sext_a = 0;
    sra = 0;
    carry_borrow_l = 0;
    carry_borrow_h = 0;
    lower_bits = {DATA_WIDTH-1{1'b0}};

    case (func_op_i)
        AddOp: begin
            {carry_borrow_l, lower_bits} = a_i[DATA_WIDTH-2:0] + b_i[DATA_WIDTH-2:0];
            {carry_borrow_h, ORes} = a_i[DATA_WIDTH-1:0] + b_i[DATA_WIDTH-1:0];
        end
        
        SubOp: begin  // As if the Carry_In == 0
            {carry_borrow_l, lower_bits} = a_i[DATA_WIDTH-2:0] - b_i[DATA_WIDTH-2:0];
            {carry_borrow_h, ORes} = a_i[DATA_WIDTH-1:0] - b_i[DATA_WIDTH-1:0];
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
        
        SllOp: begin    // Shift left logical a_i by b_i amount
            {carry_borrow_h, ORes} = {a_i[DATA_WIDTH-1], a_i << b_i};
        end

        SrlOp: begin    // Shift right logical a_i by b_i amount
            {carry_borrow_h, ORes} = {a_i[0], a_i >> b_i};
        end

        SraOp: begin    // Shift right arithmetic
            sext_a = {{DATA_WIDTH{a_i[DATA_WIDTH-1]}}, a_i};  // Sign extend to 64 bits.
            sra = sext_a >> b_i;    // Shift pulling in sign bits from upper 32 bits
            ORes = sra[DATA_WIDTH-1:0];       // Truncate back to 32 bits for ouput
        end

        SltOp: begin    // Set less than signed
            if (a_i[DATA_WIDTH-1] == b_i[DATA_WIDTH-1]) begin
                // If both sign bits are set then we need to compare.
                ORes = {{DATA_WIDTH-1{1'b0}}, a_i < b_i};
            end
            else begin
                // Otherwise we check the lhs (i.e. a_i)
                // if a_i sign bit is set then that implies that b_i isn't which means
                // a_i must be < b_i because signed numbers will always be smaller than
                // unsigned.
                // And the inverse applies with similar math rules.
                ORes = {{DATA_WIDTH-1{1'b0}}, a_i[DATA_WIDTH-1]};
            end
        end

        // Upper filled with zeroes
        SltuOp: begin   // Set less than unsigned
            ORes ={{DATA_WIDTH-1{1'b0}}, a_i < b_i};
        end

        default: begin
            `ifdef SIMULATE
                $display("%d *** ALU UNKNOWN OP: %04b", $stime, func_op_i);
            `endif

            ORes = {DATA_WIDTH{1'bx}};
        end
    endcase
end

// VNCZ
// 3210
assign flags_o = {
    carry_borrow_l ^ carry_borrow_h,  // V
    ORes[DATA_WIDTH-1],               // N
    carry_borrow_h,                   // C
    ORes == {DATA_WIDTH{1'b0}}        // Z
};

assign y_o = ORes;

endmodule

// Flags
// https://stackoverflow.com/questions/57452447/riscv-how-the-branch-intstructions-are-calculated


// https://www.reddit.com/r/asm/comments/leyv7g/can_someone_explain_to_me_why_this_is_an_overflow/
// https://www.doc.ic.ac.uk/~eedwards/compsys/arithmetic/index.html
// Add only: http://teaching.idallen.com/dat2343/10f/notes/040_overflow.txt
    // ~(~(a_i[DATA_WIDTH-1] ^ b_i[DATA_WIDTH-1]) & ((a_i[DATA_WIDTH-1] & b_i[DATA_WIDTH-1]) ^ ORes[DATA_WIDTH-1])),  // V = !(!(a^b) & (a&b)^s))
// Overflow: https://suchprogramming.com/beginning-logic-design-part-7/  and part 6
// https://azeria-labs.com/arm-conditional-execution-and-branching-part-6/
// http://www.mathcs.emory.edu/~cheung/Courses/255/Syl-ARM/7-ARM/cmp+bra.html
// http://staffwww.fullcoll.edu/aclifton/cs241/lecture-branching-comparisons.html
// https://stackoverflow.com/questions/32805087/how-is-overflow-detected-in-twos-complement
