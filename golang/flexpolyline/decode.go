// Copyright (C) 2019 HERE Europe B.V.
// Licensed under MIT, see full license in LICENSE
// SPDX-License-Identifier: MIT
// License-Filename: LICENSE

// Package flexpolyline contains tools to encode and decode FlexPolylines
// This file defines the Decode() function

package flexpolyline

import (
	"fmt"
)

// Decodes a Polyline from a string following the format specified in
// https://github.com/heremaps/flexible-polyline/blob/master/README.md
func Decode(polyline string) (*Polyline, error) {
	header, body, err := decodeHeader(polyline)
	if err != nil {
		return nil, err
	}
	multiplierDegree := header.Precision2D().factor()
	multiplierZ := header.Precision3D().factor()
	var lastLat, lastLng, lastZ float64
	circaNumChars := len(body)/circaCharsPerPoint(header) + 1
	result := make([]Point, 0, circaNumChars)
	for line := body; len(line) > 0; {
		nextIntValue, polylineTail, err := decodeValueAndAdvance(line)
		if err != nil {
			return nil, err
		}

		deltaLat := float64(toSigned(nextIntValue)) / multiplierDegree
		lastLat += deltaLat

		nextIntValue, polylineTail, err = decodeValueAndAdvance(polylineTail)
		if err != nil {
			return nil, err
		}
		deltaLng := float64(toSigned(nextIntValue)) / multiplierDegree
		lastLng += deltaLng
		nextPoint := Point{Lat: lastLat, Lng: lastLng}
		if header.Type3D() != Absent {
			nextIntValue, polylineTail, err = decodeValueAndAdvance(polylineTail)
			if err != nil {
				return nil, err
			}
			deltaZ := float64(toSigned(nextIntValue)) / multiplierZ
			lastZ += deltaZ
			nextPoint.ThirdDim = lastZ
		}
		result = append(result, nextPoint)

		line = polylineTail
	}

	if header.Type3D() != Absent {
		return MustCreatePolyline3D(header.Type3D(), header.Precision2D(), header.Precision3D(), result), nil
	} else {
		return MustCreatePolyline(header.Precision2D(), result), nil
	}
}

// Returns the type of the third dimension data, parsing only the header
func GetThirdDimension(polyline string) (Type3D, error) {
	header, _, err := decodeHeader(polyline)
	if err != nil {
		return 0, err
	}
	if header == nil {
		return 0, fmt.Errorf("received nil header")
	}
	return header.Type3D(), nil
}

var decodingTable = [...]int8 {
	62, -1, -1, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1,
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
	22, 23, 24, 25, -1, -1, -1, -1, 63, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
	36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51}

func decodeChar(char byte) (int8, error) {
	charValue := uint8(char)
	value := decodingTable[charValue-45]
	if value < 0 {
		return 0, fmt.Errorf("invalid encoding")
	}
	return value, nil
}

func toSigned(value int64) int64 {
	if value & 1 != 0 {
		value = ^value
	}
	value >>= 1
	return value
}

func decodeHeader(polyline string) (*Polyline, string, error) {
	version, err := decodeChar(polyline[0])
	if err != nil {
		return nil, "", err
	}
	if uint(version) != FormatVersion {
		return nil, "", fmt.Errorf("Invalid format version %d, can only handle %d", version, FormatVersion)
	}
	headerContent, body, err := decodeValueAndAdvance(polyline[1:])
	if err != nil {
		return nil, "", err
	}

	precision2D := Precision(headerContent & 15)
	headerContent >>= 4
	type3D := Type3D(headerContent & 7)
	precision3D := Precision(headerContent >> 3)

	return &Polyline{
		coordinates: nil,
		precision2D: precision2D,
		precision3D: precision3D,
		type3D: type3D,
	}, body, nil
}

func decodeValueAndAdvance(polyline string) (int64, string, error) {
	var (
		result int64
		shift uint8
	)
	for i := 0; i < len(polyline); i++ {
		char := polyline[i]
		value, err := decodeChar(char)
		if err != nil {
			return 0, "", err
		}
		orValue := int64(value & 0x1F) << shift
		result |= orValue
		if (value & 0x20) == 0 {
			return result, polyline[i+1:], nil
		} else {
			shift += 5
		}
	}
	return result, "", nil
}
