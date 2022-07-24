`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

module Top (
    // Signals from Cpp testbench
    input  logic sysClk_i,
    input  logic async_i,
    output logic sync_o,
    output logic rising_o,
    output logic falling_o
);


CDCSynchronizer dut (
    .sysClk_i(sysClk_i),
    .async_i(async_i),
    .sync_o(sync_o),
    .rising_o(rising_o),
    .falling_o(falling_o)
);


endmodule

