package assemblers

import "fmt"

func Dispatch(instruction string, context map[string]interface{}) (machineCode string, err error) {
	switch instruction {
	case "jal":
		machineCode, err = Jal(context)
	case "jalr":
		machineCode, err = Jalr(context)
	case "lui":
		machineCode, err = Lui(context)
	case "auipc":
		machineCode, err = Auipc(context)
	case "ebreak":
		machineCode, err = Ebreak()
	case "lb", "lh", "lw", "lbu", "lhu":
		machineCode, err = Loads(context)
	case "sb", "sh", "sw":
		machineCode, err = Stores(context)
	case "add", "sub", "xor", "or", "and", "sll", "srl", "sra", "slt", "sltu":
		machineCode, err = RtypeAlu(context)
	case "addi", "xori", "ori", "andi", "slli", "srli", "srai", "slti", "sltiu":
		machineCode, err = ItypeAlu(context)
	case "beq", "bne", "blt", "bge", "bltu", "bgeu":
		machineCode, err = BtypeBranch(context)
	case "csrrw", "csrrs", "csrrc", "csrrwi", "csrrsi", "csrrci":
		machineCode, err = ItypeCSR(context)
	case "mret":
		machineCode, err = MRet(context)
	}

	if err != nil {
		return "", err
	}

	return machineCode, nil
}

func GetFields(instruction string, ass string) []string {
	switch instruction {
	case "jal":
		return GetJalFields(ass)
	case "jalr":
		return GetJalrFields(ass)
	case "beq", "bne", "blt", "bge", "bltu", "bgeu":
		return GetBranchFields(ass)
	case "lb", "lh", "lw", "lbu", "lhu":
		return GetLoadsFields(ass)
	}

	return nil
}

func GetLabel(instruction string, ass string) (label string, err error) {
	fields := GetFields(instruction, ass)
	if fields == nil {
		return "", fmt.Errorf("no fields found for instruction: " + instruction)
	}

	switch instruction {
	case "jal":
		return fields[3], nil
	case "jalr":
		return fields[3], nil
	case "beq", "bne", "blt", "bge", "bltu", "bgeu":
		return fields[4], nil
	case "lb", "lh", "lw", "lbu", "lhu":
		return fields[3], nil
	}

	return "", fmt.Errorf("unknown instruction: " + instruction)
}
