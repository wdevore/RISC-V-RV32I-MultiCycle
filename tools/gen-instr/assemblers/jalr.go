package assemblers

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/wdevore/gen-instr/utils"
)

func GetJalrExpr() *regexp.Regexp {
	rxpr, _ := regexp.Compile(`([a-z]+)[ ]+([xa0-9]+),[ ]*([\w]+)[ ]*\(([xa0-9]+)\)`)
	return rxpr
}

func GetJalrFields(ass string) []string {
	rxpr := GetJalrExpr()

	return rxpr.FindStringSubmatch(ass)
}

// Example: jalr x0, jumpto(x1)
func Jalr(json map[string]interface{}) (macCode string, err error) {
	fmt.Println("### jalr ###")
	ass := fmt.Sprintf("%s", json["Assembly"])

	fields := GetJalrFields(ass)

	rd := fields[2]
	// fmt.Println("Destination register: ", rd)

	rs1 := fields[4]
	// fmt.Println("Rs1 register: ", rs1)

	label := fields[3]
	// fmt.Println("Offset label: ", label)

	offset := ""
	if strings.Contains(label, "0x") {
		offset = label
	} else {
		labels := json["Labels"]

		offset, err = utils.FindLabelValue(labels, label)
		if err != nil {
			return "", err
		}
	}
	// fmt.Println("Offset: ", offset)

	offsetInt, err := utils.StringHexToInt(offset)
	if err != nil {
		return "", err
	}

	// r, err := utils.GetRegValue(json["RegFile"], rs1)
	// if err != nil {
	// 	return "", err
	// }

	// offset := targetInt - r
	// fmt.Println("Offset: ", offset)

	ti := utils.IntToBinaryString(offsetInt)
	produced := utils.BinaryStringToArray(ti)

	instruction := make([]byte, 32)

	// The LSB is at [31] (i.e. reversed)
	//  0                                                             31   memory order
	// [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
	//  31                                                            0    logical order
	//  MSB                                                           LSB

	// 111111111111 1111 1111 1111 1011 1100
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
	instruction[20] = 0

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

	// funct3
	instruction[14] = 0
	instruction[13] = 0
	instruction[12] = 0

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
	// Set Opcode 1100111
	instruction[6] = 1
	instruction[5] = 1
	instruction[4] = 0
	instruction[3] = 0
	instruction[2] = 1
	instruction[1] = 1
	instruction[0] = 1

	instr := utils.BinaryArrayToString(instruction, true)

	// fmt.Println("------ imm -------- rs1 ----- funct3 ----- rd --- opcode")
	// fmt.Printf("    %v   %v       %v       %v    %v\n", instr[0:12], instr[12:17], instr[17:20], instr[20:25], instr[25:32])
	// fmt.Println("Instruction Bin: ", instr)
	// fmt.Printf("Nibbles: %v %v %v %v %v %v %v %v\n", instr[0:4], instr[4:8], instr[8:12], instr[12:16], instr[16:20], instr[20:24], instr[24:28], instr[28:32])

	return utils.BinaryStringToHexString(instr, false), nil
}
