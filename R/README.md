
# Flexible Polyline Encoding for R

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/flexpolyline)](https://CRAN.R-project.org/package=flexpolyline)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/last-month/flexpolyline?color=brightgreen)](https://CRAN.R-project.org/package=flexpolyline)
[![R build status](https://github.com/munterfinger/flexpolyline/workflows/R-CMD-check/badge.svg)](https://github.com/munterfinger/flexpolyline/actions)
[![Codecov test coverage](https://codecov.io/gh/munterfinger/flexpolyline/branch/master/graph/badge.svg)](https://codecov.io/gh/munterfinger/flexpolyline?branch=master)
<!-- badges: end -->

The **[flexpolyline](https://CRAN.R-project.org/package=flexpolyline)** R package
provides a binding to the
[C++ implementation](https://github.com/heremaps/flexible-polyline/tree/master/cpp)
of the flexible polyline encoding by HERE. The package is designed to
interface with simple feature objects of the
**[sf](https://CRAN.R-project.org/package=sf)** package. which are a common way to deal with spatial data in R.
For detailed
information on how to encode and decode polylines in R see the package
[documentation](https://munterfinger.github.io/flexpolyline/index.html) or its
[repository](https://github.com/munterfinger/flexpolyline) on GitHub.

**Note:**
* The order of the coordinates (lng, lat) does not correspond to the original
C++ implementation (lat, lng). This enables simple conversion to simple feature
objects without reordering the columns.
* Decoding gives reliable results up to a precision of 7 digits.
The package tests are also limited to this range.

## Get started

Install the released version of **flexpolyline** from CRAN with:

``` r
install.packages("flexpolyline")
```

Encoding and decoding in R is straight forward by using `encode()` and `decode()`.
These functions are binding to the flexpolyline C++ implementation and reflect
the arguments and return values of their counterparts (`hf::encode_polyline` and
`hf::decode_polyline`):

``` r
library(flexpolyline)

line <- matrix(
  c(8.69821, 50.10228, 10,
    8.69567, 50.10201, 20,
    8.69150, 50.10063, 30,
    8.68752, 50.09878, 40),
  ncol = 3, byrow = TRUE
)

encode(line)
#> [1] "B1Voz5xJ67i1Bgkh9B1B7Pgkh9BzIhagkh9BxL7Ygkh9B"

decode("B1Voz5xJ67i1Bgkh9B1B7Pgkh9BzIhagkh9BxL7Ygkh9B")
#>          LNG      LAT ELEVATION
#> [1,] 8.69821 50.10228        10
#> [2,] 8.69567 50.10201        20
#> [3,] 8.69150 50.10063        30
#> [4,] 8.68752 50.09878        40
```

A common way to deal with spatial data in R is the **sf** package, which is
built on the concept of simple features. The functions `encode_sf()` and
`decode_sf()` provide an interface that support the encoding of sf objects with
geometry type `LINESTRING`:

``` r
sfg <- sf::st_linestring(line, dim = "XYZ")
print(sfg)
#> LINESTRING Z (8.69821 50.10228 10, 8.69567 50.10201 20, 8.6915 50.10063 3...

encode_sf(sfg)
#> [1] "B1Voz5xJ67i1Bgkh9B1B7Pgkh9BzIhagkh9BxL7Ygkh9B"

decode_sf("B1Voz5xJ67i1Bgkh9B1B7Pgkh9BzIhagkh9BxL7Ygkh9B", crs = 4326)
#> Simple feature collection with 1 feature and 2 fields
#> geometry type:  LINESTRING
#> dimension:      XYZ
#> bbox:           xmin: 8.68752 ymin: 50.09878 xmax: 8.69821 ymax: 50.10228
#> z_range:        zmin: 10 zmax: 40
#> geographic CRS: WGS 84
#>   id      dim3                       geometry
#> 1  1 ELEVATION LINESTRING Z (8.69821 50.10...
```

## References

* [Flexible Polyline Encoding](https://github.com/heremaps/flexible-polyline)
* [flexpolyline R package](https://github.com/munterfinger/flexpolyline)
* [Simple Features for R](https://CRAN.R-project.org/package=sf)

## License

* The C++ implementation of the flexible polyline encoding by HERE Europe B.V.
is licensed under MIT.
* The **flexpolyline** R package is licensed under GNU GPL v3.0.
