package assemblers

import (
	"fmt"
	"regexp"

	"github.com/wdevore/gen-instr/utils"
)

//          add rd, rs1, rs2
// Example: add x3, x1, x2
func RtypeAlu(json map[string]interface{}) (macCode string, err error) {
	ass := fmt.Sprintf("%s", json["Assembly"])

	rxpr, _ := regexp.Compile(`([a-z]+)[ ]+(x[0-9]+),[ ]*(x[0-9]+),[ ]*(x[0-9]+)`)

	fields := rxpr.FindStringSubmatch(ass)

	instru := fields[1]

	rd := fields[2]
	fmt.Println("Destination register: ", rd)

	rs1 := fields[3]
	fmt.Println("Rs1 register: ", rs1)

	rs2 := fields[4]
	fmt.Println("Rs2 register: ", rs2)

	instruction := make([]byte, 32)

	// The LSB is at [31] (i.e. reversed)
	//  0                                                             31   memory order
	// [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
	//  31                                                            0    logical order
	//  MSB                                                           LSB

	// funct7
	instruction[31] = 0
	if instru == "sub" || instru == "sra" {
		instruction[30] = 1
	} else {
		instruction[30] = 0
	}
	instruction[29] = 0
	instruction[28] = 0
	instruction[27] = 0
	instruction[26] = 0
	instruction[25] = 0

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

	switch instru {
	case "add":
		instruction[14] = 0
		instruction[13] = 0
		instruction[12] = 0
	case "sub":
		instruction[14] = 0
		instruction[13] = 0
		instruction[12] = 0
	case "xor":
		instruction[14] = 1
		instruction[13] = 0
		instruction[12] = 0
	case "or":
		instruction[14] = 1
		instruction[13] = 1
		instruction[12] = 0
	case "and":
		instruction[14] = 1
		instruction[13] = 1
		instruction[12] = 1
	case "sll":
		instruction[14] = 0
		instruction[13] = 0
		instruction[12] = 1
	case "srl":
		instruction[14] = 1
		instruction[13] = 0
		instruction[12] = 1
	case "sra":
		instruction[14] = 1
		instruction[13] = 0
		instruction[12] = 1
	case "slt":
		instruction[14] = 0
		instruction[13] = 1
		instruction[12] = 0
	case "sltu":
		instruction[14] = 0
		instruction[13] = 1
		instruction[12] = 1
	}

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
	// Set Opcode 0110011
	instruction[6] = 0
	instruction[5] = 1
	instruction[4] = 1
	instruction[3] = 0
	instruction[2] = 0
	instruction[1] = 1
	instruction[0] = 1

	instr := utils.BinaryArrayToString(instruction, true)

	fmt.Println("func7   |  rs2     |  rs1  | funct3 |   rd  |  opcode")
	fmt.Printf("%v   %v      %v    %v     %v    %v\n", instr[0:7], instr[7:12], instr[12:17], instr[17:20], instr[20:25], instr[25:32])
	// fmt.Println("Instruction Bin: ", instr)
	fmt.Printf("Nibbles: %v %v %v %v %v %v %v %v\n", instr[0:4], instr[4:8], instr[8:12], instr[12:16], instr[16:20], instr[20:24], instr[24:28], instr[28:32])

	return utils.BinaryStringToHexString(instr), nil
}
