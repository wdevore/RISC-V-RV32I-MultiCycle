package assemblers

import (
	"fmt"

	"github.com/wdevore/gen-instr/utils"
)

// Example: ebreak
func Ebreak() (macCode string, err error) {
	instruction := make([]byte, 32)

	// The LSB is at [31] (i.e. reversed)
	//  0                                                             31   memory order
	// [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
	//  31                                                            0    logical order
	//  MSB                                                           LSB

	// Immediate
	instruction[31] = 0
	instruction[30] = 0
	instruction[29] = 0
	instruction[28] = 0
	instruction[27] = 0
	instruction[26] = 0
	instruction[25] = 0
	instruction[24] = 0
	instruction[23] = 0
	instruction[22] = 0
	instruction[21] = 0
	instruction[20] = 1
	instruction[19] = 0
	instruction[18] = 0
	instruction[17] = 0
	instruction[16] = 0
	instruction[15] = 0
	instruction[14] = 0
	instruction[13] = 0
	instruction[12] = 0
	instruction[11] = 0
	instruction[10] = 0
	instruction[9] = 0
	instruction[8] = 0
	instruction[7] = 0
	//            6     0
	// Set Opcode 1110011
	instruction[6] = 1
	instruction[5] = 1
	instruction[4] = 1
	instruction[3] = 0
	instruction[2] = 0
	instruction[1] = 1
	instruction[0] = 1

	instr := utils.BinaryArrayToString(instruction, true)

	fmt.Println("------ funct12 ----   rs1 -- funct3 ---- rd  --- opcode")
	fmt.Printf("   %v      %v    %v      %v    %v\n", instr[0:12], instr[12:17], instr[17:20], instr[20:25], instr[25:32])
	// fmt.Println("Instruction Bin: ", instr)
	fmt.Printf("Nibbles: %v %v %v %v %v %v %v %v\n", instr[0:4], instr[4:8], instr[8:12], instr[12:16], instr[16:20], instr[20:24], instr[24:28], instr[28:32])

	return utils.BinaryStringToHexString(instr, false), nil
}
