// Copyright (C) 2019 HERE Europe B.V.
// Licensed under MIT, see full license in LICENSE
// SPDX-License-Identifier: MIT
// License-Filename: LICENSE

package flexpolyline

import (
	"math/rand"
	"testing"
)


var emptyPolyline = []Point{{Lat: 0, Lng: 0}}

var toEncode2D = []Point{
	{Lat: 50.1022829, Lng: 8.6982122},
	{Lat: 50.1020076, Lng: 8.6956695},
	{Lat: 50.1006313, Lng: 8.6914960},
	{Lat: 50.0987800, Lng: 8.6875156},
}

var toEncode3D = []Point{
	{Lat: 50.1022829, Lng: 8.6982122, ThirdDim: 10},
	{Lat: 50.1020076, Lng: 8.6956695, ThirdDim: 20},
	{Lat: 50.1006313, Lng: 8.6914960, ThirdDim: 30},
	{Lat: 50.0987800, Lng: 8.6875156, ThirdDim: 40},
}

var toEncodeLong = []Point{
	{Lat: 52.5199356, Lng: 13.3866272},
	{Lat: 52.5100899, Lng: 13.2816896},
	{Lat: 52.4351807, Lng: 13.1935196},
	{Lat: 52.4107285, Lng: 13.1964502},
	{Lat: 52.38871,   Lng: 13.1557798},
	{Lat: 52.3727798, Lng: 13.1491003},
	{Lat: 52.3737488, Lng: 13.1154604},
	{Lat: 52.3875198, Lng: 13.0872202},
	{Lat: 52.4029388, Lng: 13.0706196},
	{Lat: 52.4105797, Lng: 13.0755529},
}


func testEncoding(t *testing.T, expected string, precision Precision, thirdDimensionFlag Type3D, thirdDimensionPrecision Precision, pointsToEncode []Point) {
	toEncode := MustCreatePolyline3D(thirdDimensionFlag, precision, thirdDimensionPrecision, pointsToEncode)
	result, err := Encode(toEncode)
	checkResult(t, result, expected, err)
}

func checkResult(t *testing.T, expected string, result string, err error) {
	if err != nil {
		t.Errorf("Encode returned error %s", err)
	}
	if result != expected {
		t.Errorf("Expected: %s, got: %s", expected, result)
	}
}

func TestEncodeValue(t *testing.T) {
	expected := "BFoz5xJ67i1B1B7PzIhaxL7Y"
	testEncoding(t, expected, 5, Absent, 0, toEncode2D)
}

func TestAltitude(t *testing.T) {
	expected := "BlBoz5xJ67i1BU1B7PUzIhaUxL7YU"
	testEncoding(t, expected, 5, Altitude, 0, toEncode3D)
}

func TestLongerPolyline(t *testing.T) {
	expected := "BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e"
	testEncoding(t, expected, 5, Absent, 0, toEncodeLong)
}

func TestAsMethod(t *testing.T) {
	expected := "BFoz5xJ67i1B1B7PzIhaxL7Y"
	result, err := MustCreatePolyline(5, toEncode2D).Encode()
	checkResult(t, result, expected, err)
	expected = "BlBoz5xJ67i1BU1B7PUzIhaUxL7YU"
	result, err = MustCreatePolyline3D(Altitude, 5, 0, toEncode3D).Encode()
	checkResult(t, result, expected, err)
	expected = "BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e"
	result, err = MustCreatePolyline(5, toEncodeLong).Encode()
	checkResult(t, result, expected, err)
}

func BenchmarkEncode(b *testing.B) {
	points := buildPoints(b.N)
	polyline := MustCreatePolyline(4, points)

	b.ResetTimer()
	_, err := Encode(polyline)
	if err != nil {
		b.Fail()
	}
}

func buildPoints(n int) []Point {
	base := Point{Lat: 50, Lng: 8}

	points := make([]Point, 0, n)
	for i := 0; i < n; i++ {
		points = append(points, Point{
			Lat: base.Lat + 10*rand.Float64(),
			Lng: base.Lat + 10*rand.Float64(),
		})
	}

	return points
}
