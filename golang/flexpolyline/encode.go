// Copyright (C) 2019 HERE Europe B.V.
// Licensed under MIT, see full license in LICENSE
// SPDX-License-Identifier: MIT
// License-Filename: LICENSE

// Package flexpolyline contains tools to encode and decode FlexPolyline
// This file defines the Encode() function

package flexpolyline

import (
	"math"
	"strings"
)

// Encodes a Polyline to a string following the format specified in
// https://github.com/heremaps/flexible-polyline/blob/master/README.md
func Encode(polyline *Polyline) (string, error) {
	multiplierDegree := polyline.Precision2D().factor()
	multiplierZ := polyline.Precision3D().factor()

	var lastLat, lastLng, lastZ int64
	var builder strings.Builder
	builder.Grow(circaCharsPerPoint(polyline)*len(polyline.Coordinates())+4)
	encodeHeader(polyline, &builder)

	for i := 0; i < len(polyline.Coordinates()); i++ {
		location := polyline.Coordinates()[i]
		lat := int64(math.Round(location.Lat * multiplierDegree))
		encodeScaledValue(lat - lastLat, &builder)
		lastLat = lat

		lng := int64(math.Round(location.Lng * multiplierDegree))
		encodeScaledValue(lng - lastLng, &builder)
		lastLng = lng

		if polyline.Type3D() != Absent {
			z := int64(math.Round(location.ThirdDim * multiplierZ))
			encodeScaledValue(z - lastZ, &builder)
			lastZ = z
		}

	}
	return builder.String(), nil
}

const encodingTable = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

func encodeUint(value uint64, builder *strings.Builder) {
	for ; value > 0x1F; {
		pos := (value & 0x1F) | 0x20
		builder.WriteString(string(encodingTable[pos]))
		value >>= 5
	}
	builder.WriteString(string(encodingTable[value]))
}

func encodeScaledValue(value int64, builder* strings.Builder) {
	uintValue := uint64(value)
	uintValue <<= 1
	if value < 0 {
		uintValue = ^uintValue
	}
	encodeUint(uintValue, builder)
}

func encodeHeader(polyline *Polyline, builder *strings.Builder) {
	headerContent := (uint64(polyline.Precision3D()) << 7) | (uint64(polyline.Type3D()) << 4) | uint64(polyline.Precision2D())
	encodeUint(uint64(FormatVersion), builder)
	encodeUint(headerContent, builder)
}
