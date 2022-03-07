package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"regexp"
)

func main() {
	// Open our jsonFile
	jsonFile, err := os.Open("assembly.json")
	// if we os.Open returns an error then handle it
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println("Successfully Opened assembly.json")
	// defer the closing of our jsonFile so that we can parse it later on
	defer jsonFile.Close()

	byteValue, _ := ioutil.ReadAll(jsonFile)

	var result map[string]interface{}
	json.Unmarshal([]byte(byteValue), &result)

	fmt.Println("Compiling: ", result["Assembly"])

	rxpr, _ := regexp.Compile(`([a-z]+) ([a-z0-9]*)[, ]*([a-z0-9]*)[, ]*([a-z0-9]*)`)

	ass := fmt.Sprintf("%s", result["Assembly"])
	fields := rxpr.FindStringSubmatch(ass)

	instruction := fields[1]

	machineCode := ""
	switch instruction {
	case "jal":
		machineCode, err = jal(result, rxpr)
		if err != nil {
			panic(err)
		}
	}

	fmt.Println("Machine Code: ", machineCode)
}

func _main() {
	hexStr := "0x00000008"
	intV, _ := stringHexToInt(hexStr)

	binStr := intToBinaryString(intV)
	binArr := binaryStringToArray(binStr)
	twosComplement(binArr)
	fmt.Println(binArr)
	fmt.Println(binaryArrayToHexString(binArr))
}
