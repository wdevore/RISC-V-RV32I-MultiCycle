package utils

import (
	"fmt"
	"strconv"
	"strings"
)

func StringHexToInt(hex string) (value int64, err error) {
	hex = strings.Replace(hex, "0x", "", 1)
	hex = strings.Replace(hex, "WA:", "", 1)

	value, err = strconv.ParseInt(hex, 16, 64)
	if err != nil {
		return 0, err
	}
	return value, nil
}

func StringRegToInt(reg string) (value int64, err error) {
	r := strings.Replace(reg, "x", "", 1)
	value, err = strconv.ParseInt(r, 10, 64)
	if err != nil {
		return 0, err
	}

	return value, nil
}

func UintToHexString(value uint64) string {
	return fmt.Sprintf("0x%08X", value)
}

func IntToBinaryString(value int64) string {
	if value >= 0 {
		return fmt.Sprintf("%032b", value)
	} else {
		v := fmt.Sprintf("%032b", -value)
		binArr := BinaryStringToArray(v)
		TwosComplement(binArr)
		return BinaryArrayToString(binArr, false)
	}
}

func BinaryArrayToString(binary []byte, reverse bool) string {
	b := CopyArray(binary)
	if reverse {
		b = ReverseArray(b)
	}
	s := make([]string, len(b))
	for _, v := range b {
		s = append(s, fmt.Sprintf("%b", v))
	}
	return strings.Join(s, "")
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

func BinaryStringToHexString(binary string) string {
	ui, err := strconv.ParseUint(binary, 2, 64)
	if err != nil {
		return "error"
	}

	return UintToHexString(ui)
}

func BinaryArrayToHexString(arr []byte) string {
	return BinaryStringToHexString(BinaryArrayToString(arr, false))
}

func IntToBinaryArray(value int64) []byte {
	return BinaryStringToArray(IntToBinaryString(value))
}
