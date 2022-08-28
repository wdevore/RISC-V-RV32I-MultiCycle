//Verilog module.
module Decoder(
    input logic [3:0] bcd,
    output logic [6:0] seg
);

//         8     9           dp    t-5
//         .  *-----*         .  *-----*
//            |     |            |     |
//         11 |  3  | 6     tl-6 | m-0 | tr-3
//            *-----*            *-----*
//            |     |            |     |
//          7 |     | 4     ll-4 |     | lr-1
//            *-----*            *-----*
//               5                 b-2
//
// 6  5  4  3  2  1  0
// tl t  ll tr b  lr m

always_comb begin
    case (bcd) //case statement
        0  : seg = 7'b0000001;
        1  : seg = 7'b1110101;
        2  : seg = 7'b1000010;
        3  : seg = 7'b1010000;
        4  : seg = 7'b0110100;
        5  : seg = 7'b0011000;
        6  : seg = 7'b0001000;
        7  : seg = 7'b1010101;
        8  : seg = 7'b0000000;
        9  : seg = 7'b0010000;
        10 : seg = 7'b0000100;  // A
        11 : seg = 7'b0101000;  // B
        12 : seg = 7'b1101010;  // C
        13 : seg = 7'b1100000;  // D
        14 : seg = 7'b0001010;  // E
        15 : seg = 7'b0001110;  // F
        //switch off 7 segment character when the bcd digit is not a decimal number.
        default : seg = 7'b1111111; 
    endcase
end
    
endmodule