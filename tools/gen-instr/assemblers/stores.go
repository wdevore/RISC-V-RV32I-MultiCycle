package assemblers

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/wdevore/gen-instr/utils"
)

// s(b,h,w) <src1>, <offset>(<base register>)  => sb <rs2>, <offset>(<rs1>)
// Example: sb x14, 0x010(x0)
// Store contents of x14 to x0+0x10

func Stores(json map[string]interface{}) (macCode string, err error) {
	ass := fmt.Sprintf("%s", json["Assembly"])

	rxpr, _ := regexp.Compile(`([a-z]+)[ ]+(x[0-9]+),[ ]*([\w]+)[ ]*\((x[0-9]+)\)`)

	fields := rxpr.FindStringSubmatch(ass)
	rs2 := fields[2] // src
	fmt.Println("Source register rs2: ", rs2)

	imm := fields[3]
	immAsWA := strings.Contains(imm, "WA:")

	rs1 := fields[4] // base reg
	fmt.Println("Base register rs1: ", rs1)

	immInt, err := utils.StringHexToInt(imm)
	if err != nil {
		return "", err
	}
	if immAsWA {
		// Convert from word-addressing to byte-addressing
		immInt *= 4
	}
	fmt.Printf("Immediate: 0x%x\n", immInt)

	ti := utils.IntToBinaryString(immInt)
	produced := utils.BinaryStringToArray(ti)

	instruction := make([]byte, 32)

	// The LSB is at [31] (i.e. reversed)
	//  0                                                             31   memory order
	// [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
	//  31                                                            0    logical order
	//  MSB                                                           LSB
	// Immediate 11:5
	instruction[31] = produced[20]
	instruction[30] = produced[21]
	instruction[29] = produced[22]
	instruction[28] = produced[23]
	instruction[27] = produced[24]
	instruction[26] = produced[25]
	instruction[25] = produced[26]

	// Rs2
	rs2Int, err := utils.StringRegToInt(rs2)
	if err != nil {
		return "", err
	}

	rs2Arr := utils.IntToBinaryArray(rs2Int)
	instruction[24] = rs2Arr[27]
	instruction[23] = rs2Arr[28]
	instruction[22] = rs2Arr[29]
	instruction[21] = rs2Arr[30]
	instruction[20] = rs2Arr[31]

	// Rs1
	rs1Int, err := utils.StringRegToInt(rs1)
	if err != nil {
		return "", err
	}

	rs1Arr := utils.IntToBinaryArray(rs1Int)
	instruction[19] = rs1Arr[27]
	instruction[18] = rs1Arr[28]
	instruction[17] = rs1Arr[29]
	instruction[16] = rs1Arr[30]
	instruction[15] = rs1Arr[31]

	funct3 := fields[1]
	switch funct3 {
	case "sb":
		instruction[14] = 0
		instruction[13] = 0
		instruction[12] = 0
	case "sh":
		instruction[14] = 0
		instruction[13] = 0
		instruction[12] = 1
	case "sw":
		instruction[14] = 0
		instruction[13] = 1
		instruction[12] = 0
	}

	// Immediate 4:0
	instruction[11] = produced[27]
	instruction[10] = produced[28]
	instruction[9] = produced[29]
	instruction[8] = produced[30]
	instruction[7] = produced[31]

	//            6     0
	// Set Opcode 0100011
	instruction[6] = 0
	instruction[5] = 1
	instruction[4] = 0
	instruction[3] = 0
	instruction[2] = 0
	instruction[1] = 1
	instruction[0] = 1

	instr := utils.BinaryArrayToString(instruction, true)

	fmt.Println("    imm11:5   |  rs2 |  rs1 |  funct3 |  imm4:0 |  opcode")
	fmt.Printf("   %v      %v  %v   %v        %v   %v\n", instr[0:7], instr[7:12], instr[12:17], instr[17:20], instr[20:25], instr[25:32])
	// fmt.Println("Instruction Bin: ", instr)
	fmt.Printf("Nibbles: %v %v %v %v %v %v %v %v\n", instr[0:4], instr[4:8], instr[8:12], instr[12:16], instr[16:20], instr[20:24], instr[24:28], instr[28:32])

	return utils.BinaryStringToHexString(instr), nil
}
