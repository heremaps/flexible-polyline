// Copyright (C) 2019 HERE Europe B.V.
// Licensed under MIT, see full license in LICENSE
// SPDX-License-Identifier: MIT
// License-Filename: LICENSE

package flexpolyline

import "testing"

func TestPrecisionIsChecked(t *testing.T) {
	for i := 0; i <= 15; i++ {
		_, err := CreatePolyline(Precision(i), emptyPolyline)
		if err != nil {
			t.Error("Precision2D in allowed range, but returns an error")
		}
	}
	_, err := CreatePolyline(16, emptyPolyline)
	if err == nil {
		t.Error("Precision2D too high, but does not return an error")
	}
}

func TestThirdDimensionFlagIsChecked(t *testing.T) {
	for i := 0; i <= 3; i++ {
		_, err := CreatePolyline3D(Type3D(i), 5, 5, emptyPolyline)
		if err != nil {
			t.Error("Third dimension flag in allowed range, but returns an error")
		}
	}
	for i := 4; i <= 5; i++ {
		_, err := CreatePolyline3D(Type3D(i), 5, 5, emptyPolyline)
		if err == nil {
			t.Error("Third dimension flag has reserved value, but does not return an error")
		}
	}
	for i := 6; i <= 7; i++ {
		_, err := CreatePolyline3D(Type3D(i), 5, 5, emptyPolyline)
		if err != nil {
			t.Error("Third dimension flag in allowed range, but returns an error")
		}
	}
	_, err := CreatePolyline3D(8, 5, 5, emptyPolyline)
	if err == nil {
		t.Error("Third dimension flag too big, but does not return an error")
	}
}

func TestThirdDimensionPrecisionIsChecked(t *testing.T) {
	for i := 0; i <= 15; i++ {
		_, err := CreatePolyline3D(0, 5, Precision(i), emptyPolyline)
		if err != nil {
			t.Error("Third dimension precision in allowed range, but returns an error")
		}
	}
	_, err := CreatePolyline3D(0, 5, 16, emptyPolyline)
	if err == nil {
		t.Error("Third dimension precision too high, but does not return an error")
	}
}

