`default_nettype none

// --------------------------------------------------------------------------
// ALU
// Operations:
//   Add, Sub
//   Shift left/right
//   Compare
// Flags:
//   Flag        bit
//   Z zero      0
//   C carry     1
//   N negative  2
//   V Overflow  3
// The output is tri capable.
// --------------------------------------------------------------------------

// Add/Subtract references used for the ALU
// https://en.wikipedia.org/wiki/Carry_flag#
// http://teaching.idallen.com/dat2343/10f/notes/040_overflow.txt
typedef enum logic [3:0] {
    AddOp,
    SubOp
} ALU_Operations /*verilator public*/; 

typedef enum logic [1:0] {
    ZeroFlag,
    CarryFlag,
    NegFlag,
    OverFlag
} ALU_Flags /*verilator public*/; 

module ALU
#(
    parameter DATA_WIDTH = 32, // Bitwidth, Default to 16 bits
                               // 3 2 1 0
    parameter FLAG_BITS = 4    // V,N,C,Z
)
(
    input  logic carbor_flag_i,             // Carry or borrow flag
    input  logic [DATA_WIDTH-1:0] a_i,
    input  logic [DATA_WIDTH-1:0] b_i,
    input  logic [3:0] func_op_i,           // Operation
    output logic [DATA_WIDTH-1:0] y_o,      // Results output
    output logic [FLAG_BITS-1:0] flags_o    // Flag result
);

reg [DATA_WIDTH-1:0] ORes;
reg cF;

always_comb begin
    // Initial conditions
    ORes = {DATA_WIDTH{1'b0}};// {DATA_WIDTH{1'bx}};
    cF = 1'b0;

    case (func_op_i)
        AddOp: begin
            `ifdef SIMULATE
                $display("%d Add_OP: A: %h, B: %h", $stime, a_i, b_i);
            `endif

            // Carry and sum
            // Using ternary correctly expands flag to data width without
            // issuing warnings
            // {cF, ORes} = a_i + b_i + carbor_flag_i;
            // {cF, ORes} = a_i + b_i + (carbor_flag_i ? 1 :0);
            // Or this style using replication
            {cF, ORes} = a_i + b_i + {{DATA_WIDTH-1{1'b0}},carbor_flag_i}; // carbor_flag_i = carry
            `ifdef SIMULATE
                $display("%d Add_OP: Carry %b, Sum %h", $stime, cF, ORes);
            `endif
        end
        SubOp: begin  // As if the Carry == 0
            `ifdef SIMULATE
                $display("%d Sub_OP: A: %h - B: %h", $stime, a_i, b_i);
            `endif

            {cF, ORes} = a_i - b_i;  // carbor_flag_i = borrow NOT USED
            `ifdef SIMULATE
                $display("%d Sub_OP: Carry %b, Diff %h", $stime, cF, ORes);
            `endif
        end
        // `SHL: begin // Logical shift
        //     `ifdef SIMULATE
        //         $display("%d Shl_OP: (%d) << (%d)", $stime, a_i, b_i);
        //     `endif
        //     // The left hand side contains the variable to shift,
        //     // the right hand side contains the number of shifts to perform
        //     {cF, ORes} = {a_i[DATA_WIDTH-1], a_i << b_i};
        // end
        // `SHR: begin // Logical shift (Arithmetic is >>>)
        //     `ifdef SIMULATE
        //         $display("%d Shr_OP: (%d) >> (%d)", $stime, a_i, b_i);
        //     `endif
        //     {cF, ORes} = {a_i[0], a_i >> b_i};
        // end
        default: begin
            `ifdef SIMULATE
                $display("%d *** ALU UNKNOWN OP: %04b", $stime, func_op_i);
            `endif
            ORes = {DATA_WIDTH{1'b0}};// {DATA_WIDTH{1'bx}};
        end
    endcase
end

// Set remaining flags
// assign zF = ORes == {DATA_WIDTH{1'b0}};  // Zero
// assign nF = ORes[DATA_WIDTH-1];          // Negative

// 2's compliment overflow flag
// The rules for turning on the overflow flag in binary/integer math are two:
// 1. If the sum of two numbers with the sign bits off yields a result number
//    with the sign bit on, the "overflow" flag is turned on.
// 2. If the sum of two numbers with the sign bits on yields a result number
//    with the sign bit off, the "overflow" flag is turned on.
// assign oF = (
//         // Input Sign-bits Off yet Result sign-bit On 
//         ((A[DATA_WIDTH-1] == 0) && (B[DATA_WIDTH-1] == 0) && (ORes[DATA_WIDTH-1] == 1)) ||
//         // Input Sign-bits On yet Result sign-bit Off
//         ((A[DATA_WIDTH-1] == 1) && (B[DATA_WIDTH-1] == 1) && (ORes[DATA_WIDTH-1] == 0))
//     );

assign flags_o = {
    (
        // Input Sign-bits Off yet Result sign-bit On 
        ((a_i[DATA_WIDTH-1] == 0) && (b_i[DATA_WIDTH-1] == 0) && (ORes[DATA_WIDTH-1] == 1)) ||
        // Input Sign-bits On yet Result sign-bit Off
        ((a_i[DATA_WIDTH-1] == 1) && (b_i[DATA_WIDTH-1] == 1) && (ORes[DATA_WIDTH-1] == 0))
    ),                          // V
    ORes[DATA_WIDTH-1],         // N
    cF,                         // C
    ORes == {DATA_WIDTH{1'b0}}  // Z
};

assign y_o = ORes;

endmodule
