// Copyright (C) 2019 HERE Europe B.V.
// Licensed under MIT, see full license in LICENSE
// SPDX-License-Identifier: MIT
// License-Filename: LICENSE

// Package flexpolyline contains tools to encode and decode FlexPolylines
// This file defines data structures to store FlexPolylines

package flexpolyline

import (
	"fmt"
	"math"
)

// FlexPolyline specification version
const FormatVersion uint = 1

// Number of decimal digits after the comma
type Precision uint8

func (p Precision) factor() float64 {
	return math.Pow10(int(p))
}

// Whether the third dimension is present and what meaning it has
type Type3D uint8

const (
	Absent Type3D = iota
	Level
	Altitude
	Elevation
	Reserved1
	Reserved2
	Custom1
	Custom2
)

// A point on the Earth surface with an optional third dimension
type Point struct {
	Lat      float64
	Lng      float64
	ThirdDim float64
}

// Structure to store FlexPolyline
type Polyline struct {
	coordinates []Point
	precision2D Precision
	precision3D Precision
	type3D      Type3D
}

func (p* Polyline) Coordinates() []Point {
	return p.coordinates
}

func (p* Polyline) Precision2D() Precision {
	return p.precision2D
}

func (p* Polyline) Precision3D() Precision {
	return p.precision3D
}

func (p* Polyline) Type3D() Type3D {
	return p.type3D
}

// Creates a two dimensional FlexPolyline
func CreatePolyline(precision Precision, points []Point) (*Polyline, error) {
	err := checkArgs(Absent, precision, 0)
	if err != nil {
		return nil, err
	}
	return &Polyline{
		coordinates: points,
		precision2D: precision,
	}, nil
}

// Creates a two dimensional FlexPolyline. Panics if arguments are bad.
func MustCreatePolyline(precision Precision, points []Point) *Polyline {
	p, err := CreatePolyline(precision, points)
	if err != nil {
		panic(err)
	}
	return p
}

// Creates a three dimensional FlexPolyline
func CreatePolyline3D(type3D Type3D, precision2D, precision3D Precision, points []Point) (*Polyline, error) {
	err := checkArgs(type3D, precision2D, precision3D)
	if err != nil {
		return nil, err
	}
	return &Polyline{
		coordinates: points,
		precision2D: precision2D,
		precision3D: precision3D,
		type3D:      type3D,
	}, nil
}

// Creates a three dimensional FlexPolyline. Panics if arguments are bad.
func MustCreatePolyline3D(type3D Type3D, precision2D, precision3D Precision, points []Point) *Polyline {
	p, err := CreatePolyline3D(type3D, precision2D, precision3D, points)
	if err != nil {
		panic(err)
	}
	return p
}

// Encodes a Polyline to a string
func (p *Polyline) Encode() (string, error) {
	return Encode(p)
}

func circaCharsPerPoint(header *Polyline) int {
	const assumedMaxThirdDimValue = 10000.
	circaNumChars := 2.*math.Log(360.*header.Precision2D().factor())/math.Log(64)
	if header.Type3D() != Absent {
		circaNumChars += math.Log(assumedMaxThirdDimValue*header.Precision3D().factor())/math.Log(64)
	}
	return int(math.Ceil(circaNumChars))
}


func checkArgs(type3D Type3D, precision2D, precision3D Precision) error {
	if precision2D > 15 {
		return fmt.Errorf("Precision2D %d > max Precision2D (15)", precision2D)
	}
	if type3D > Custom2 {
		return fmt.Errorf("Type3D %d > max Type3D (7)", type3D)
	}
	if type3D == Reserved1 || type3D == Reserved2 {
		return fmt.Errorf("Type3D %d reserved for future use", type3D)
	}
	if precision3D > 15 {
		return fmt.Errorf("Precision3D %d > max Precision3D (15)", precision3D)
	}
	return nil
}
