package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"syscall"

	"go.bug.st/serial"
)

func main() {

	// Retrieve the port list
	ports, err := serial.GetPortsList()
	if err != nil {
		log.Fatal(err)
	}
	if len(ports) == 0 {
		log.Fatal("No serial ports found!")
	}

	// Print the list of detected ports
	// for _, port := range ports {
	// 	fmt.Printf("Found port: %v\n", port)
	// }

	mode := &serial.Mode{
		BaudRate: 115200,
	}
	port, err := serial.Open("/dev/ttyUSB0", mode)
	if err != nil {
		log.Fatal(err)
	}
	defer port.Close()

	ch := make(chan string)

	go func(ch chan string) {
		// Uncomment this block to actually read from stdin
		reader := bufio.NewReader(os.Stdin)
		for {
			s, err := reader.ReadString('\n')
			// fbytes, err := reader.Peek(1)
			// bbyte, err := reader.ReadByte()
			if err != nil { // Maybe log non io.EOF errors, if you want
				close(ch)
				log.Fatal(err)
				return
			}
			ch <- s
		}
		close(ch)
	}(ch)

	rdBuf := make([]byte, 1)
	previousCommand := ""
	command := ""

stdinloop:
	for {
		fmt.Printf("Command: ")
		select {
		case stdin, ok := <-ch:
			if !ok {
				break stdinloop
			} else {
				command = stdin[0:1]
				if stdin[0:1] == "\n" {
					command = previousCommand
				}
				// fmt.Println("Command:", command)

				if command == "`" {
					return
				}

				if command != "s" {
					sendCommand(command, port)
					rxBuf := readPort(rdBuf, 4, port)
					fmt.Printf("Response: %s", string(rxBuf))
				}

				sendCommand("s", port)
				rxBuf := readPort(rdBuf, 40, port)
				showData(rxBuf)

				previousCommand = command
			}
			// case <-time.After(1 * time.Second):
			// Do something when there is nothing read from stdin
			// fmt.Println("{", string(bbyte), "}")
		}
	}

}

func readPort(rdBuf []byte, size int, port serial.Port) (data []byte) {
	rxBuf := make([]byte, size)

	for i := 0; i < len(rxBuf); i++ {
		n, err := port.Read(rdBuf)
		if err != nil {
			fmt.Println("Read error")
			log.Fatal(err)
			// break
		}
		if n == 0 {
			fmt.Println("\nEOF")
			break
		}
		rxBuf[i] = rdBuf[0]
	}

	return rxBuf
}

func sendCommand(command string, port serial.Port) {
	// n, err := port.Write([]byte{0x0a})
	_, err := port.Write([]byte(command))
	if err != nil {
		fmt.Println("Write error")
		log.Fatal(err)
	}
}

func showData(rxBuf []byte) {
	// Break bytes down into blocks
	// 0000_0000:1100_0100
	// 0000_0|000:11|00_0100 => 00000 00011 000100
	// 0123_4|567:01|23_4567
	fmt.Println("=============================================================================")
	fmt.Println("MatrixState:", matrixState(0, rxBuf))
	fmt.Println("VectorState:", vectorState(0, rxBuf))
	fmt.Println("    IRState:", irState(1, rxBuf))
	fmt.Println("      PCSrc:", PCSrc(36, rxBuf))
	fmt.Println("   WDSrcMux:", WDSrcMux(37, rxBuf))
	fmt.Println("  ALU flags:", ALUFlags(38, rxBuf))
	bits(2, 31, rxBuf)
	fmt.Println()
	fmt.Println("          <------------- Binary ------------>  <Byte Addr>  <Word Addr>")
	showPC(3, rxBuf)
	showPCPrior(11, rxBuf)
	showWord("      IR", 7, rxBuf)
	showWord(" AMuxOut", 15, rxBuf)
	showWord(" BMuxOut", 19, rxBuf)
	showWord("  ImmExt", 23, rxBuf)
	showWord(" AddrMux", 27, rxBuf)
	showWord("WdSrcOut", 32, rxBuf)
	showByte(" DataOut", 39, rxBuf)
	fmt.Println("=============================================================================")
}

func matrixState(idx int, rxBuf []byte) string {
	b := fmt.Sprintf("%08b", rxBuf[idx])
	switch b[0:5] {
	case "00000":
		return "Reset"
	case "00001":
		return "Fetch"
	case "00010":
		return "Decode"
	case "00011":
		return "Execute"
	case "00100":
		return "PreFetch"
	case "00101":
		return "IRQ0"
	case "00110":
		return "IRQ1"
	case "00111":
		return "IRQ2"
	case "01000":
		return "Halt"
	}
	return "---"
}

func vectorState(idx int, rxBuf []byte) string {
	b1 := fmt.Sprintf("%08b", rxBuf[idx])
	b2 := fmt.Sprintf("%08b", rxBuf[idx+1])
	b := b1[5:8] + b2[0:2]
	switch b[0:5] {
	case "00000":
		return "Sync0"
	case "00001":
		return "Vector0"
	case "00010":
		return "Vector1"
	case "00011":
		return "Vector2"
	case "00100":
		return "Vector3"
	}
	return "---"
}

func irState(idx int, rxBuf []byte) string {
	b := fmt.Sprintf("%08b", rxBuf[idx])
	switch b[2:8] {
	case "000000":
		return "STStore"
	case "000001":
		return "STMemAcc"
	case "000010":
		return "STMemWrt"
	case "000011":
		return "STMemRrd"
	case "000100":
		return "ITLoad"
	case "000101":
		return "ITLDMemAcc"
	case "000110":
		return "ITLDMemMdr"
	case "000111":
		return "ITLDMemCmpl"
	case "001000":
		return "RType"
	case "001001":
		return "RTCmpl"
	case "001010":
		return "BType"
	case "001011":
		return "BTBranch"
	case "001100":
		return "BTCmpl"
	case "001101":
		return "ITALU"
	case "001110":
		return "ITALUCmpl"
	case "001111":
		return "JTJal"
	case "010000":
		return "JTJalRtr"
	case "010001":
		return "ITJalr"
	case "010010":
		return "UTCmpl"
	case "010011":
		return "UTypeAui"
	case "010100":
		return "UTAuiCmpl"
	case "010101":
		return "ITEbreak"
	case "010110":
		return "ITECall"
	case "010111":
		return "ITCSR"
	case "011000":
		return "ITCSRLd"
	case "011001":
		return "ITMret"
	case "011010":
		return "ITMretClr"
	case "011011":
		return "IRUnknown"
	}
	return "---"
}

func PCSrc(idx int, rxBuf []byte) string {
	b := fmt.Sprintf("%03b", rxBuf[idx])
	switch b[0:3] {
	case "000":
		return "PCSrcAluImm"
	case "001":
		return "PCSrcAluOut"
	case "010":
		return "PCSrcResetVec"
	case "011":
		return "PCSrcRDCSR"
	case "100":
		return "PCSrcResetAdr"
	}
	return "---"
}

func WDSrcMux(idx int, rxBuf []byte) string {
	b := fmt.Sprintf("%02b", rxBuf[idx])
	switch b[0:2] {
	case "00":
		return "WDSrcImm"
	case "01":
		return "WDSrcALUOut"
	case "10":
		return "WDSrcMDR"
	case "11":
		return "WDSrcCSR"
	}
	return "---"
}

func ALUFlags(idx int, rxBuf []byte) string {
	b := fmt.Sprintf("%04b", rxBuf[idx])
	switch b[0:4] {
	case "0000":
		return "----"
	case "0001":
		return "---Z"
	case "0010":
		return "--C-"
	case "0011":
		return "--CZ"
	case "0100":
		return "-N--"
	case "0101":
		return "-N-Z"
	case "0110":
		return "-NC-"
	case "0111":
		return "-NCZ"
	case "1000":
		return "V---"
	case "1001":
		return "V--Z"
	case "1010":
		return "V-C-"
	case "1011":
		return "V-CZ"
	case "1100":
		return "VN--"
	case "1101":
		return "VN-Z"
	case "1110":
		return "VNC-"
	case "1111":
		return "VNCZ"
	}
	return "---"
}

func bits(idx int, idx2 int, rxBuf []byte) {
	b := fmt.Sprintf("%08b", rxBuf[idx])
	fmt.Println("-----------------------------")
	fmt.Println("                      A      ")
	fmt.Println("                      L A    ")
	fmt.Println("                      U d    ")
	fmt.Println("          P M A M   M F d R  ")
	fmt.Println("C R   I P C e L d R e l r s I")
	fmt.Println("l e H R C P m U r g m g   a O")
	fmt.Println("o a a                 s s    ")
	fmt.Println("c d l l l l r l l w w l r l w")
	fmt.Println("k y t d d d d d d r r d c d r")
	fmt.Println("-----------------------------")
	b2 := fmt.Sprintf("%08b", rxBuf[idx2])
	fmt.Printf("%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s\n", string(b[0]), string(b[1]), string(b[2]), string(b[3]), string(b[4]), string(b[5]), string(b[6]), string(b[7]), string(b2[0]), string(b2[1]), string(b2[2]), string(b2[3]), string(b2[4]), string(b2[5]), string(b2[6]))
}

func showPC(idx int, rxBuf []byte) {
	b0_7 := fmt.Sprintf("%08b", rxBuf[idx])
	b8_14 := fmt.Sprintf("%08b", rxBuf[idx+1])
	b15_22 := fmt.Sprintf("%08b", rxBuf[idx+2])
	b23_30 := fmt.Sprintf("%08b", rxBuf[idx+3])
	bs := fmt.Sprintf("%s%s%s%s", b23_30, b15_22, b8_14, b0_7)
	ui64, err := StringToUint(bs)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("      PC: %s_%s_%s_%s (%s) (%s)\n", b23_30, b15_22, b8_14, b0_7, BinaryStringToHexString(bs, true), UintToHexString(ui64/4, true))
}

func showPCPrior(idx int, rxBuf []byte) {
	b0_7 := fmt.Sprintf("%08b", rxBuf[idx])
	b8_14 := fmt.Sprintf("%08b", rxBuf[idx+1])
	b15_22 := fmt.Sprintf("%08b", rxBuf[idx+2])
	b23_30 := fmt.Sprintf("%08b", rxBuf[idx+3])
	bs := fmt.Sprintf("%s%s%s%s", b23_30, b15_22, b8_14, b0_7)
	ui64, err := StringToUint(bs)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf(" PCPrior: %s_%s_%s_%s (%s) (%s)\n", b23_30, b15_22, b8_14, b0_7, BinaryStringToHexString(bs, true), UintToHexString(ui64/4, true))
}

func showByte(label string, idx int, rxBuf []byte) {
	b0_7 := fmt.Sprintf("%08b", rxBuf[idx])
	fmt.Printf("%s: %s (%s)\n", label, b0_7, BinaryStringToHexString(b0_7, true))
}

func showWord(label string, idx int, rxBuf []byte) {
	b0_7 := fmt.Sprintf("%08b", rxBuf[idx])
	b8_14 := fmt.Sprintf("%08b", rxBuf[idx+1])
	b15_22 := fmt.Sprintf("%08b", rxBuf[idx+2])
	b23_30 := fmt.Sprintf("%08b", rxBuf[idx+3])
	bs := fmt.Sprintf("%s%s%s%s", b23_30, b15_22, b8_14, b0_7)
	fmt.Printf("%s: %s_%s_%s_%s (%s)\n", label, b23_30, b15_22, b8_14, b0_7, BinaryStringToHexString(bs, true))
}

func UintToHexString(value uint64, with0x bool) string {
	if with0x {
		return fmt.Sprintf("0x%08X", value)
	} else {
		return fmt.Sprintf("%08X", value)
	}
}

func StringToUint(binary string) (uint64, error) {
	ui, err := strconv.ParseUint(binary, 2, 64)
	if err != nil {
		return 0, err
	}

	return ui, nil
}

func BinaryStringToHexString(binary string, with0x bool) string {
	ui, err := strconv.ParseUint(binary, 2, 64)
	if err != nil {
		return "error"
	}

	return UintToHexString(ui, with0x)
}

func IntToBinaryString(value int64) string {
	if value >= 0 {
		return fmt.Sprintf("%032b", value)
	} else {
		v := fmt.Sprintf("%032b", -value)

		binArr := BinaryStringToArray(v)

		return BinaryArrayToString(binArr)
	}
}

func BinaryStringToArray(value string) []byte {
	a := []byte(value)

	for i, v := range a {
		if v == 48 {
			a[i] = 0
		} else {
			a[i] = 1
		}
	}

	// a = reverseArray(a)
	return a
}

func CopyArray(arr []byte) []byte {
	b := make([]byte, len(arr))
	copy(b, arr)
	return b
}

func BinaryArrayToString(binary []byte) string {
	b := CopyArray(binary)
	s := make([]string, len(b))
	for _, v := range b {
		s = append(s, fmt.Sprintf("%b", v))
	}
	return strings.Join(s, "")
}

func select_stdin() {
	var r_fdset syscall.FdSet
	for i := 0; i < 16; i++ {
		r_fdset.Bits[i] = 0
	}
	r_fdset.Bits[0] = 1
	_, selerr := syscall.Select(1, &r_fdset, nil, nil, nil)
	if selerr != nil {
		log.Fatal(selerr)
	}
}

func process() {
	// err := syscall.SetNonblock(int(os.Stdin.Fd()), true)
	// if err != nil {
	// 	log.Fatal(err)
	// }

	ch := make(chan string)

	go func(ch chan string) {
		// Uncomment this block to actually read from stdin
		reader := bufio.NewReader(os.Stdin)
		for {
			s, err := reader.ReadString('\n')
			// fbytes, err := reader.Peek(1)
			// bbyte, err := reader.ReadByte()
			if err != nil { // Maybe log non io.EOF errors, if you want
				close(ch)
				log.Fatal(err)
				return
			}
			ch <- s
		}
		close(ch)
	}(ch)

stdinloop:
	for {
		select {
		case stdin, ok := <-ch:
			if !ok {
				break stdinloop
			} else {
				fmt.Println("Read input from stdin:", stdin)
			}
			// case <-time.After(1 * time.Second):
			// Do something when there is nothing read from stdin
			// fmt.Println("{", string(bbyte), "}")
		}
	}
}
