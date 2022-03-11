package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"regexp"
)

func main() {
	assemblyPro := os.Args[1:]

	var fileName = "ebreak.json"

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
		machineCode, err = jal(result)
	case "jalr":
		machineCode, err = jalr(result)
	case "lui":
		machineCode, err = lui(result)
	case "auipc":
		machineCode, err = auipc(result)
	case "ebreak":
		machineCode, err = ebreak()
	}

	if err != nil {
		panic(err)
	}

	fmt.Println("Machine Code: ", machineCode)
}
