package main

import (
	"fmt"
	"strconv"
	"strings"
)

func stringHexToInt(hex string) (value int64, err error) {
	hex = strings.Replace(hex, "0x", "", 1)
	value, err = strconv.ParseInt(hex, 16, 64)
	if err != nil {
		return 0, err
	}
	return value, nil
}

func stringRegToInt(reg string) (value int64, err error) {
	r := strings.Replace(reg, "x", "", 1)
	value, err = strconv.ParseInt(r, 16, 64)
	if err != nil {
		return 0, err
	}

	return value, nil
}

func uintToHexString(value uint64) string {
	return fmt.Sprintf("0x%08X", value)
}

func intToBinaryString(value int64) string {
	if value >= 0 {
		return fmt.Sprintf("%032b", value)
	} else {
		v := fmt.Sprintf("%032b", -value)
		binArr := binaryStringToArray(v)
		twosComplement(binArr)
		return binaryArrayToString(binArr, false)
	}
}

func binaryArrayToString(binary []byte, reverse bool) string {
	b := copyArray(binary)
	if reverse {
		b = reverseArray(b)
	}
	s := make([]string, len(b))
	for _, v := range b {
		s = append(s, fmt.Sprintf("%b", v))
	}
	return strings.Join(s, "")
}

func binaryStringToArray(value string) []byte {
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

func binaryStringToHexString(binary string) string {
	ui, err := strconv.ParseUint(binary, 2, 64)
	if err != nil {
		return "error"
	}

	return uintToHexString(ui)
}

func binaryArrayToHexString(arr []byte) string {
	return binaryStringToHexString(binaryArrayToString(arr, false))
}

func intToBinaryArray(value int64) []byte {
	return binaryStringToArray(intToBinaryString(value))
}
