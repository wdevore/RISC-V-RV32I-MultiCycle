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
	port, err := serial.Open("/dev/ttyUSB1", mode)
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

	// ----------------------------------------
	// How many bytes are transmitter by fpga
	// ----------------------------------------
	rxBuffSize := 68 + 1

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
				rxBuf := readPort(rdBuf, rxBuffSize, port)
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
	bits(2, 31, 40, rxBuf)
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
	showWord("  MDROut", 41, rxBuf)
	showWord("  ALUOut", 45, rxBuf)
	showByte(" DataOut", 39, rxBuf)
	showWord("    Mepc", 49, rxBuf)
	showWord("     Mip", 53, rxBuf)
	showWord(" Mstatus", 57, rxBuf)
	showWord("     Mie", 61, rxBuf)
	showWord(" CSRData", 65, rxBuf)
	fmt.Println("=============================================================================")
}

func matrixState(idx int, rxBuf []byte) string {
	b2 := fmt.Sprintf("%08b", rxBuf[idx])
	ui, _ := strconv.ParseUint(b2[0:5], 2, 64)
	switch ui { // b[0:5]
	case 0:
		return "Reset"
	case 1:
		return "Fetch"
	case 2:
		return "Decode"
	case 3:
		return "Execute"
	case 4:
		return "PreFetch"
	case 5:
		return "IRQ0"
	case 6:
		return "IRQ1"
	case 7:
		return "IRQ2"
	case 8:
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
	ui, _ := strconv.ParseUint(b[2:8], 2, 64)

	// b := fmt.Sprintf("%d", rxBuf[idx])
	switch ui { // b[2:8]
	case 0:
		return "STStore"
	case 1:
		return "STMemAcc"
	case 2:
		return "STMemWrt"
	case 3:
		return "STMemRrd"
	case 4:
		return "ITLoad"
	case 5:
		return "ITLDMemAcc"
	case 6:
		return "ITLDMemMdr"
	case 7:
		return "ITLDMemCmpl"
	case 8:
		return "RType"
	case 9:
		return "RTCmpl"
	case 10:
		return "BType"
	case 11:
		return "BTBranch"
	case 12:
		return "BTCmpl"
	case 13:
		return "ITALU"
	case 14:
		return "ITALUCmpl"
	case 15:
		return "JTJal"
	case 16:
		return "JTJalRtr"
	case 17:
		return "ITJalr"
	case 18:
		return "ITJalrRtr"
	case 19:
		return "UType"
	case 20:
		return "UTCmpl"
	case 21:
		return "UTypeAui"
	case 22:
		return "UTAuiCmpl"
	case 23:
		return "ITEbreak"
	case 24:
		return "ITECall"
	case 25:
		return "ITCSR"
	case 26:
		return "ITCSRLd"
	case 27:
		return "ITMret"
	case 28:
		return "ITMretClr"
	case 29:
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

func bits(idx int, idx2 int, idx3 int, rxBuf []byte) {
	b := fmt.Sprintf("%08b", rxBuf[idx])
	fmt.Println("            -------------------------------------------------")
	fmt.Println("                    |                 A       t | i i i   i i")
	fmt.Println("                  c |                 L       a | r n r   s r")
	fmt.Println("                  l |                 U       k | q t g w c q")
	fmt.Println("                  k |                 F A     e |   r   r s r")
	fmt.Println("                    |                 l d       | t   p i r s")
	fmt.Println("                  s |     P M A M   M a d R   b | r p e t   t")
	fmt.Println("            C R   e | I P C e L d R e g r s I r | i r n e i  ")
	fmt.Println("            l e H l | R C P m U r g m s   a O a | g o d   n t")
	fmt.Println("            o a a e |                   s     n | g g i c s r")
	fmt.Println("            c d l c | l l l r l l w w l r l w c | r r n s t i")
	fmt.Println("            k y t t | d d d d d d r r d c d r h | d e g r r g")
	fmt.Println("            -------------------------------------------------")
	b2 := fmt.Sprintf("%08b", rxBuf[idx2])
	b3 := fmt.Sprintf("%08b", rxBuf[idx3])
	clk_select := "0"
	if string(b3[0]) == "0" && string(b3[1]) == "1" {
		clk_select = "1"
	} else if string(b3[0]) == "1" && string(b3[1]) == "0" {
		clk_select = "2"
	}
	fmt.Printf("            %s %s %s %s | %s %s %s %s %s %s %s %s %s %s %s %s %s | %s %s %s %s %s %s\n",
		string(b[0]), string(b[1]), string(b[2]), clk_select, string(b[3]), string(b[4]), string(b[5]),
		string(b[6]), string(b[7]), string(b2[0]), string(b2[1]), string(b2[2]), string(b2[3]),
		string(b2[4]), string(b2[5]), string(b2[6]), string(b2[7]),
		string(b3[2]), string(b3[3]), string(b3[4]), string(b3[5]), string(b3[6]), string(b3[7]))
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
