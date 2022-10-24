package assemblers

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/wdevore/gen-instr/utils"
)

func GetLoadsExpr() *regexp.Regexp {
	rxpr, _ := regexp.Compile(`([a-z]+)[ ]+([xa0-9]+),[ ]*([@+\w]+)[ ]*\(([xa0-9]+)\)`)
	return rxpr
}

func GetLoadsFields(ass string) []string {
	rxpr := GetLoadsExpr()

	return rxpr.FindStringSubmatch(ass)
}

// Example: lw x19, 0x0A(x0)
func Loads(json map[string]interface{}) (macCode string, err error) {

	ass := fmt.Sprintf("%s", json["Assembly"])

	fields := GetLoadsFields(ass)

	rd := fields[2]
	// fmt.Println("Destination register: ", rd)

	imm := fields[3]
	immAsWA := strings.Contains(imm, "WA:")

	// Can be either, examples: 0x0(x0) or @Ref+1(x0)
	rs1 := fields[4]
	// fmt.Println("Rs1 register: ", rs1)

	immInt, err := utils.StringHexToInt(imm)
	if err != nil {
		return "", err
	}
	if immAsWA {
		// Convert from word-addressing to byte-addressing
		immInt *= 4
	}
	// fmt.Printf("Immediate: 0x%x\n", immInt)

	ti := utils.IntToBinaryString(immInt)
	produced := utils.BinaryStringToArray(ti)

	instruction := make([]byte, 32)

	// The LSB is at [31] (i.e. reversed)
	//  0                                                             31   memory order
	// [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
	//  31                                                            0    logical order
	//  MSB                                                           LSB
	// Immediate
	instruction[31] = produced[20]
	instruction[30] = produced[21]
	instruction[29] = produced[22]
	instruction[28] = produced[23]
	instruction[27] = produced[24]
	instruction[26] = produced[25]
	instruction[25] = produced[26]
	instruction[24] = produced[27]
	instruction[23] = produced[28]
	instruction[22] = produced[29]
	instruction[21] = produced[30]
	instruction[20] = produced[31]

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
	fmt.Println("### Load: ", funct3, " ###")

	switch funct3 {
	case "lb":
		instruction[14] = 0
		instruction[13] = 0
		instruction[12] = 0
	case "lh":
		instruction[14] = 0
		instruction[13] = 0
		instruction[12] = 1
	case "lw":
		instruction[14] = 0
		instruction[13] = 1
		instruction[12] = 0
	case "lbu":
		instruction[14] = 1
		instruction[13] = 0
		instruction[12] = 0
	case "lhu":
		instruction[14] = 1
		instruction[13] = 0
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
	// Set Opcode 0000011
	instruction[6] = 0
	instruction[5] = 0
	instruction[4] = 0
	instruction[3] = 0
	instruction[2] = 0
	instruction[1] = 1
	instruction[0] = 1

	instr := utils.BinaryArrayToString(instruction, true)

	// fmt.Println("   imm11:0       |  rs1 | funct3 | rd  |  opcode")
	// fmt.Printf("%v      %v    %v    %v   %v\n", instr[0:12], instr[12:17], instr[17:20], instr[20:25], instr[25:32])
	// fmt.Println("Instruction Bin: ", instr)
	// fmt.Printf("Nibbles: %v %v %v %v %v %v %v %v\n", instr[0:4], instr[4:8], instr[8:12], instr[12:16], instr[16:20], instr[20:24], instr[24:28], instr[28:32])

	return utils.BinaryStringToHexString(instr, false), nil
}
