
# Flexible Polyline Encoding for R <img src="man/figures/logo.png" align="right" alt="" width="120" />

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/flexpolyline)](https://CRAN.R-project.org/package=flexpolyline)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/last-month/flexpolyline?color=brightgreen)](https://CRAN.R-project.org/package=flexpolyline)
[![R build status](https://github.com/munterfinger/flexpolyline/workflows/R-CMD-check/badge.svg)](https://github.com/munterfinger/flexpolyline/actions)
[![pkgdown](https://github.com/munterfinger/flexpolyline/workflows/pkgdown/badge.svg)](https://github.com/munterfinger/flexpolyline/actions)
[![Codecov test coverage](https://codecov.io/gh/munterfinger/flexpolyline/branch/master/graph/badge.svg)](https://codecov.io/gh/munterfinger/flexpolyline?branch=master)
<!-- badges: end -->

The **flexpolyline** R package provides a binding to the
[C++ implementation](https://github.com/heremaps/flexible-polyline/tree/master/cpp) of the
flexible polyline encoding by [HERE](https://github.com/heremaps/flexible-polyline).
The flexible polyline encoding is a lossy compressed representation of a list of
coordinate pairs or coordinate triples. The encoding is achieved by:
(1) Reducing the decimal digits of each value;
(2) encoding only the offset from the previous point;
(3) using variable length for each coordinate delta; and
(4) using 64 URL-safe characters to display the result.
The flexible polyline encoding is a variant of the [Encoded Polyline Algorithm Format](https://developers.google.com/maps/documentation/utilities/polylinealgorithm) by Google.

**Note:**

* Decoding gives reliable results up to a precision of 7 digits.
The tests are also limited to this range.
* The order of the coordinates (lng, lat) does not correspond to the original C++ implementation (lat, lng).
This enables simple conversion to `sf` objects, without reordering the columns.
* The encoding is lossy, this means the encoding process could reduce the precision of your data.

## Installation

You can install the released version of **flexpolyline** from [CRAN](https://CRAN.R-project.org/package=flexpolyline) with:

``` r
install.packages("flexpolyline")
```

Install the development version from [GitHub](https://github.com/munterfinger/flexpolyline) with:

``` r
remotes::install_github("munterfinger/flexpolyline")
```

## C++ binding

Encoding and decoding in R is straight forward by using `encode()` and `decode()`.
These functions are binding to the flexpolyline C++ implementation and reflect the arguments and return values of their counterparts (`hf::encode_polyline` and `hf::decode_polyline`):

``` r
line <- matrix(
  c(8.69821, 50.10228, 10,
    8.69567, 50.10201, 20,
    8.69150, 50.10063, 30,
    8.68752, 50.09878, 40),
  ncol = 3, byrow = TRUE
)

encode(line)

decode("BlBoz5xJ67i1BU1B7PUzIhaUxL7YU")
```

## Simple feature support
A common way to deal with spatial data in R is the
[sf](https://CRAN.R-project.org/package=sf) package, which is
built on the concept of simple features. The functions `encode_sf()` and
`decode_sf()` provide an interface that support the encoding of sf objects:

``` r
sfg <- sf::st_linestring(line, dim = "XYZ")

encode_sf(sfg)

decode_sf("BlBoz5xJ67i1BU1B7PUzIhaUxL7YU")
```

## References

* [Flexible Polyline Encoding by HERE](https://github.com/heremaps/flexible-polyline)
* [Encoded Polyline Algorithm Format](https://developers.google.com/maps/documentation/utilities/polylinealgorithm)
* [Simple Features for R](https://CRAN.R-project.org/package=sf)
* Inspired by the [googlePolylines](https://github.com/SymbolixAU/googlePolylines) package

## License

* The **flexpolyline** R package is licensed under GNU GPL v3.0.
* The C++ implementation by HERE Europe B.V. is licensed under MIT.
