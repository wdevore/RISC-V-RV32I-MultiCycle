package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"regexp"

	"github.com/wdevore/gen-instr/assemblers"
)

func main() {
	assemblyPro := os.Args[1:]

	var fileName = "lw.json"

	if len(assemblyPro) > 0 {
		fileName = assemblyPro[0]
	} else {
		// panic("Assembly json file required.")
	}

	// Open our jsonFile
	jsonFile, err := os.Open(fileName)

	// if we os.Open returns an error then handle it
	if err != nil {
		panic(err)
	}
	fmt.Println("Successfully Opened assembly.json")
	// defer the closing of our jsonFile so that we can parse it later on
	defer jsonFile.Close()

	byteValue, _ := ioutil.ReadAll(jsonFile)

	var result map[string]interface{}
	json.Unmarshal([]byte(byteValue), &result)

	fmt.Println("Compiling: ", result["Assembly"])

	rxpr, _ := regexp.Compile(`([a-z]+)`)

	ass := fmt.Sprintf("%s", result["Assembly"])
	fields := rxpr.FindStringSubmatch(ass)

	instruction := fields[1]

	machineCode := ""
	switch instruction {
	case "jal":
		machineCode, err = assemblers.Jal(result)
	case "jalr":
		machineCode, err = assemblers.Jalr(result)
	case "lui":
		machineCode, err = assemblers.Lui(result)
	case "auipc":
		machineCode, err = assemblers.Auipc(result)
	case "ebreak":
		machineCode, err = assemblers.Ebreak()
	case "lb", "lh", "lw", "lbu", "lhu":
		machineCode, err = assemblers.Loads(result)
	case "sb", "sh", "sw":
		machineCode, err = assemblers.Stores(result)
	case "add", "sub", "xor", "or", "and", "sll", "srl", "sra", "slt", "sltu":
		machineCode, err = assemblers.RtypeAlu(result)
	case "addi", "xori", "ori", "andi", "slli", "srli", "srai", "slti", "sltiu":
		machineCode, err = assemblers.ItypeAlu(result)
	case "beq", "bne", "blt", "bge", "bltu", "bgeu":
		machineCode, err = assemblers.BtypeBranch(result)
	}

	if err != nil {
		panic(err)
	}

	fmt.Println("Machine Code: ", machineCode)
}
