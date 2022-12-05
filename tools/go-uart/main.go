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
			// fmt.Printf("Enter command: ")
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
		select {
		case stdin, ok := <-ch:
			if !ok {
				break stdinloop
			} else {
				command = stdin[0:1]
				if stdin[0:1] == "\n" {
					command = previousCommand
				}
				fmt.Println("Command:", command)

				// n, err := port.Write([]byte{0x0a})
				_, err := port.Write([]byte(command))
				if err != nil {
					fmt.Println("Write error")
					log.Fatal(err)
				}
				// fmt.Printf("Sent %v bytes\n", n)
				var rxBuf []byte

				if command == "`" {
					return
				}

				switch command {
				case "s":
					rxBuf = make([]byte, 32)
				default:
					rxBuf = make([]byte, 4)
				}

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

				switch command {
				case "s":
					// Break bytes down into blocks
					// 0000_0000:1100_0100
					// 0000_0|000:11|00_0100 => 00000 00011 000100
					// 0123_4|567:01|23_4567
					fmt.Println("=============================================")
					fmt.Println("  MatxState:", matrixState(rxBuf))
					fmt.Println("VectorState:", vectorState(rxBuf))
					fmt.Println("    IRState:", irState(rxBuf))
					bits(rxBuf)
					fmt.Println()
					showPC(rxBuf)
					showPCPrior(rxBuf)
					showWord("     IR", 7, rxBuf)
					showWord("AMuxOut", 15, rxBuf)
					showWord("BMuxOut", 19, rxBuf)
					showWord(" ImmExt", 23, rxBuf)
					showWord("AddrMux", 27, rxBuf)
				default:
					fmt.Printf("Response: %s", string(rxBuf))
				}

				previousCommand = command
			}
			// case <-time.After(1 * time.Second):
			// Do something when there is nothing read from stdin
			// fmt.Println("{", string(bbyte), "}")
		}
	}

}

func matrixState(rxBuf []byte) string {
	b := fmt.Sprintf("%08b", rxBuf[0])
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

func vectorState(rxBuf []byte) string {
	b1 := fmt.Sprintf("%08b", rxBuf[0])
	b2 := fmt.Sprintf("%08b", rxBuf[1])
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

func irState(rxBuf []byte) string {
	b := fmt.Sprintf("%08b", rxBuf[1])
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

func bits(rxBuf []byte) {
	b := fmt.Sprintf("%08b", rxBuf[2])
	fmt.Println("-----------------------")
	fmt.Println("                      A")
	fmt.Println("                      L")
	fmt.Println("                      U")
	fmt.Println("                      F")
	fmt.Println("C R       P M A M R M l")
	fmt.Println("l e H I P C e L d g e g")
	fmt.Println("o a a R C P m U r | m s")
	fmt.Println("c d l l l l r l l w w l")
	fmt.Println("k y t d d d d d d r r d")
	fmt.Println("-----------------------")
	b2 := fmt.Sprintf("%08b", rxBuf[31])
	fmt.Printf("%s %s %s %s %s %s %s %s %s %s %s %s\n", string(b[0]), string(b[1]), string(b[2]), string(b[3]), string(b[4]), string(b[5]), string(b[6]), string(b[7]), string(b2[0]), string(b2[1]), string(b2[2]), string(b2[3]))
}

func showPC(rxBuf []byte) {
	b0_7 := fmt.Sprintf("%08b", rxBuf[3])
	b8_14 := fmt.Sprintf("%08b", rxBuf[4])
	b15_22 := fmt.Sprintf("%08b", rxBuf[5])
	b23_30 := fmt.Sprintf("%08b", rxBuf[6])
	bs := fmt.Sprintf("%s%s%s%s", b23_30, b15_22, b8_14, b0_7)
	ui64, err := StringToUint(bs)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("     PC: %s_%s_%s_%s (%s) WA:(%s)\n", b23_30, b15_22, b8_14, b0_7, BinaryStringToHexString(bs, true), UintToHexString(ui64/4, true))
}

func showPCPrior(rxBuf []byte) {
	b0_7 := fmt.Sprintf("%08b", rxBuf[11])
	b8_14 := fmt.Sprintf("%08b", rxBuf[12])
	b15_22 := fmt.Sprintf("%08b", rxBuf[13])
	b23_30 := fmt.Sprintf("%08b", rxBuf[14])
	bs := fmt.Sprintf("%s%s%s%s", b23_30, b15_22, b8_14, b0_7)
	ui64, err := StringToUint(bs)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("PCPrior: %s_%s_%s_%s (%s) WA:(%s)\n", b23_30, b15_22, b8_14, b0_7, BinaryStringToHexString(bs, true), UintToHexString(ui64/4, true))
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
