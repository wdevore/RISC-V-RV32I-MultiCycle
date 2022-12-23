`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// --------------------------------------------------------------------------
// Nx32 BRAM memory
// --------------------------------------------------------------------------
// The path to the data file is relative to the test bench (TB).
// If the TB is run from this directory then the path would be "ROM.dat"
// `define MEM_CONTENTS "ROM.dat"
// Otherwise it is relative to the TB.

// Use this define starting the ranger_console. It's just a dummy
// because you can simply "ld" what ever code you need via the simulation.
// `define MEM_CONTENTS "itype_csrs/intr1"

// Use this define to preload a specific ram during synthesis.

// OR
// `define ROM_PATH "/media/RAMDisk/"
// `define MEM_CONTENTS "code"

module Memory
#(
    parameter WORDS = `MEM_WORDS,    // 2^WORDS
    parameter DATA_WIDTH = 32)
(
    input  logic                  clk_i,     // pos-edge
    input  logic [DATA_WIDTH-1:0] data_i,    // Memory data input
    input  logic [WORDS-1:0]      addr_i,    // Memory addr_i
    input  logic                  wr_i,      // Write enable (Active Low)
    input  logic                  rd_i,      // Read enable (Active Low)
    output logic [DATA_WIDTH-1:0] data_o     // Memory data output
);

/*verilator public_module*/

// Memory bank
//     #  of bits               # cells
logic [DATA_WIDTH-1:0] mem [(1<<WORDS)-1:0] /*verilator public*/;

initial begin
    // I can explicitly specify the start/end addr_i in order to avoid the
    // warning: "WARNING: memory.v:23: $readmemh: Standard inconsistency, following 1364-2005."
    //     $readmemh (`MEM_CONTENTS, mem, 'h00, 'h04);
    `ifdef USE_ROM
        // This only works with BRAM. It generally doesn't work with SPRAM constructs.
        // $display("Using ROM: %s", `MEM_CONTENTS);
        $readmemh ({`ROM_PATH, `MEM_CONTENTS, `ROM_EXTENSION}, mem);  // , 0, 6
    `elsif USE_STATIC
        $display("Using STATIC content");
        mem[0] =    32'h00000002;       // Simple data for testing
        mem[1] =    32'h00000004;
        mem[2] =    32'h00000006;
        mem[3] =    32'h00000008;
        mem[4] =    32'h0000000A;
        mem[5] =    32'h1111000B;
        mem[6] =    32'h0000000C;
        mem[7] =    32'h0000000D;
        mem[8] =    32'h1111110E;
        mem[9] =    32'h0000000F;
        mem[10] =   32'h55AA3312;   // 0x0000000A
        mem[11] =   32'h00009914;   // 0x0000000B
        mem[12] =   32'h00000016;   // 0x0000000C
        mem[13] =   32'h00006626;   // 0x0000000D
        mem[14] =   32'hBBAA1136;   // 0x0000000E
        mem[15] =   32'h00003246;   // 0x0000000F
        mem[16] =   32'h21113456;   // 0x00000010
        mem[17] =   32'h00000090;   // 0x00000011
        mem[18] =   32'hD0B0A090;   // 0x00000012
        mem[19] =   32'h1AB0A090;   // 0x00000013
        mem[20] =   32'h04002983;   // 0x00000014 = byte-addr 0x50 = "lw x19, x0,  d16"
        mem[21] =   32'h04480983;   // 0x00000015 =           0x54 = "lb x19, x16, 0x...011"
        mem[22] =   32'h00E100A3;   // 0x00000016 =           0x58
        mem[1023] = 32'h00000050;   // 0x000003FF = 0x14*d4 = 0x50
    `endif

    `ifdef SHOW_MEMORY
        // Example of displaying contents
        $display("------- Top MEM contents ------");
        for(integer index = 0; index < 32; index = index + 1)
            $display("memory[%d] = %b <- %h", index[7:0], mem[index], mem[index]);

        // $display("------- Top MEM contents ------");
        // for(integer index = 0; index < 32; index = index + 4) begin
        //     $display("memory[%d] = %b <- %h", index[7:0], mem[index], mem[index]);
        // end

        // Display the vector data residing at the bottom of memory
        $display("------- Bottom MEM contents ------");
        for(integer index = 1020; index < 1024; index = index + 1)
            $display("memory[%d] = %b <- %h", index[7:0], mem[index], mem[index]);
    `endif
end

// --------------------------------
// Dual Port RAM --  LP/HX and Ultra+ classes
// --------------------------------
always_ff @(negedge clk_i) begin
    if (~wr_i) begin
        mem[addr_i] <= data_i;
    end
end

always_ff @(negedge clk_i) begin
    if (~rd_i) begin
        data_o <= mem[addr_i];
    end
end

endmodule

