`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// --------------------------------------------------------------------------
// 1024x32 BRAM memory
// Single or Dual Port
// --------------------------------------------------------------------------
// The path to the data file is relative to the test bench (TB).
// If the TB is run from this directory then the path would be "ROM.dat"
// `define MEM_CONTENTS "ROM.dat"
// Otherwise it is relative to the TB.
`define ROM_PATH "../../../roms/"
`define ROM_EXTENSION ".dat"
// `define MEM_CONTENTS "Nop_Halt"

module Memory
#(
    parameter WORDS = 10,    // 2^WORDS = 1K
    parameter DATA_WIDTH = 32)
(
    input  logic                  clk_i,     // pos-edge
    input  logic [DATA_WIDTH-1:0] data_i,    // Memory data input
    input  logic [WORDS-1:0]      addr_i,    // Memory addr_i
    input  logic                  wr_i,      // Write enable (Active Low)
    output logic [DATA_WIDTH-1:0] data_o     // Memory data output
);

// Memory bank
reg [DATA_WIDTH-1:0] mem [(1<<WORDS)-1:0] /*verilator public*/; // The actual memory

initial begin
    // I can explicitly specify the start/end addr_i in order to avoid the
    // warning: "WARNING: memory.v:23: $readmemh: Standard inconsistency, following 1364-2005."
    //     $readmemh (`MEM_CONTENTS, mem, 'h00, 'h04);
    `ifdef USE_ROM
        // NOTE:
        // `` - The double-backtick(``) is essentially a token delimiter.
        // It helps the compiler clearly differentiate between the Argument and
        // the rest of the string in the macro text.
        // Note: this approach doesn't work yosys very well.
        // See: https://www.systemverilog.io/macros

        // This only works with BRAM. It generally doesn't work with SPRAM constructs.
        $display("Using ROM: %s", ``MEM_CONTENTS);
        $readmemh ({`ROM_PATH, ``MEM_CONTENTS, `ROM_EXTENSION}, mem);  // , 0, 6
    `elsif USE_STATIC
        $display("Using STATIC content");
        mem[0] =   32'h00000002;       // Simple data for testing
        mem[1] =   32'h00000004;
        mem[2] =   32'h00000006;
        mem[3] =   32'h00000008;
        mem[4] =   32'h0000000A;
        mem[5] =   32'h0000000B;
        mem[6] =   32'h0000000C;
        mem[7] =   32'h0000000D;
        mem[8] =   32'h0000000E;
        mem[9] =   32'h0000000F;
        mem[10] =  32'h55443312;
        mem[11] =  32'h00009914;
        mem[12] =  32'h00000016;
        mem[255] = 32'h00000001;
    `endif

    `ifdef SHOW_MEMORY
        // Example of displaying contents
        $display("------- Top MEM contents ------");
        for(integer index = 0; index < 15; index = index + 1)
            $display("memory[%d] = %b <- %h", index[7:0], mem[index], mem[index]);

        // Display the vector data residing at the bottom of memory
        $display("------- Bottom MEM contents ------");
        for(integer index = 250; index < 256; index = index + 1)
            $display("memory[%d] = %b <- %h", index[7:0], mem[index], mem[index]);
    `endif
end

// --------------------------------
// Register blobs
// --------------------------------
// Force Register blocks. Remove data_o <= ... above as well.
// assign data_o = mem[addr_i];

// --------------------------------
// Single Port RAM -- Ultra+ class chips
// --------------------------------
// always_ff @(posedge clk_i) begin
//     if (~wr_i) begin
//         mem[addr_i] <= data_i;
//         `ifdef SIMULATE
//             $display("%d WRITE data at Addr(0x%h), Mem(0x%h), data_i(0x%h)", $stime, addr_i, mem[addr_i], data_i);
//         `endif
//     end
//     data_o <= mem[addr_i];  // <-- remove this to simulate Register blobs
// end

// --------------------------------
// Dual Port RAM --  LP/HX and Ultra+ classes
// --------------------------------
always_ff @(posedge clk_i) begin
    if (~wr_i) begin
        mem[addr_i] <= data_i;
        `ifdef SIMULATE
            $display("%d Mem WRITE data Addr (0x%h), Data(0x%h), data_i(0x%h)", $stime, addr_i, mem[addr_i], data_i);
        `endif
    end
end

always_ff @(posedge clk_i) begin
    data_o <= mem[addr_i];
    `ifdef SIMULATE
        $display("%d Mem READ data Addr (0x%h), Data(0x%h), data_i(0x%h)", $stime, addr_i, mem[addr_i], data_i);
    `endif
end

endmodule

