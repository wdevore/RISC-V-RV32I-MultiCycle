`default_nettype none

// Synthesis container for the RangerRisc softcore

// This module is the "interface" to the BlackiceNxt.

module basic
(
    input logic clk,            // 25MHz clock input
    output logic led_o          // Active clock indicator
);

localparam DataWidth = 32;     // RV32I

logic led;


assign led_o = led;

endmodule