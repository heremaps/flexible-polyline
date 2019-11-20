// Copyright (C) 2019 HERE Europe B.V.
// Licensed under MIT, see full license in LICENSE
// SPDX-License-Identifier: MIT
// License-Filename: LICENSE

package flexpolyline

import (
	"math"
	"testing"
)

const testDataPrecision = 7
var testData2D = []Point{
	{Lat: 50.10228, Lng: 8.69821},
	{Lat: 50.10201, Lng: 8.69567},
	{Lat: 50.10063, Lng: 8.69150},
	{Lat: 50.09878, Lng: 8.68752},
}
var testData3D = []Point {
	{Lat: 50.10228, Lng: 8.69821, ThirdDim: 10},
	{Lat: 50.10201, Lng: 8.69567, ThirdDim: 20},
	{Lat: 50.10063, Lng: 8.69150, ThirdDim: 30},
	{Lat: 50.09878, Lng: 8.68752, ThirdDim: 40},
}

func arePointsEqualToPrecision(actual, expected []Point, precision Precision) bool {
	if len(actual) != len(expected) {return false}
	precisionMultiplier := precision.factor()
	for i := 0; i < len(actual); i++ {
		roundedLatActual := int64(math.Round(actual[i].Lat * precisionMultiplier))
		roundedLatExpected := int64(math.Round(expected[i].Lat * precisionMultiplier))
		roundedLngActual := int64(math.Round(actual[i].Lng * precisionMultiplier))
		roundedLngExpected := int64(math.Round(expected[i].Lng * precisionMultiplier))
		rounded3rdActual := int64(math.Round(actual[i].ThirdDim * precisionMultiplier))
		rounded3rdExpected := int64(math.Round(expected[i].ThirdDim * precisionMultiplier))
		if roundedLatActual != roundedLatExpected || roundedLngActual != roundedLngExpected || rounded3rdActual != rounded3rdExpected{
			return false
		}
	}
	return true
}

func TestDecodeStaticHeader(t *testing.T) {
	polyline := "BFoz5xJ67i1B1B7PzIhaxL7Y"
	result, _, err := decodeHeader(polyline)
	if err != nil {
		t.Errorf("Decode returned error %s", err)
	}
	if result.Precision2D() != 5 || result.Type3D() != 0 || result.Precision3D() != 0 {
		t.Errorf("Decode returned unexpected header %v", result)
	}
}

func TestDecodeStaticHeaderWithAltitude(t *testing.T) {
	polyline := "BlBoz5xJ67i1BU1B7PUzIhaUxL7YU"
	result, _, err := decodeHeader(polyline)
	if err != nil {
		t.Errorf("Decode returned error %s", err)
	}
	if result.Type3D() != Altitude || result.Precision3D() != 0 {
		t.Errorf("Decode returned unexpected header %v", result)
	}
}

func TestDecodeValue(t *testing.T) {
	polyline := "BFoz5xJ67i1B1B7PzIhaxL7Y"
	result, err := Decode(polyline)
	if err != nil {
		t.Errorf("Decode returned error %s", err)
	}
	if !arePointsEqualToPrecision(result.Coordinates(), testData2D, testDataPrecision) {
		t.Errorf("Expected: %v, got: %v", testData2D, result)
	}
}

func TestDecodeValueWithAltitude(t *testing.T) {
	polyline := "BlBoz5xJ67i1BU1B7PUzIhaUxL7YU"
	result, err := Decode(polyline)
	if err != nil {
		t.Errorf("Decode returned error %s", err)
	}
	if !arePointsEqualToPrecision(result.Coordinates(), testData3D, 7) {
		t.Errorf("Expected: %v, got: %v", testData3D, result)
	}
}

func TestDecodeValueEncodedWithDifferent3rdDimPrecisions(t *testing.T) {
	for i := 0.; i <= 15.; i++ {
		toEncode := MustCreatePolyline3D(Altitude, 5, Precision(i), testData3D)
		polyline, _ := Encode(toEncode)
		result, err := Decode(polyline)
		if err != nil {
			t.Errorf("Decode returned error %s", err)
		}
		comparisonPrecision := Precision(math.Min(i, testDataPrecision))
		if !arePointsEqualToPrecision(result.Coordinates(), testData3D, comparisonPrecision) {
			t.Errorf("Precision2D: %f, Expected: %v, got: %v", i, testData3D, result)
		}
	}
}

func TestThirdDimensionFlagWithDifferentValues(t *testing.T) {
	flags := []Type3D{Absent, Level, Altitude, Elevation, Custom1, Custom2}
	for i := 0; i < len(flags); i++ {
		toEncode := MustCreatePolyline3D(flags[i], 5, 0, []Point{{Lat: 0, Lng: 0}})
		polyline, _ := Encode(toEncode)
		thirdDimensionFlag, err := GetThirdDimension(polyline)
		if err != nil {
			t.Errorf("GetThirdDimension returned error %s", err)
		}
		if thirdDimensionFlag != flags[i] {
			t.Errorf("%d Expected: %d, got: %d", i, flags[i], thirdDimensionFlag)
		}
	}
}
