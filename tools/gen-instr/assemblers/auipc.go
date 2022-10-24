package assemblers

import (
	"fmt"
	"regexp"

	"github.com/wdevore/gen-instr/utils"
)

// Example: auipc x10, 0
func Auipc(json map[string]interface{}) (macCode string, err error) {
	fmt.Println("### auipc ###")
	ass := fmt.Sprintf("%s", json["Assembly"])

	rxpr, _ := regexp.Compile(`([a-z]+) ([xa0-9]+),[ ]*([\w]+)`)

	fields := rxpr.FindStringSubmatch(ass)
	rd := fields[2]
	// fmt.Println("Destination register: ", rd)

	imm := fields[3]
	// fmt.Println("Immediate: ", imm)

	immInt, err := utils.StringHexToInt(imm)
	if err != nil {
		return "", err
	}

	ti := utils.IntToBinaryString(immInt)
	produced := utils.BinaryStringToArray(ti)

	instruction := make([]byte, 32)

	// The LSB is at [31] (i.e. reversed)
	//  0                                                             31   memory order
	// [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
	//  31                                                            0    logical order
	//  MSB                                                           LSB

	// Immediate
	instruction[31] = produced[12]
	instruction[30] = produced[13]
	instruction[29] = produced[14]
	instruction[28] = produced[15]
	instruction[27] = produced[16]
	instruction[26] = produced[17]
	instruction[25] = produced[18]
	instruction[24] = produced[19]
	instruction[23] = produced[20]
	instruction[22] = produced[21]
	instruction[21] = produced[22]
	instruction[20] = produced[23]
	instruction[19] = produced[24]
	instruction[18] = produced[25]
	instruction[17] = produced[26]
	instruction[16] = produced[27]
	instruction[15] = produced[28]
	instruction[14] = produced[29]
	instruction[13] = produced[30]
	instruction[12] = produced[31]

	// Set destination register
	rdInt, err := utils.StringRegToInt(rd)
	if err != nil {
		return "", err
	}

	rdArr := utils.IntToBinaryArray(rdInt)
	instruction[11] = rdArr[27]
	instruction[10] = rdArr[28]
	instruction[9] = rdArr[29]
	instruction[8] = rdArr[30]
	instruction[7] = rdArr[31]

	//            6     0
	// Set Opcode 0010111
	instruction[6] = 0
	instruction[5] = 0
	instruction[4] = 1
	instruction[3] = 0
	instruction[2] = 1
	instruction[1] = 1
	instruction[0] = 1

	instr := utils.BinaryArrayToString(instruction, true)

	// fmt.Println("------ imm ----------------------    rd   --- opcode")
	// fmt.Printf("    %v           %v      %v\n", instr[0:20], instr[20:25], instr[25:32])
	// fmt.Println("Instruction Bin: ", instr)
	// fmt.Printf("Nibbles: %v %v %v %v %v %v %v %v\n", instr[0:4], instr[4:8], instr[8:12], instr[12:16], instr[16:20], instr[20:24], instr[24:28], instr[28:32])

	return utils.BinaryStringToHexString(instr, false), nil
}
