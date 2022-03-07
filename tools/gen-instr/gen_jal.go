package main

import (
	"errors"
	"fmt"
	"regexp"
)

func jal(json map[string]interface{}, rxpr *regexp.Regexp) (macCode string, err error) {
	ass := fmt.Sprintf("%s", json["Assembly"])

	fields := rxpr.FindStringSubmatch(ass)
	rd := fields[2]
	fmt.Println("Destination register: ", rd)

	label := fields[3]
	fmt.Println("Offset label: ", label)

	pc := fmt.Sprintf("%s", json["PC"])
	fmt.Println("PC: ", pc)

	pcInt, err := stringHexToInt(pc)
	if err != nil {
		return "", err
	}

	labels := json["Labels"]

	target, err := findLabelValue(labels, label)
	if err != nil {
		return "", err
	}
	fmt.Println("Target offset: ", target)

	targetInt, err := stringHexToInt(target)
	if err != nil {
		return "", err
	}

	delta := targetInt - pcInt

	bs := intToBinaryString(delta)
	binArr := binaryStringToArray(bs)

	deltaStr := ""
	deltaStr = intToBinaryString(delta)

	out := fmt.Sprintf("Delta d%d : %s : b%s", delta, binaryArrayToHexString(binArr), deltaStr)
	fmt.Println(out)

	produced := binaryStringToArray(deltaStr)

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
	rdInt, err := stringRegToInt(rd)
	if err != nil {
		return "", err
	}

	rdArr := binaryStringToArray(intToBinaryString(rdInt))
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

	instr := binaryArrayToString(instruction, true)
	fmt.Println("Instruction Bin: ", instr)

	return binaryStringToHexString(instr), nil
}

func findLabelValue(labels interface{}, label string) (value string, err error) {
	for _, v := range labels.([]interface{}) {
		m, ok := v.(map[string]interface{})
		if ok {
			if val, ok := m[label]; ok {
				return fmt.Sprintf("%s", val), nil
			}
		}
	}

	return "", errors.New("Label '" + label + "' not found")
}
