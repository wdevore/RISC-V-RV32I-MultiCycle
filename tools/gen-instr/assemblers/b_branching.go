package assemblers

import (
	"fmt"
	"regexp"

	"github.com/wdevore/gen-instr/utils"
)

func GetBranchExpr() *regexp.Regexp {
	rxpr, _ := regexp.Compile(`([a-z]+)[ ]+([xa0-9]+),[ ]*([xa0-9]+),[ ]*@([\w]+)`)
	return rxpr
}

func GetBranchFields(ass string) []string {
	rxpr := GetBranchExpr()

	return rxpr.FindStringSubmatch(ass)
}

//          beq rs1, rs2, imm
// Example: beq  x1,  x2, @offset
func BtypeBranch(json map[string]interface{}) (macCode string, err error) {
	ass := fmt.Sprintf("%s", json["Assembly"])

	fields := GetBranchFields(ass)

	instru := fields[1]

	rs1 := fields[2]
	fmt.Println("Rs1 register: ", rs1)

	rs2 := fields[3]
	fmt.Println("Rs2 register: ", rs2)

	label := fields[4]
	fmt.Println("Offset label: ", label)

	pc := fmt.Sprintf("%s", json["PC"])
	fmt.Println("PC: ", pc)

	pcInt, err := utils.StringHexToInt(pc)
	if err != nil {
		return "", err
	}

	labels := json["Labels"]

	target, err := utils.FindLabelValue(labels, label)
	if err != nil {
		return "", err
	}
	fmt.Println("Target offset: ", target)

	targetInt, err := utils.StringHexToInt(target)
	if err != nil {
		return "", err
	}

	delta := targetInt - pcInt

	bs := utils.IntToBinaryString(delta)
	binArr := utils.BinaryStringToArray(bs)

	deltaStr := ""
	deltaStr = utils.IntToBinaryString(delta)

	out := fmt.Sprintf("Delta d(%d) : %s : b%s", delta, utils.BinaryArrayToHexString(binArr, true), deltaStr)
	fmt.Println(out)

	produced := utils.BinaryStringToArray(deltaStr)

	instruction := make([]byte, 32)

	// The LSB is at [31] (i.e. reversed)
	//  0                                                             31   memory order
	// [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
	//  31                                                            0    logical order
	//  MSB                                                           LSB

	// Immediate 12|10:5
	instruction[31] = produced[12]

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

	// func3
	switch instru {
	case "beq":
		instruction[14] = 0
		instruction[13] = 0
		instruction[12] = 0
	case "bne":
		instruction[14] = 0
		instruction[13] = 0
		instruction[12] = 1
	case "blt":
		instruction[14] = 1
		instruction[13] = 0
		instruction[12] = 0
	case "bge":
		instruction[14] = 1
		instruction[13] = 0
		instruction[12] = 1
	case "bltu":
		instruction[14] = 1
		instruction[13] = 1
		instruction[12] = 0
	case "bgeu":
		instruction[14] = 1
		instruction[13] = 1
		instruction[12] = 1
	}

	// Immediate 4:1|11
	instruction[11] = produced[27]
	instruction[10] = produced[28]
	instruction[9] = produced[29]
	instruction[8] = produced[30]
	instruction[7] = produced[20]

	//            6     0
	// Set Opcode 1100011
	instruction[6] = 1
	instruction[5] = 1
	instruction[4] = 0
	instruction[3] = 0
	instruction[2] = 0
	instruction[1] = 1
	instruction[0] = 1

	instr := utils.BinaryArrayToString(instruction, true)

	fmt.Println("  imm 12|10:5 | rs2  |  rs1  | funct3 | imm 4:1|11 | opcode")
	fmt.Printf("   %v     %v    %v   %v       %v      %v\n", instr[0:7], instr[7:12], instr[12:17], instr[17:20], instr[20:25], instr[25:32])
	// fmt.Println("Instruction Bin: ", instr)
	fmt.Printf("Nibbles: %v %v %v %v %v %v %v %v\n", instr[0:4], instr[4:8], instr[8:12], instr[12:16], instr[16:20], instr[20:24], instr[24:28], instr[28:32])

	return utils.BinaryStringToHexString(instr, false), nil
}
