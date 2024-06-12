# Copyright (C) 2019 HERE Europe B.V.
# Licensed under MIT, see full license in LICENSE
# SPDX-License-Identifier: MIT
# License-Filename: LICENSE

import unittest

import flexpolyline as fp


class TestFlexPolyline(unittest.TestCase):
    def test_encode1(self):
        input = [
            (50.1022829, 8.6982122),
            (50.1020076, 8.6956695),
            (50.1006313, 8.6914960),
            (50.0987800, 8.6875156),
        ]
        res = fp.encode(input)
        expected = "BFoz5xJ67i1B1B7PzIhaxL7Y"

        self.assertEqual(res, expected)

    def test_dict_encode(self):
        input = [
            {'lat': 50.1022829, 'lng': 8.6982122},
            {'lat': 50.1020076, 'lng': 8.6956695},
            {'lat': 50.1006313, 'lng': 8.6914960},
            {'lat': 50.0987800, 'lng': 8.6875156}
        ]
        res = fp.dict_encode(input)
        expected = "BFoz5xJ67i1B1B7PzIhaxL7Y"

        self.assertEqual(res, expected)

    def test_encode_alt(self):
        input = [
            (50.1022829, 8.6982122, 10),
            (50.1020076, 8.6956695, 20),
            (50.1006313, 8.6914960, 30),
            (50.0987800, 8.6875156, 40),
        ]
        res = fp.encode(input, third_dim=fp.ALTITUDE)
        expected = "BlBoz5xJ67i1BU1B7PUzIhaUxL7YU"

        self.assertEqual(res, expected)

    def test_encode2(self):
        input = [
            [52.5199356, 13.3866272],
            [52.5100899, 13.2816896],
            [52.4351807, 13.1935196],
            [52.4107285, 13.1964502],
            [52.38871, 13.1557798],
            [52.3727798, 13.1491003],
            [52.3737488, 13.1154604],
            [52.3875198, 13.0872202],
            [52.4029388, 13.0706196],
            [52.4105797, 13.0755529],
        ]

        res = fp.encode(input)
        expected = "BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e"

        self.assertEqual(res, expected)

    def assertAlmostEqualSequence(self, first, second, places=None):
        for row1, row2 in zip(first, second):
            for a, b in zip(row1, row2):
                self.assertAlmostEqual(a, b, places=places)

    def assertAlmostEqualDictSequence(self, first, second, places=None):
        for row1, row2 in zip(first, second):
            for k, a in row1.items():
                self.assertAlmostEqual(a, row2[k], places=places)

    def test_iter_decode1(self):
        polyline = list(p for p in fp.iter_decode("BFoz5xJ67i1B1B7PzIhaxL7Y"))
        expected = [
            (50.10228, 8.69821),
            (50.10201, 8.69567),
            (50.10063, 8.69150),
            (50.09878, 8.68752)
        ]
        self.assertAlmostEqualSequence(polyline, expected, places=7)

    def test_iter_decode_fails(self):
        with self.assertRaises(ValueError):
            list(fp.iter_decode("BFoz5xJ67i1B1B7PzIhaxL7"))

        with self.assertRaises(ValueError):
            list(fp.iter_decode("CFoz5xJ67i1B1B7PzIhaxL7"))

    def test_dict_decode_2d(self):
        polyline = fp.dict_decode("BFoz5xJ67i1B1B7PzIhaxL7Y")
        expected = [
            {'lat': 50.10228, 'lng': 8.69821},
            {'lat': 50.10201, 'lng': 8.69567},
            {'lat': 50.10063, 'lng': 8.69150},
            {'lat': 50.09878, 'lng': 8.68752}
        ]
        self.assertAlmostEqualDictSequence(polyline, expected, places=7)

    def test_dict_decode_3d(self):
        polyline = fp.dict_decode("BlBoz5xJ67i1BU1B7PUzIhaUxL7YU")
        expected = [
            {'lat': 50.10228, 'lng': 8.69821, 'alt': 10},
            {'lat': 50.10201, 'lng': 8.69567, 'alt': 20},
            {'lat': 50.10063, 'lng': 8.69150, 'alt': 30},
            {'lat': 50.09878, 'lng': 8.68752, 'alt': 40}
        ]
        self.assertAlmostEqualDictSequence(polyline, expected, places=7)

    def test_iter_decode2(self):
        polyline = list(fp.iter_decode("BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e"))
        expected = [
            (52.51994, 13.38663),
            (52.51009, 13.28169),
            (52.43518, 13.19352),
            (52.41073, 13.19645),
            (52.38871, 13.15578),
            (52.37278, 13.14910),
            (52.37375, 13.11546),
            (52.38752, 13.08722),
            (52.40294, 13.07062),
            (52.41058, 13.07555),
        ]
        self.assertAlmostEqualSequence(polyline, expected, places=7)

    def test_get_third_dimension(self):
        self.assertEqual(fp.get_third_dimension("BFoz5xJ67i1BU"), fp.ABSENT)
        self.assertEqual(fp.get_third_dimension("BVoz5xJ67i1BU"), fp.LEVEL)
        self.assertEqual(fp.get_third_dimension("BlBoz5xJ67i1BU"), fp.ALTITUDE)
        self.assertEqual(fp.get_third_dimension("B1Boz5xJ67i1BU"), fp.ELEVATION)


if __name__ == '__main__':
    unittest.main()