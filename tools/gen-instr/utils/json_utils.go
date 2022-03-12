package utils

import (
	"errors"
	"fmt"
)

func FindLabelValue(labels interface{}, label string) (value string, err error) {
	for _, v := range labels.([]interface{}) {
		m, ok := v.(map[string]interface{})
		if ok {
			if val, ok := m[label]; ok {
				return fmt.Sprintf("%s", val), nil
			}
		}
	}

	return "", errors.New("Label '" + label + "' not found")
}

func GetRegValue(regFile interface{}, reg string) (value int64, err error) {
	for _, v := range regFile.([]interface{}) {
		m, ok := v.(map[string]interface{})
		if ok {
			if val, ok := m[reg]; ok {
				iVal, err := StringRegToInt(fmt.Sprintf("%s", val))
				if err != nil {
					return 0, errors.New("Unable to format Register '" + reg + "' value")
				}
				return iVal, nil
			}
		}
	}

	return 0, errors.New("Register '" + reg + "' not found")
}
