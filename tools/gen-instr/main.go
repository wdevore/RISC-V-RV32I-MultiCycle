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

	machineCode, err := assemblers.Dispatch(instruction, context)

	if err != nil {
		panic(err)
	}

	fmt.Println("Machine Code: ", machineCode)
	err = clipboard.WriteAll(machineCode)
	if err != nil {
		panic(err)
	}
}
