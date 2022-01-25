`default_nettype none

// --------------------------------------------------------------------------
// Pseudo memory management unit
// --------------------------------------------------------------------------

module Pmmu
#(
    parameter WORDS = 10,    // 2^WORDS = 1K
    parameter DATA_WIDTH = 32)
(
    input  logic                  clk_i,     // pos-edge

    /* verilator lint_off UNUSED */          // suppress unused bits warning
    input  logic [DATA_WIDTH-1:0] ir_i,      // Instruction register
    // "addr_i" will be either PC or a ALU computed value.
    input  logic [DATA_WIDTH-1:0] addr_i,    // Memory addr_i (Word addressing format)
    /* verilator lint_on UNUSED */

    input  logic [DATA_WIDTH-1:0] wd_i,      // Memory data input for writing
    input  logic                  mwr_i,     // Write enable (Active Low)
    input  logic                  mrd_i,     // Memory read (Active Low)

    output logic [DATA_WIDTH-1:0] rd_o,      // Memory data output
    output logic                  mem_rdy_o  // Memory is ready (Active High), busy (Active Low)
);

// ^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--
// destructure the Instruction for Load operations
// ^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--
logic [2:0] funct3 = ir_i[14:12];

// Capture operation type. The upper bit (bit 3) is the sign indicator
logic signed_op = !funct3[2];       // 0 = signed, 1 = unsigned

// Determine the data-size of the operation
logic is_byte_size     = funct3[1:0] == 2'b00;
logic is_halfword_size = funct3[1:0] == 2'b01;
// Word = 2'b10;

// Because BRAM is organized as 32bit words and our PC increments
// by 4 "bytes", that means if we used the incoming address it
// will have "skipped" over 3 bytes. This means we need to convert
// from word-addressing to byte-addressing.
// We do this by logically shifting right by 2.
// (i.e. ignoring the lower 2 bits)
logic [WORDS-1:0] word_addr = {addr_i[WORDS-1:2], 2'b00} >> 2; // = {2'b00, addr_i[DATA_WIDTH-1:2]}
logic [DATA_WIDTH-1:0] storage_data;    // Output from BRAM

logic [7:0] byte_data;
logic [1:0] byte_selector = addr_i[1:0];    // Use byte-addressing

Mux4 #(.DATA_WIDTH(DATA_WIDTH/4)) byte_mux
(
    .select_i(byte_selector),
    .data0_i(storage_data[7:0]),
    .data1_i(storage_data[15:8]),
    .data2_i(storage_data[23:16]),
    .data3_i(storage_data[31:24]),
    .data_o(byte_data)
);

logic [15:0] halfword_data;
logic halfword_selector = addr_i[1];  // Use byte-addressing

Mux2 #(.DATA_WIDTH(DATA_WIDTH/2)) halfword_mux
(
    .select_i(halfword_selector),
    .data0_i(storage_data[15:0]),
    .data1_i(storage_data[31:16]),
    .data_o(halfword_data)
);

// Determine the sign bit:
// With the data-size we can locate the data's sign bit but only if
// the instruction is specifying a signed operation, otherwise we
// default to unsigned (i.e. Zero extend)
logic data_sign = signed_op ? is_byte_size ? byte_data[7] : halfword_data[15] : 0;

// ^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--
// Instruction for Store operations
// ^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--
logic [DATA_WIDTH-1:0] store_byte_data;
logic [DATA_WIDTH-1:0] store_halfword_data;

Mux4 #(.DATA_WIDTH(DATA_WIDTH)) store_byte_mux
(
    .select_i(byte_selector),
    .data0_i({storage_data[31:8],  wd_i[7:0]}),
    .data1_i({storage_data[31:16], wd_i[15:8],  storage_data[7:0]}),
    .data2_i({storage_data[31:24], wd_i[23:16], storage_data[15:0]}),
    .data3_i({wd_i[31:24],         storage_data[23:0]}),
    .data_o(store_byte_data)
);

Mux2 #(.DATA_WIDTH(DATA_WIDTH)) store_halfword_mux
(
    .select_i(halfword_selector),
    .data0_i({storage_data[31:16],  wd_i[15:0]}),
    .data1_i({wd_i[31:16],  storage_data[15:0]}),
    .data_o(store_halfword_data)
);

logic [DATA_WIDTH-1:0] store_data;

always_comb begin
    rd_o = {DATA_WIDTH{1'bx}};
    store_data = wd_i;

    if (~mrd_i) begin   // Load
        // Sign extend 8 or 16 bit loads
        if (is_byte_size)
            rd_o = {{24{data_sign}}, byte_data};
        else if (is_halfword_size)
            rd_o = {{16{data_sign}}, halfword_data};
        else
            rd_o = storage_data;
    end

    if (~mwr_i) begin   // Store
        if (is_byte_size)
            store_data = store_byte_data;
        else if (is_halfword_size)
            store_data = store_halfword_data;
    end
end

// ~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**
// Memory (BRAM, SRAM...)
// Memory is organized as [N-addresses x 32-bits].
// ~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**
assign mem_rdy_o = 1'b1;        // BRAM is always ready

Memory #(.WORDS(WORDS)) bram(
    .clk_i(clk_i),
    .data_i(store_data),
    .addr_i(word_addr[9:0]),
    .wr_i(mwr_i),
    .data_o(storage_data)
);

endmodule

