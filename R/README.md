
# Flexible Polyline Encoding for R

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/flexpolyline)](https://CRAN.R-project.org/package=flexpolyline)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/last-month/flexpolyline?color=brightgreen)](https://CRAN.R-project.org/package=flexpolyline)
<!-- badges: end -->

The **flexpolyline** R package provides a binding to the
[C++ implementation](https://github.com/heremaps/flexible-polyline/tree/master/cpp)
of the flexible polyline encoding by
[HERE](https://github.com/heremaps/flexible-polyline).

**Note:**
* Decoding gives reliable results up to a precision of 7 digits.
The tests are also limited to this range.
* The order of the coordinates (lng, lat) does not correspond to the original
C++ implementation (lat, lng). This enables simple conversion to `sf` objects,
without reordering the columns.
* The encoding is lossy, this means the encoding process could reduce the
precision of your data.

## Installation

You can install the released version of **flexpolyline**
from [CRAN](https://CRAN.R-project.org/package=flexpolyline) with:

``` r
install.packages("flexpolyline")
```

Install the development version
from [GitHub](https://github.com/munterfinger/flexpolyline) with:

``` r
remotes::install_github("munterfinger/flexpolyline")
```

## C++ binding

Encoding and decoding in R is straight forward by using `encode()` and `decode()`.
These functions are binding to the flexpolyline C++ implementation and reflect
the arguments and return values of their counterparts (`hf::encode_polyline` and
`hf::decode_polyline`):

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
* [Simple Features for R](https://CRAN.R-project.org/package=sf)
* Inspired by the [googlePolylines](https://github.com/SymbolixAU/googlePolylines) package

## License

* The **flexpolyline** R package is licensed under GNU GPL v3.0.
* The C++ implementation by HERE Europe B.V. is licensed under MIT.
