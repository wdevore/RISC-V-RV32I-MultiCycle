`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

module DeMux4
#(
    parameter DATA_WIDTH = 32
)
(
   input  logic [1:0] select,
   input  logic [DATA_WIDTH-1:0]  data_i,
   output logic [DATA_WIDTH-1:0]  data0_o,
   output logic [DATA_WIDTH-1:0]  data1_o,
   output logic [DATA_WIDTH-1:0]  data2_o,
   output logic [DATA_WIDTH-1:0]  data3_o
);

always_comb begin
    case (select)
        2'b00: begin
            data0_o = data_i;
            data1_o = 0;
            data2_o = 0;
            data3_o = 0;
        end
        2'b01: begin
            data0_o = 0;
            data1_o = data_i;
            data2_o = 0;
            data3_o = 0;
        end
        2'b10: begin
            data0_o = 0;
            data1_o = 0;
            data2_o = data_i;
            data3_o = 0;
        end
        2'b11: begin
            data0_o = 0;
            data1_o = 0;
            data2_o = 0;
            data3_o = data_i;
        end
    endcase
end

endmodule

