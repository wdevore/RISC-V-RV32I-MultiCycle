`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// **__**__**__**__**__**__**__**__**__**__**__**__**__**__**__
// This module is not used. It was an early design that
// didn't pan out.
// **__**__**__**__**__**__**__**__**__**__**__**__**__**__**__

// The CSR module is a sparsely populated bank of registers
// The spec says there can be up to 4096, however, RangerRisc
// implements a very minimal M-mode.
//
// Instructions:
// CSRRW  - Read and write a CSR
// CSRRS  - Read and set selected bits to 1
// CSRRC  - Read and clear selected bits to 0
// CSRRWI - Read and write a CSR (from immediate value)
// CSRRSI - Read and set selected bits to 1 (using immediate mask)
// CSRRCI - Read and clear selected bits to 0 (using immediate mask)

// Because we are implementing only interrupts AND nothing else
// all the registers can be 32bits.
// Had we considered cycles or counters then a mixture of 32/64 bits
// would be required.
// Keep in mind that some of the registers "could" actually be
// hardware with different types of read/write side-effects.
// For example, below, the Mip register has a bit connected to hardware.

// Section 3.1.14
// When a trap is taken into M-mode, mepc is written with the virtual address of the instruction
// that was interrupted or that encountered the exception. Otherwise, mepc is never written by the
// implementation, though it may be explicitly written by software.

// An interrupt will be taken (i.e., the trap handler will be invoked) if
// and only if:
//  1) the corresponding bit Mie is set
//  2) and Mip register bit is set
//  3) and if interrupts are globally enabled (mstatus.mie)

module CSRs
#(
    parameter DATA_WIDTH = 32
)
(
    input  logic clk_i,
    /*verilator lint_off UNUSED*/
    input  logic [DATA_WIDTH-1:0] ir_i, 
    input  logic [`CSRAddrSize-1:0] csr_addr_i, 
    /*verilator lint_on UNUSED*/
    input  logic wr_i, // Write = Active Low
    input  logic rd_i, // Read = Active Low
    input  logic [DATA_WIDTH-1:0] data_i,   // RsA = rs1
    input  logic irq_i, // falling edge
    output logic [DATA_WIDTH-1:0] csrs_o [0:`CSRCnt-1] /*verilator public*/,
    output logic [DATA_WIDTH-1:0] data_o /*verilator public*/
);

/*verilator public_module*/

localparam IMM_SIZE = 5;

// Standard flip-flop style registers
logic [DATA_WIDTH-1:0] csrs [0:`CSRCnt-1] /*verilator public*/;

logic [2:0] funct3 = ir_i[14:12];
logic immSet = funct3[2];
logic [4:0] rs1 = ir_i[19:15];

// Previous value of CSR
logic [DATA_WIDTH-1:0] pr_csr = {DATA_WIDTH{1'b0}};
logic [DATA_WIDTH-1:0] data;

logic [3:0] regIdx = 0;

initial begin
    `ifdef POPULATE_CSR_REGISTERS
        $display("------Populating CSRs ----");
        csrs[0] = 32'h0000_0000;  // Mstatus
        csrs[1] = 32'h0000_0000;  // Mie
        csrs[2] = 32'h0000_0000;  // Mtvec
        csrs[3] = 32'h0000_0000;  // Mscratch
        csrs[4] = 32'h0000_0000;  // Mepc
        csrs[5] = 32'h0000_0000;  // Mcause
        csrs[6] = 32'h0000_0000;  // Mtval
        csrs[7] = 32'h0000_0000;  // Mip
    `endif
end

always_comb begin
    case (csr_addr_i)
        Mstatus: regIdx  = `CSR_Mstatus;
        Mie: regIdx      = `CSR_Mie;
        Mtvec: regIdx    = `CSR_Mtvec;      // Mode = Direct
        Mscratch: regIdx = `CSR_Mscratch;
        Mepc: regIdx     = `CSR_Mepc;       // MRET return address
        Mcause: regIdx   = `CSR_Mcause;
        Mtval: regIdx    = `CSR_Mtval;
        Mip: regIdx      = `CSR_Mip;
        default: regIdx  = 8;    // Blank/Void
    endcase

    if (immSet)
        data = {{DATA_WIDTH-IMM_SIZE{1'b0}}, rs1}; // Zero extend
    else
        data = data_i;

    case (funct3)
        CSRRC, CSRRCI: begin
            data = ~data & pr_csr;
        end
        CSRRS, CSRRSI: begin
            data = data | pr_csr;
        end
        default:
            data = data;
    endcase
end

always_ff @(negedge clk_i, negedge irq_i) begin
    if (regIdx < 8) begin
        if (~wr_i) begin
            csrs[regIdx] <= data;
        end
        else if (~rd_i) begin
            pr_csr <= csrs[regIdx];
        end
    end

    // Mip is a "hardware" based register. It has a bit (MEIP)
    // directly connected to hardware IRQ IO.
    // This also bypasses any write side-effects.
    //                          |``````MEIP
    //                          v
    // 0000_0000_0000_0000_0000_1000_0000_0000
    if (~irq_i) begin
        // Set pending bit in Mip register
        // Note: You can clear the bit using CSRRC with 0x000000800
        csrs[`CSR_Mip][`CSR_Mip_MEIE] <= 1'b1;

        // Indicate what the cause is: Machine external interrupt
        csrs[`CSR_Mcause][`CSR_Mcause_MEI] <= 1'b1;

        // Copy Mie bit to previous register bit mstatus.MPIE
        // csrs[0] <= csrs[0] | {{20{1'b0}}, 1'b1, {11{1'b0}}};
    end
end

assign data_o = pr_csr; // A single register
assign csrs_o = csrs;   // All the registers

endmodule
