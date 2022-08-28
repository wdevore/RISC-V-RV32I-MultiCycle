/******************************************************************************
*                                                                             *
* Copyright 2016 myStorm Copyright and related                                *
* rights are licensed under the Solderpad Hardware License, Version 0.51      *
* (the “License”); you may not use this file except in compliance with        *
* the License. You may obtain a copy of the License at                        *
* http://solderpad.org/licenses/SHL-0.51. Unless required by applicable       *
* law or agreed to in writing, software, hardware and materials               *
* distributed under this License is distributed on an “AS IS” BASIS,          *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or             *
* implied. See the License for the specific language governing                *
* permissions and limitations under the License.                              *
*                                                                             *
******************************************************************************/

module blink(
	input  logic clk,
	output logic led,
	output logic [5:0] blade
);

logic [24:0] count;

assign led = count[22];

assign blade[0] = count[23];
assign blade[1] = count[22];
assign blade[2] = count[21];
assign blade[3] = count[20];
assign blade[4] = count[19];
assign blade[5] = count[18];

always_ff @(posedge clk)
	count <= count + 1;

endmodule
