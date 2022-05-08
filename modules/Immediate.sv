`ifdef SIMULATE
`timescale 1ns/1ps
`endif

module Immediate
#(
    parameter DATA_WIDTH = 32
)
(
    /*verilator lint_off UNUSED*/     // suppress unused bits warning
    input logic [DATA_WIDTH-1:0] ir_i,      // Instruction register
    /*verilator lint_on UNUSED*/
    output logic [DATA_WIDTH-1:0] imm_o /*verilator public*/    // Imm extended or Amount(s)
);

/*verilator public_module*/

logic sign = ir_i[31];
logic [6:0] ir_opcode = ir_i[6:0];
logic [2:0] imm_src;
logic [2:0] funct3 = ir_i[14:12];
logic [4:0] shamt = ir_i[24:20];

// Set imm_src 
always_comb begin
    case (ir_opcode)
        `ITYPE: begin
            imm_src = 3'b000;   // Default to standard I-Type

            // Is this a specialization of shifting I-Type
            if (funct3 == `SLLI || funct3 == `SRLI) // includes SRAI
                imm_src = 3'b101;   // shift amount = shamt
        end

        `ITYPE_L, `ITYPE_J, `ITYPE_E: imm_src = 3'b000;

        `STYPE: imm_src = 3'b001;

        `BTYPE: imm_src = 3'b010;

        `UTYPE_L, `UTYPE_A: imm_src = 3'b011;

        `JTYPE: imm_src = 3'b100;

        default:
            imm_src = 3'b111;

    endcase
end

Mux8 #(.DATA_WIDTH(DATA_WIDTH), .SELECT_SIZE(3)) mux
(
    .select_i(imm_src),
    .data0_i({{21{sign}}, ir_i[30:25], ir_i[24:21], ir_i[20]}),                     // I-Type
    .data1_i({{21{sign}}, ir_i[30:25], ir_i[11:8], ir_i[7]}),                       // S-Type
    .data2_i({{20{sign}}, ir_i[7], ir_i[30:25], ir_i[11:8], 1'b0}),                 // B-Type
    .data3_i({sign, ir_i[30:20], ir_i[19:12], 12'b0}),                              // U-Type
    .data4_i({{12{sign}}, ir_i[19:12], ir_i[20], ir_i[30:25], ir_i[24:21], 1'b0}),  // J-Type
    .data5_i({27'b0, shamt}),                                                       // shamt
    .data6_i({DATA_WIDTH{1'bx}}),                                                   
    .data7_i({DATA_WIDTH{1'b0}}),    // Can be used to route a Zero to SrcB
    .data_o(imm_o)
);

endmodule
