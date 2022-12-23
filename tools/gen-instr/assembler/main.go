package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"regexp"
	"strings"

	"github.com/wdevore/gen-instr/assemblers"
	"github.com/wdevore/gen-instr/utils"
)

type machine_line struct {
	line  string
	ltype string
	addr  string
	value string
	code  string
}

type section struct {
	label string
	lines []*machine_line
}

func main() {
	assemblyPro := os.Args[1:]

	var fileName = "assembly.json"

	// Open our jsonFile
	jsonFile, err := os.Open(fileName)

	// if we os.Open returns an error then handle it
	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}

	// defer the closing of our jsonFile so that we can parse it later on
	defer jsonFile.Close()

	fmt.Println("Successfully Opened assembly.json")

	byteValue, _ := ioutil.ReadAll(jsonFile)

	var context map[string]interface{}
	json.Unmarshal([]byte(byteValue), &context)

	inputPath := context["inputPath"]
	inputAsmFile := context["inputFile"]

	if len(assemblyPro) > 0 {
		inputAsmFile = assemblyPro[0]
	}

	fmt.Println("Assembling: ", inputAsmFile)

	// Fetch assembly to compile
	af := fmt.Sprintf("%s%s", inputPath, inputAsmFile)
	assFile, err := os.Open(af)

	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}

	scanner := bufio.NewScanner(assFile)

	labels := make(map[string]string)

	// Check if address on Label is in word-address form if it has a prefix "@"
	// "$" means byte-address form
	labelExpr, _ := regexp.Compile(`([0-9a-zA-Z]*): [@$]([0-9a-zA-Z]*)`)

	// First pass to collect labels. All address values are converted to byte-address form
	labelNames := findLabels(scanner, labels, labelExpr)

	// Second pass to collect program lines
	assFile.Seek(0, 0) // Restart stream.
	scanner = bufio.NewScanner(assFile)

	sections := []section{}

	for i := 0; i < len(labelNames)-1; i++ {
		startLabel := labelNames[i]
		endLabel := labelNames[i+1]
		sect, err := processSection(scanner, labels, startLabel, endLabel, labelExpr)
		if err != nil {
			fmt.Println(err)
			os.Exit(-1)
		}
		sections = append(sections, sect)
	}

	sect, err := processSection(scanner, labels, labelNames[len(labelNames)-1], "", labelExpr)
	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}
	sections = append(sections, sect)

	instrExpr, _ := regexp.Compile(`([a-z]+)`)
	loadRefExpr, _ := regexp.Compile(`@([\w]+)([+]*)([0-9]*)`)

	// Assemble program
	for _, seti := range sections {
		for _, mc_line := range seti.lines {
			_, err := assemble(mc_line, instrExpr, loadRefExpr, labels)
			if err != nil {
				fmt.Println(err)
				os.Exit(-1)
			}
		}
	}

	writeRamFile(context, sections)
	writeOutFile(context, sections)
}

func findLabels(scanner *bufio.Scanner, labels map[string]string, labelExpr *regexp.Regexp) (labelNames []string) {
	commentLineExp, _ := regexp.Compile(`^([ ]*)[ ]*([\/\/]{2})`)

	// PC counts in word-address format of type uint64 (hex value)
	pc := 0

	for scanner.Scan() {
		line := scanner.Text()

		if len(line) == 0 {
			continue
		}

		fields := commentLineExp.FindStringSubmatch(line)
		if len(fields) > 0 {
			continue
		}

		// "addr" is in word-address form
		label, addr, err := matchLabel(line, labelExpr)
		if err == nil {
			// Ex: "Data1: @"
			if addr == "" {
				// An address wasn't supplied. Use current PC instead
				addr = utils.UintToHexString(uint64(pc), false)
			}

			// If "$" present then the address is being specified in
			// byte-address form. We need to convert it internally
			// back to word-address for counting.
			if strings.Contains(line, "$") {
				addr = utils.ByteAddrToWordAddrString(addr)
			}

			// Convert addr from string-hex to uint so we can update the PC
			value, err := utils.StringHexToInt(addr)
			if err != nil {
				log.Fatalln(err)
			}

			pc = int(value)

			labels[label] = addr
			labelNames = append(labelNames, label)
		} else {
			pc++
		}

	}

	return labelNames
}

func processSection(scanner *bufio.Scanner, labels map[string]string, startLabel string, endLabel string, labelExpr *regexp.Regexp) (sect section, err error) {
	rawExpr, _ := regexp.Compile(`([ ]*)d: ([0-9a-zA-z]+)`)
	addRefExpr, _ := regexp.Compile(`([ ]*)@: ([\w]+)`)

	sect = section{label: startLabel}
	pc, err := utils.StringHexToInt(labels[startLabel])
	if err != nil {
		return sect, err
	}

	// Scan from start to end label
	for scanner.Scan() {
		line := scanner.Text()
		line = strings.Trim(line, " ")

		if len(line) == 0 {
			continue
		}
		if line[0] == '/' && line[1] == '/' {
			continue
		}

		// label, _, _ := matchLabel(line, labelExpr)
		// if label != "" {
		// 	// Is label the starting label
		// 	if label == startLabel {
		// 		continue
		// 	}

		// 	if label == endLabel {
		// 		break
		// 	}
		// }

		v, isRaw, err := matchRaw(line, rawExpr)
		if err != nil {
			return sect, err
		}
		if isRaw {
			mcl := machine_line{line: line, ltype: "Data", addr: utils.UintToHexString(uint64(pc), false), value: v}
			sect.lines = append(sect.lines, &mcl)
			pc++
			continue
		}

		// Is 'line' an address reference, ex: "@: Data"
		v, isRef, err := matchAddrRef(line, addRefExpr, labels)
		if err != nil {
			return sect, err
		}
		if isRef {

			v = utils.WordAddrToByteAddrString(v)
			// vi, err := utils.StringHexToInt(v)
			// if err != nil {
			// 	return sect, err
			// }
			// utils.UintToHexString(uint64(vi), false)

			mcl := machine_line{line: line, ltype: "AddrRef", addr: utils.UintToHexString(uint64(pc), false), value: v}
			sect.lines = append(sect.lines, &mcl)
			pc++
			continue
		}

		label, _, _ := matchLabel(line, labelExpr)
		if label != "" {
			// Is label the starting label
			if label == startLabel {
				continue
			}

			if label == endLabel {
				break
			}
		}

		// An instruction
		mcl := machine_line{line: line, ltype: "Instruction", addr: utils.UintToHexString(uint64(pc), false), value: ""}
		sect.lines = append(sect.lines, &mcl)

		pc++
	}

	return sect, nil
}

// Is 'line' raw data, for example: "   d: 0000000C"
func matchRaw(line string, expr *regexp.Regexp) (value string, isMatch bool, err error) {
	fields := expr.FindStringSubmatch(line)
	if len(fields) > 0 {
		return fields[2], true, nil
	}

	return "", false, nil
}

// Is 'line' address reference, for example: "  @: Trap"
func matchAddrRef(line string, expr *regexp.Regexp, labels map[string]string) (value string, isMatch bool, err error) {
	fields := expr.FindStringSubmatch(line)
	if len(fields) > 0 {
		// Look up address reference in Labels
		label := fields[2]
		addr, present := labels[label]
		if !present {
			return "", false, fmt.Errorf("label not found")
		}

		return addr, true, nil
	}

	return "", false, nil
}

// Is 'line' a lable, for example: Boot: @040  or Boot: 0x300
func matchLabel(line string, expr *regexp.Regexp) (label string, addr string, err error) {
	fields := expr.FindStringSubmatch(line)
	if len(fields) > 0 {
		label := fields[1]

		addr = fields[2]

		return label, addr, nil
	}

	return "", "", fmt.Errorf("not a Label line")
}

func assemble(mc_line *machine_line, expr *regexp.Regexp, loadRefExpr *regexp.Regexp, labels map[string]string) (macCode string, err error) {

	switch mc_line.ltype {
	case "Data":
		macCode = mc_line.value
	case "AddrRef":
		break
	default:
		fields := expr.FindStringSubmatch(mc_line.line)

		instruction := fields[1]
		// if instruction == "blt" {
		// 	fmt.Println("")
		// }
		// Rewrite any instructions to replace references, for example, "lw"
		mc_line.line, err = rewrite(instruction, mc_line.line, labels, loadRefExpr)
		if err != nil {
			return "", err
		}

		// Some instructions require fetching a label, for example, "jal"
		label, value, _ := getLabelRef(instruction, mc_line.line, labels, loadRefExpr)

		// All address fields need to be converted to Byte-address form
		// for the Context--depending on the instruction.
		// switch instruction {
		// case "beq", "bne", "blt", "bge", "bltu", "bgeu", "jal":
		// 	value = utils.WordAddrToByteAddrString(value)
		// }

		// PC address needs to be converted to Byte-address form
		pcByteAddr := utils.WordAddrToByteAddrString(mc_line.addr)
		// if strings.Contains(instruction, "jal") {
		// 	fmt.Println("debug")
		// }

		context := createContext(mc_line.line, pcByteAddr, label, value)

		macCode, err = assemblers.Dispatch(instruction, context)
		mc_line.code = macCode

		if err != nil {
			return "", err
		}
	}

	return macCode, nil
}

func createContext(ass string, pc string, label string, value string) (context map[string]interface{}) {
	// Create a context to pass to the assemblers
	ctx := "{"
	ctx += "\"Assembly\":\"" + ass + "\","
	ctx += "\"PC\":\"" + pc + "\","
	ctx += "\"Labels\": [{\"" + label + "\":\"" + value + "\"}]"
	ctx += "}"

	json.Unmarshal([]byte(ctx), &context)

	return context
}

func rewrite(instruction string, ass string, labels map[string]string, loadRefExpr *regexp.Regexp) (newInstr string, err error) {
	newInstr = ass

	switch instruction {
	case "lb", "lh", "lw", "lbu", "lhu", "sb", "sh", "sw":
		value, err := resolveCalc(instruction, ass, labels)

		if err != nil {
			return "", err
		}

		if value == "" {
			newInstr = ass
		} else {
			lFields := assemblers.GetLoadsFields(ass)
			newInstr = lFields[1] + " " + lFields[2] + ", " + value + "(" + lFields[4] + ")"
		}
		// case "beq", "bne", "blt", "bge", "bltu", "bgeu":
		// 	// Rewrite label to branch target value
		// 	value, err := resolveCalc(instruction, ass, labels)

		// 	if err != nil {
		// 		return "", err
		// 	}

		// 	lFields := assemblers.GetLoadsFields(ass)
		// 	newInstr = lFields[1] + " " + lFields[2] + ", "+ lFields[3] + ", " + value
	}

	return newInstr, nil
}

func resolveCalc(instruction string, ass string, labels map[string]string) (value string, err error) {
	switch instruction {
	case "lb", "lh", "lw", "lbu", "lhu", "sb", "sh", "sw":
		// Formats can be:
		// lw x4, 0x28(x0)
		// lw x4, 0x28+4(x0)
		// lw x4, @Data(x0)
		// lw x4, @Data+4(x0)

		expr, _ := regexp.Compile(`([\w]+) ([x0-9]+),[ ]*([\w@]+)([+]*)([0-9]*)`)

		fields := expr.FindStringSubmatch(ass)

		if len(fields) > 0 {
			expr, _ = regexp.Compile(`([\w]+) ([x0-9]+),[ ]*([\w]+)([+]*)([0-9]*)`)
			// Check for format: lw x4, 0x28(x0)
			fields = expr.FindStringSubmatch(ass)

			if len(fields) > 0 {
				if fields[4] != "" {
					// Ex: 0x28+4
					base, err := utils.StringHexToInt(fields[3])
					if err != nil {
						return "", err
					}

					offset, err := utils.StringHexToInt(fields[5])
					if err != nil {
						return "", err
					}
					v := uint64(base + offset)

					value = utils.UintToHexString(v, true)
				} else {
					// Ex: 0x28
					value = labels[fields[3]]
				}
			} else {
				expr, _ = regexp.Compile(`([\w]+) ([x0-9]+),[ ]*@([\w]+)([+]*)([0-9]*)`)
				// Check for format: lw x4, @Data(x0)
				fields = expr.FindStringSubmatch(ass)

				if fields[4] != "" {
					// Ex: @Data+4
					value = labels[fields[3]]

					base, err := utils.StringHexToInt(value)
					if err != nil {
						return "", err
					}

					offset, err := utils.StringHexToInt(fields[5])
					if err != nil {
						return "", err
					}

					v := uint64(base + offset)
					value = utils.UintToHexString(v, true)
				} else {
					// Ex: @Data
					value = labels[fields[3]]
				}

				value = utils.WordAddrToByteAddrString(value)
			}
		}
	case "beq", "bne", "blt", "bge", "bltu", "bgeu":
		// Not currently a path taken.
		expr, _ := regexp.Compile(`@([\w]+)`)

		fields := expr.FindStringSubmatch(ass)
		if len(fields) == 0 {
			return "", fmt.Errorf("branch label required")
		}

		value = labels[fields[1]]
		byteAddr := utils.WordAddrToByteAddrString(value)
		bad, err := utils.StringHexToInt(byteAddr)
		if err != nil {
			return "", err
		}

		value = utils.UintToHexString(uint64(bad), true)
	}

	return value, nil
}

func getLabelRef(instruction string, ass string, labels map[string]string, loadRefExpr *regexp.Regexp) (label string, value string, err error) {
	label, err = assemblers.GetLabel(instruction, ass)
	if err != nil {
		return "", "", err
	}

	value = labels[label]

	return label, value, nil
}

func writeRamFile(context map[string]interface{}, sections []section) {
	file := context["RamFile"]
	fmt.Println("Writing: ", file)

	typeSim := fmt.Sprint(context["Type"])
	var ramDir = ""
	if typeSim == "Syn" {
		ramDir = fmt.Sprint(context["SynRamDir"])
		fmt.Println("Writing ram file to: ", ramDir)
	} else {
		ramDir = fmt.Sprint(context["SimRamDir"])
	}

	_ = os.Mkdir(ramDir, os.ModePerm)

	outfile := fmt.Sprint(file)

	f, err := os.Create(ramDir + outfile)

	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}

	defer f.Close()

	for _, seti := range sections {
		for _, mc_line := range seti.lines {
			var err error

			switch mc_line.ltype {
			case "Data", "AddrRef":
				_, err = f.WriteString("@" + mc_line.addr + " " + mc_line.value + "\n")
			default:
				_, err = f.WriteString("@" + mc_line.addr + " " + mc_line.code + "\n")
			}

			if err != nil {
				fmt.Println(err)
				os.Exit(-1)
			}
		}
	}

	// We must write an extra line because SystemVerilog's readmenh
	// needs to detect a final blank line.
	// _, err = f.WriteString("\n")
	// if err != nil {
	// 	fmt.Println(err)
	// 	os.Exit(-1)
	// }

	f.Sync()

	fmt.Println("File written: ", file)
}

func writeOutFile(context map[string]interface{}, sections []section) {
	file := context["OutFile"]
	fmt.Println("Writing: ", context["OutFile"])

	outfile := fmt.Sprint(file)
	f, err := os.Create(outfile)

	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}

	defer f.Close()

	for _, seti := range sections {
		for _, mc_line := range seti.lines {
			var err error

			switch mc_line.ltype {
			case "Data", "AddrRef":
				_, err = f.WriteString("@" + mc_line.addr + " " + mc_line.value + " " + mc_line.line + "\n")
			default:
				_, err = f.WriteString("@" + mc_line.addr + " " + mc_line.code + " " + mc_line.line + "\n")
			}

			if err != nil {
				fmt.Println(err)
				os.Exit(-1)
			}
		}
	}

	f.Sync()

	fmt.Println("File written: ", file)
}
