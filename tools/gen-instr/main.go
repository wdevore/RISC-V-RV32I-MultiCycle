package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"regexp"

	"github.com/atotto/clipboard"
	"github.com/wdevore/gen-instr/assemblers"
)

func main() {
	assemblyPro := os.Args[1:]

	var fileName = "assembly.json"

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

	var context map[string]interface{}
	json.Unmarshal([]byte(byteValue), &context)

	fmt.Println("Assembling: ", context["Assembly"])

	rxpr, _ := regexp.Compile(`([a-z]+)`)

	ass := fmt.Sprintf("%s", context["Assembly"])
	fields := rxpr.FindStringSubmatch(ass)

	instruction := fields[1]

	machineCode := ""
	switch instruction {
	case "jal":
		machineCode, err = assemblers.Jal(context)
	case "jalr":
		machineCode, err = assemblers.Jalr(context)
	case "lui":
		machineCode, err = assemblers.Lui(context)
	case "auipc":
		machineCode, err = assemblers.Auipc(context)
	case "ebreak":
		machineCode, err = assemblers.Ebreak()
	case "lb", "lh", "lw", "lbu", "lhu":
		machineCode, err = assemblers.Loads(context)
	case "sb", "sh", "sw":
		machineCode, err = assemblers.Stores(context)
	case "add", "sub", "xor", "or", "and", "sll", "srl", "sra", "slt", "sltu":
		machineCode, err = assemblers.RtypeAlu(context)
	case "addi", "xori", "ori", "andi", "slli", "srli", "srai", "slti", "sltiu":
		machineCode, err = assemblers.ItypeAlu(context)
	case "beq", "bne", "blt", "bge", "bltu", "bgeu":
		machineCode, err = assemblers.BtypeBranch(context)
	}

	if err != nil {
		panic(err)
	}

	fmt.Println("Machine Code: ", machineCode)
	err = clipboard.WriteAll(machineCode)
	if err != nil {
		panic(err)
	}
}
