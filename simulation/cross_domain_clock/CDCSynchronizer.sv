`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// This is a 2-FF + synchronizer design

module CDCSynchronizer
(
    input  logic        sysClk_i,    // Destination clock domain
    input  logic        async_i,     // Signal outside of domain
    output logic        sync_o,      // Synchronized signal
    output logic        rising_o,    // Indicates starting of rising-edge of synced signal
    output logic        falling_o    // Indicates starting of falling-edge of synced signal
);

/*verilator public_module*/

logic [2:0] async_r; // 3 bits

// Shift bits from LSB to MSB
always @(posedge sysClk_i)
   async_r <= { async_r[1:0], async_i };

// Rising/Falling are pulled from Bits 2 and 1
assign rising_o = ( async_r[2:1] == 2'b01 );
assign falling_o = ( async_r[2:1] == 2'b10 );

// Sync is delayed by passing through Bits 1 and 0
assign sync_o = async_r[1];

endmodule

