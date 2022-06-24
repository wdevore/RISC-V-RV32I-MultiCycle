package assemblers

import (
	"fmt"
	"regexp"

	"github.com/wdevore/gen-instr/utils"
)

// Example: csrrw rd, csr, rs1
// or       csrrwi rd, csr, zimm[4:0]
//
// or       csrrw x2, mstatus, x0
// or       csrrw x2, mstatus, x9
// or       csrrwi x3, mie, 0x05
// or       csrrwi x3, 0x304, 0x05

func ItypeCSR(json map[string]interface{}) (macCode string, err error) {
	ass := fmt.Sprintf("%s", json["Assembly"])

	rxpr, _ := regexp.Compile(`([csrwsi]+)[ ]+([xa0-9]+),[ ]*([\w]+),[ ]*([xa0-9]+)`)

	fields := rxpr.FindStringSubmatch(ass)

	instru := fields[1]

	rd := fields[2]
	fmt.Println("Destination register: ", rd)

	// csr
	csr := fields[3]
	fmt.Println("CSR register: ", csr)
	// Convert name to addr
	switch csr {
	case "mstatus":
		csr = "0x300"
	case "mie":
		csr = "0x304"
	case "mtvec":
		csr = "0x305"
	case "mscratch":
		csr = "0x340"
	case "mepc":
		csr = "0x341"
	case "mcause":
		csr = "0x342"
	case "mtval":
		csr = "0x343"
	case "mip":
		csr = "0x344"
	}
	fmt.Println("CSR addr: ", csr)

	// rs1 or immediate
	rs1Imm := fields[4]
	fmt.Println("Rs1 or Immediate: ", rs1Imm)

	instruction := make([]byte, 32)

	// The LSB is at [31] (i.e. reversed)
	//  0                                                             31   memory order
	// [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
	//  31                                                            0    logical order
	//  MSB                                                           LSB

	// 31             20 19    15 14      12 11      7 6         0
	// |      csr       |   rs1  |  funct3  |    rd   |  opcode  |

	// CSR (12 bits)
	fi, err := utils.StringHexToInt(csr)
	if err != nil {
		return "", err
	}
	csrA := utils.ReverseArray(utils.IntToBinaryArray(fi))

	instruction[31] = csrA[11]
	instruction[30] = csrA[10]
	instruction[29] = csrA[9]
	instruction[28] = csrA[8]
	instruction[27] = csrA[7]
	instruction[26] = csrA[6]
	instruction[25] = csrA[5]
	instruction[24] = csrA[4]
	instruction[23] = csrA[3]
	instruction[22] = csrA[2]
	instruction[21] = csrA[1]
	instruction[20] = csrA[0]

	// Rs1
	fi, err = utils.StringRegToInt(rs1Imm)
	if err != nil {
		return "", err
	}

	rs1Arr := utils.ReverseArray(utils.IntToBinaryArray(fi))
	instruction[19] = rs1Arr[4]
	instruction[18] = rs1Arr[3]
	instruction[17] = rs1Arr[2]
	instruction[16] = rs1Arr[1]
	instruction[15] = rs1Arr[0]

	// func3
	switch instru {
	case "csrrw":
		instruction[14] = 0
		instruction[13] = 0
		instruction[12] = 1
	case "csrrs":
		instruction[14] = 0
		instruction[13] = 1
		instruction[12] = 0
	case "csrrc":
		instruction[14] = 0
		instruction[13] = 1
		instruction[12] = 1
	case "csrrwi":
		instruction[14] = 1
		instruction[13] = 0
		instruction[12] = 1
	case "csrrsi":
		instruction[14] = 1
		instruction[13] = 1
		instruction[12] = 0
	case "csrrci":
		instruction[14] = 1
		instruction[13] = 1
		instruction[12] = 1
	}

	// rd
	fi, err = utils.StringRegToInt(rd)
	if err != nil {
		return "", err
	}

	rdArr := utils.ReverseArray(utils.IntToBinaryArray(fi))
	instruction[11] = rdArr[4]
	instruction[10] = rdArr[3]
	instruction[9] = rdArr[2]
	instruction[8] = rdArr[1]
	instruction[7] = rdArr[0]

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

	// 31             20 19    15 14      12 11      7 6         0
	// |      csr       | rs1/imm |  funct3  |    rd   |  opcode  |

	fmt.Println("|      csr       | rs1/imm | funct3  |    rd   |  opcode  |")
	fmt.Printf("    %v    %v      %v      %v    %v\n", instr[0:12], instr[12:17], instr[17:20], instr[20:25], instr[25:32])
	// fmt.Println("Instruction Bin: ", instr)
	fmt.Printf("Nibbles: %v %v %v %v %v %v %v %v\n", instr[0:4], instr[4:8], instr[8:12], instr[12:16], instr[16:20], instr[20:24], instr[24:28], instr[28:32])

	return utils.BinaryStringToHexString(instr, false), nil
}
