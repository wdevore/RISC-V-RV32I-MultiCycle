package assemblers

import (
	"fmt"
	"regexp"

	"github.com/wdevore/gen-instr/utils"
)

func GetJalExpr() *regexp.Regexp {
	rxpr, _ := regexp.Compile(`([a-z]+)[ ]+([xa0-9]+),[ ]*@([\w]+)`)
	return rxpr
}

func GetJalFields(ass string) []string {
	rxpr := GetJalExpr()

	return rxpr.FindStringSubmatch(ass)
}

func Jal(json map[string]interface{}) (macCode string, err error) {
	fmt.Println("### jal ###")
	ass := fmt.Sprintf("%s", json["Assembly"])

	fields := GetJalFields(ass)

	rd := fields[2]
	// fmt.Println("Destination register: ", rd)

	label := fields[3]
	// fmt.Println("Offset label: ", label)

	pc := fmt.Sprintf("%s", json["PC"])
	// fmt.Println("PC: ", pc)

	pcInt, err := utils.StringHexToInt(pc)
	if err != nil {
		return "", err
	}

	labels := json["Labels"]

	target, err := utils.FindLabelValue(labels, label)
	if err != nil {
		return "", err
	}
	// fmt.Println("Target offset: ", target)

	targetInt, err := utils.StringHexToInt(target)
	if err != nil {
		return "", err
	}

	delta := targetInt - pcInt

	// bs := utils.IntToBinaryString(delta)
	// binArr := utils.BinaryStringToArray(bs)

	deltaStr := ""
	deltaStr = utils.IntToBinaryString(delta)

	// out := fmt.Sprintf("Delta d(%d) : %s : b%s", delta, utils.BinaryArrayToHexString(binArr, true), deltaStr)
	// fmt.Println(out)

	produced := utils.BinaryStringToArray(deltaStr)

	instruction := make([]byte, len(produced))

	// Swizzle produced value into instruction-immediate
	// The LSB is at [31] (i.e. reversed)
	//  0                                                             31   memory order
	// [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 1 0 0]
	//  31                                                            0    logical order
	//  MSB                                                           LSB
	instruction[31] = produced[11]

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

	instruction[20] = produced[20]

	instruction[19] = produced[12]
	instruction[18] = produced[13]
	instruction[17] = produced[14]
	instruction[16] = produced[15]
	instruction[15] = produced[16]
	instruction[14] = produced[17]
	instruction[13] = produced[18]
	instruction[12] = produced[19]

	// Set destination register
	rdInt, err := utils.StringRegToInt(rd)
	if err != nil {
		return "", err
	}

	rdArr := utils.BinaryStringToArray(utils.IntToBinaryString(rdInt))
	instruction[11] = rdArr[27]
	instruction[10] = rdArr[28]
	instruction[9] = rdArr[29]
	instruction[8] = rdArr[30]
	instruction[7] = rdArr[31]

	// Set Opcode 1101111
	instruction[6] = 1
	instruction[5] = 1
	instruction[4] = 0
	instruction[3] = 1
	instruction[2] = 1
	instruction[1] = 1
	instruction[0] = 1

	instr := utils.BinaryArrayToString(instruction, true)
	// fmt.Println("Instruction Bin: ", instr)

	// fmt.Println("i20 ----- i10:1 ---- i11 ---i19:12 ------- rd --- opcode")
	// fmt.Printf(" %v     %v     %v     %v     %v   %v\n", instr[0:1], instr[1:11], instr[11:12], instr[12:20], instr[20:25], instr[25:32])
	// fmt.Println("Instruction Bin: ", instr)
	// fmt.Printf("Nibbles: %v %v %v %v %v %v %v %v\n", instr[0:4], instr[4:8], instr[8:12], instr[12:16], instr[16:20], instr[20:24], instr[24:28], instr[28:32])

	return utils.BinaryStringToHexString(instr, false), nil
}
