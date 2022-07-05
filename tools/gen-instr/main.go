package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"math/bits"
	"os"
	"regexp"

	"github.com/atotto/clipboard"
	"github.com/wdevore/gen-instr/assemblers"
	"github.com/wdevore/gen-instr/utils"
)

func main() {
	processLine()
	// testBaudGenerator()
}

func processLine() {
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

func testUART() {
	var acc uint
	cnt := 0
	pcnt := 0
	var carryI uint
	var carryO uint
	carryI = 0
	var intrm uint
	for i := 0; acc <= 115200; i++ {
		// acc, carryO = bits.Add(acc, 59, carryI)
		intrm, carryO = bits.Add(intrm, 59, carryI)
		s := utils.IntToBinaryString(int64(intrm))

		a := utils.BinaryStringToArray(s)
		if a[32-11] == 1 {
			acc += intrm
			fmt.Println(intrm, " | ", acc, " : ", cnt-pcnt)
			intrm = 0
			pcnt = cnt
		}

		// fmt.Println(s)
		carryI = carryO
		cnt++
	}

	fmt.Println(cnt)
	fmt.Println(acc)
}

func testBits() {
	s := utils.IntToBinaryString(int64(0))
	a := utils.BinaryStringToArray(s)
	// Note: "a" is reversed
	cnt := 0
	// pcnt := 0
	for i := 0; i < 2000; i++ {
		addBinary(a, 59)
		if a[32-11] == 1 {
			// ass := utils.BinaryArrayToString(a, false)
			// dt := cnt - pcnt
			// if dt > 1 {
			fmt.Print("0")
			// ccccccccccccccccccccccccccc|
			// 0000_0000_0000_0000_0000_0000_0000_0000
			//                           |
			//                            \ Overflow bit
			// To simulate a N bit counter, clear overflow bit
			// for j := 0; j < 22; j++ {
			a[21] = 0
			// }
			// fmt.Println(cnt, " : ", ass, " : dt: ", dt)
			// }
			// pcnt = cnt
		}
		fmt.Print("1")
		// fmt.Println(cnt, " : ", utils.BinaryArrayToString(a, false))
		cnt++
	}
}

func addBinary(arr []byte, v int) {
	for i := 0; i < v; i++ {
		utils.AddOne(arr)
	}
}

func testBaudGenerator() {
	clkFreq := 25000000
	baud := 115200
	baudGeneratorAccWidth := 16
	baudGeneratorSft := baud << baudGeneratorAccWidth
	baudGeneratorInc0 := baudGeneratorSft / clkFreq
	fmt.Println(baudGeneratorInc0)
	baudGeneratorInc := ((baud << (baudGeneratorAccWidth - 4)) + (clkFreq >> 5)) / (clkFreq >> 4)
	cnt := 0
	pcnt := 0

	s := utils.IntToBinaryString(int64(0))
	a := utils.BinaryStringToArray(s)

	//                      |
	// 0000_0000_0000_0000_1100_0001_0010_0110
	// 0000 0000 0000 0000 0100 0000 00101 001
	for clk := 0; clk < 1000; clk++ {
		addBinary(a, baudGeneratorInc)
		ass := utils.BinaryArrayToString(a, false)

		if a[32-baudGeneratorAccWidth+1] == 1 {
			// fmt.Print("0")
			// fmt.Println("clk: ", clk, " : ", ass)
			a[baudGeneratorAccWidth+1] = 0
			dt := cnt - pcnt
			fmt.Println(cnt, " : ", ass, " : dt: ", dt)
			pcnt = cnt
		}
		// fmt.Print("1")
		cnt++
	}
}
