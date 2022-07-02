package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"regexp"

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

	if len(assemblyPro) > 0 {
		fileName = assemblyPro[0]
	}

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

	fmt.Println("Assembling: ", context["input"])

	// Fetch assembly to compile
	af := fmt.Sprintf("%s", context["input"])
	assFile, err := os.Open(af)

	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}

	scanner := bufio.NewScanner(assFile)

	labels := make(map[string]string)

	labelExpr, _ := regexp.Compile(`([0-9a-zA-Z]*): @([0-9a-zA-Z]*)`)

	// First pass to collect labels
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

	writeOutput(context, sections)
}

func findLabels(scanner *bufio.Scanner, labels map[string]string, labelExpr *regexp.Regexp) (labelNames []string) {
	pc := 0

	for scanner.Scan() {
		line := scanner.Text()

		if len(line) == 0 {
			continue
		}
		if line[0] == '/' && line[1] == '/' {
			continue
		}

		label, addr, err := matchLabel(line, labelExpr)
		if err == nil {
			if addr == "" {
				// Ex: "Data1: @"
				// An address wasn't supplied. Use current PC instead
				addr = utils.UintToHexString(uint64(pc), false)
			}
			labels[label] = addr
			labelNames = append(labelNames, label)
		} else {
			pc++
		}

	}

	return labelNames
}

func processSection(scanner *bufio.Scanner, labels map[string]string, startLabel string, endLabel string, labelExpr *regexp.Regexp) (sect section, err error) {
	rawExpr, _ := regexp.Compile(`([ ]+)d: ([0-9a-zA-z]+)`)
	addRefExpr, _ := regexp.Compile(`([ ]+)@: ([\w]+)`)

	sect = section{label: startLabel}
	pc, err := utils.StringHexToInt(labels[startLabel])
	if err != nil {
		return sect, err
	}

	// Scan from start to end label
	for scanner.Scan() {
		line := scanner.Text()

		if len(line) == 0 {
			continue
		}
		if line[0] == '/' && line[1] == '/' {
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

		// Is 'line' an address reference
		v, isRef, err := matchAddrRef(line, addRefExpr, labels)
		if err != nil {
			return sect, err
		}
		if isRef {
			// "v" needs to be converted to Byte-address
			v = utils.WordAddrToByteAddrString(v)
			mcl := machine_line{line: line, ltype: "AddrRef", addr: utils.UintToHexString(uint64(pc), false), value: v}
			sect.lines = append(sect.lines, &mcl)
			pc++
			continue
		}

		// An instruction
		mcl := machine_line{line: line, ltype: "Instruction", addr: utils.UintToHexString(uint64(pc), false), value: ""}
		sect.lines = append(sect.lines, &mcl)

		pc++
	}

	return sect, nil
}

// Is 'line' raw data, for example: "   r 0000000C"
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

// Is 'line' a lable, for example: Boot: @040
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

		// Rewrite any instructions to replace references, for example, "lw"
		mc_line.line, err = rewrite(instruction, mc_line.line, labels, loadRefExpr)
		if err != nil {
			return "", err
		}

		// Some instructions require fetching a label, for example, "jal"
		label, value, _ := getLabelRef(instruction, mc_line.line, labels, loadRefExpr)

		// addr needs to be converted to Byte-address form
		byteAddr := utils.WordAddrToByteAddrString(mc_line.addr)
		context := createContext(mc_line.line, byteAddr, label, value)

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
	if instruction == "lbu" {
		fmt.Println("")
	}

	newInstr = ass

	switch instruction {
	case "lb", "lh", "lw", "lbu", "lhu":
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
	}

	return newInstr, nil
}

func getLabelRef(instruction string, ass string, labels map[string]string, loadRefExpr *regexp.Regexp) (label string, value string, err error) {
	label, err = assemblers.GetLabel(instruction, ass)
	if err != nil {
		return "", "", err
	}

	value = labels[label]

	return label, value, nil
}

func resolveCalc(instruction string, ass string, labels map[string]string) (value string, err error) {
	switch instruction {
	case "lb", "lh", "lw", "lbu", "lhu":
		loadRefExpr, _ := regexp.Compile(`@([\w]+)([+]*)([0-9]*)`)

		fields := loadRefExpr.FindStringSubmatch(ass)

		if len(fields) > 0 {
			if fields[2] == "+" {
				// Ex: @Data+3
				value = labels[fields[1]]
				byteAddr := utils.WordAddrToByteAddrString(value)
				bad, err := utils.StringHexToInt(byteAddr)
				if err != nil {
					return "", err
				}

				baOffset := utils.WordAddrToByteAddrString(fields[3])
				offset, err := utils.StringHexToInt(baOffset)
				if err != nil {
					return "", err
				}
				v := uint64(bad + offset)
				value = utils.UintToHexString(v, true)
			} else {
				// Ex: @Data
				value = labels[fields[1]]
				byteAddr := utils.WordAddrToByteAddrString(value)
				bad, err := utils.StringHexToInt(byteAddr)
				if err != nil {
					return "", err
				}

				value = utils.UintToHexString(uint64(bad), true)
			}
		}
	}

	return value, nil
}

func writeOutput(context map[string]interface{}, sections []section) {
	fmt.Println("Writing: ", context["output"])

	outfile := fmt.Sprint(context["output"])
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
	_, err = f.WriteString("\n")
	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}

	f.Sync()

	fmt.Println("File written: ", context["output"])
}
