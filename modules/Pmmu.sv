`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// --------------------------------------------------------------------------
// Pseudo memory management unit
// --------------------------------------------------------------------------

module Pmmu
#(
    parameter WORDS = 10,    // 10-bits 2^WORDS = 1K
    parameter DATA_WIDTH = 32)
(
    input  logic                  clk_i,     // pos-edge

    /*verilator lint_off UNUSED*/          // suppress unused bits warning
    input  logic [2:0]            funct3,    // funct3 = ir_i[14:12] of Instruction register
    // "byte_addr_i" will be either PC or a ALU computed value.
    input  logic [DATA_WIDTH-1:0] byte_addr_i,    // Memory byte_addr_i (Byte addressing format)
    /*verilator lint_on UNUSED*/

    input  logic [DATA_WIDTH-1:0] wd_i,      // Memory data input for writing
    input  logic                  mwr_i,     // Write enable (Active Low)
    input  logic                  mrd_i,     // Memory read (Active Low)

    output logic [DATA_WIDTH-1:0] rd_o,      // Memory data output
    output logic                  mem_rdy_o  // Memory is ready (Active High), busy (Active Low)
);

/*verilator public_module*/

// ^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--
// Destructure the Instruction:
// logic for Load/Store operations
// ^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--

// Capture operation type. The upper bit (bit 3) is the sign indicator
logic signed_op = !funct3[2];       // 0 = signed, 1 = unsigned

// Determine the data-size of the operation
logic is_byte_size     = funct3[1:0] == `BYTE_SIZE;
logic is_halfword_size = funct3[1:0] == `HALFWORD_SIZE;

// Because BRAM is organized as 32bit words and our PC increments
// by 4 "bytes", that means if we used the incoming address it
// will have "skipped" over 3 bytes, which means we need to convert
// from byte-addressing to word-addressing.
// We do this by logically shifting right by 2.
// (i.e. ignoring the lower 2 bits)
logic [WORDS-1:0] word_addr = byte_addr_i[WORDS+1:2];
logic [DATA_WIDTH-1:0] storage_data_out;    // Output from BRAM

logic [7:0] byte_data;
logic [1:0] byte_selector = byte_addr_i[1:0];    // Use byte-addressing

Mux4 #(.DATA_WIDTH(DATA_WIDTH/4)) byte_mux
(
    .select_i(byte_selector),
    .data0_i(storage_data_out[7:0]),
    .data1_i(storage_data_out[15:8]),
    .data2_i(storage_data_out[23:16]),
    .data3_i(storage_data_out[31:24]),
    .data_o(byte_data)
);

logic [15:0] halfword_data;
logic halfword_selector = byte_addr_i[1];  // Use byte-addressing

Mux2 #(.DATA_WIDTH(DATA_WIDTH/2)) halfword_mux
(
    .select_i(halfword_selector),
    .data0_i(storage_data_out[15:0]),
    .data1_i(storage_data_out[31:16]),
    .data_o(halfword_data)
);

// ^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--
// Logic for Store operations
// ^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--^^--
logic [DATA_WIDTH-1:0] store_byte_data;
logic [DATA_WIDTH-1:0] store_halfword_data;

// Merge source byte-data to storage data
Mux4 #(.DATA_WIDTH(DATA_WIDTH)) store_byte_mux
(
    .select_i(byte_selector),
    .data0_i({storage_data_out[31:8],  wd_i[7:0]}),
    .data1_i({storage_data_out[31:16], wd_i[7:0], storage_data_out[7:0]}),
    .data2_i({storage_data_out[31:24], wd_i[7:0], storage_data_out[15:0]}),
    .data3_i({wd_i[7:0],               storage_data_out[23:0]}),
    .data_o(store_byte_data)
);

// Merge source word-data to storage data
Mux2 #(.DATA_WIDTH(DATA_WIDTH)) store_hw_mux
(
    .select_i(halfword_selector),
    .data0_i({storage_data_out[31:16],  wd_i[15:0]}),
    .data1_i({wd_i[15:0],  storage_data_out[15:0]}),
    .data_o(store_halfword_data)
);

logic [DATA_WIDTH-1:0] storage_data_in;
logic data_sign;

always_comb begin
    data_sign = 0;      // Default positive number
    rd_o = storage_data_out; // Default to "word"s

    // Capture sign bit
    if (signed_op) begin
        data_sign = is_byte_size ? byte_data[7] : halfword_data[15];
    end

    // Assign output from memory
    if (~mrd_i) begin
        if (is_byte_size)
            rd_o = {{24{data_sign}}, byte_data};        // Sign extend
        else if (is_halfword_size)
            rd_o = {{16{data_sign}}, halfword_data};    // Sign extend
    end

    // Assign input to memory
    if (is_byte_size)
        storage_data_in = store_byte_data;
    else if (is_halfword_size)
        storage_data_in = store_halfword_data;
    else
        storage_data_in = wd_i;     // Passthrough for "word"
end

// ~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**
// Memory (BRAM, SRAM, etc.)
// Memory is organized as [N-addresses x 32-bits].
// ~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**~~**
Memory #(.WORDS(WORDS)) bram(
    .clk_i(clk_i),
    .data_i(storage_data_in),
    .addr_i(word_addr[9:0]),
    .wr_i(mwr_i),
    .rd_i(mrd_i),
    .data_o(storage_data_out)
);

assign mem_rdy_o = 1'b1;        // BRAM is always ready

endmodule

