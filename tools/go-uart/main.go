package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
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

				switch command {
				case "s":
					rxBuf = make([]byte, 3)
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
					byte1 := fmt.Sprintf("%08b", rxBuf[0])
					byte2 := fmt.Sprintf("%08b", rxBuf[1])
					byte3 := fmt.Sprintf("%08b", rxBuf[2])
					// fmt.Println(byte1)
					// fmt.Println(byte2)
					fmt.Println("MatxState:   ", byte1[0:5])
					fmt.Println("VectorState: ", byte1[5:8]+byte2[0:2])
					fmt.Println("IRState:     ", byte2[2:8])
					fmt.Println("Bits:        ", byte3)

					// fmt.Printf("Byte 0: %s\n", IntToBinaryString((int64)(rxBuf[0])))
					// fmt.Printf("Byte 1: %s", IntToBinaryString((int64)(rxBuf[1])))
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
