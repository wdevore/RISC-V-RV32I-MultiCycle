package utils

func TwosComplement(arr []byte) []byte {
	// Negate all bits
	Negate(arr)

	// Add 1
	AddOne(arr)
	return arr
}

func Negate(arr []byte) {
	// Negate all bits
	for i := range arr {
		if arr[i] == 0 {
			arr[i] = 1
		} else {
			arr[i] = 0
		}
	}
}

// The LSB is at [31] (i.e. reversed)
// 0                                                              31
// [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0]
//  MSB                                                           LSB
//
//  0011  -> 1100
//              1
//           1101
func AddOne(arr []byte) {
	l := len(arr)
	c := 1
	for i := l - 1; i > 0; i-- {
		nc := int(arr[i]) & c
		if nc == 1 {
			arr[i] = 0
		} else {
			arr[i] = byte(int(arr[i]) | c)
		}
		c = nc
	}
}

func CopyArray(arr []byte) []byte {
	b := make([]byte, len(arr))
	copy(b, arr)
	return b
}

func ReverseArray(arr []byte) []byte {
	for i := 0; i < len(arr)/2; i++ {
		j := len(arr) - i - 1
		arr[i], arr[j] = arr[j], arr[i]
	}
	return arr
}
