`default_nettype none

// --------------------------------------------------------------------------
// Test bench
// --------------------------------------------------------------------------
`timescale 1ns/1ps

`define VCD_OUTPUT "/media/RAMDisk/waveform.vcd"

module Register_tb (
   input wire logic Clock_TB
);
   localparam Data_WIDTH = 32;                 // data width
   
   // Test bench Signals
   // Output from register
   wire logic [Data_WIDTH-1:0] DOut_TB;

   // Inputs to register
   logic LD_TB;
   logic [Data_WIDTH-1:0] DIn_TB;

   // logic Clock_TB;

   // -------------------------------------------
   // Device under test
   // -------------------------------------------
   Register #(.DATA_WIDTH(Data_WIDTH)) dut
   (
      .clk_i(Clock_TB),
      .ld_ni(LD_TB),
      .data_i(DIn_TB),
      .data_o(DOut_TB)
   );

   // The clock runs until the sim finishes. #100 = 200ns clock cycle
   // always_comb begin
   //    /* verilator lint_off ALWCOMBORDER */
   //    Clock_TB = ~Clock_TB;
   // end

   // -------------------------------------------
   // Configure starting sim states
   // -------------------------------------------
   initial begin
      $dumpfile(`VCD_OUTPUT);
      $dumpvars;  // Save waveforms to vcd file
      
      $display("%d %m: Starting testbench simulation...", $stime);

      DIn_TB = {Data_WIDTH{1'b0}};  // DIn = 0
      LD_TB = 1'b1;     // Disable load

      // Clock_TB = 1'b0;
   end

   always_comb begin
      // ------------------------------------
      // Load
      // ------------------------------------
      DIn_TB = 32'h000000A0;  // Set Address to 0x00A0
      LD_TB = 1'b0;     // Enable load

      // Clock_TB = 1'b1;

      // Assert that the register was loaded with 0x00A0
      if (DOut_TB !== 32'h000000A0) begin
         $display("%d %m: ERROR - Register output incorrect (%h).", $stime, DOut_TB);
         $finish;
      end

      // Clock_TB = 1'b0;
      // Clock_TB = 1'b1;
   end

   always_comb begin
      // ------------------------------------
      // Simulation duration
      // ------------------------------------
      $display("%d %m: Testbench simulation FINISHED.", $stime);
      $finish;
   end
endmodule
