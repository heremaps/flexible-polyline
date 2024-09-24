# Flexible Polyline encoding

The flexible polyline encoding is a lossy compressed representation of a list of coordinate
pairs or coordinate triples. It achieves that by:

1. Reducing the decimal digits of each value.
2. Encoding only the offset from the previous point.
3. Using variable length for each coordinate delta.
4. Using 64 URL-safe characters to display the result.

The encoding is a variant of [Encoded Polyline Algorithm Format]. The advantage of this encoding
over the original are the following:

* Output string is composed by only URL-safe characters, i.e. may be used without URL encoding
  as query parameters.
* Floating point precision is configurable: This allows to represent coordinates with precision
  up to microns (5 decimal places allow meter precision only).
* It allows to encode a 3rd dimension with a given precision, which may be a level, altitude,
  elevation or some other custom value.

## Specification

See [Specification].

[Encoded Polyline Algorithm Format]: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
[Specification]: https://github.com/heremaps/flexible-polyline#specifications

## Example

```rust
use flexpolyline::{Polyline, Precision};

// encode
let coordinates = vec![
    (50.1022829, 8.6982122),
    (50.1020076, 8.6956695),
    (50.1006313, 8.6914960),
    (50.0987800, 8.6875156),
];

let polyline = Polyline::Data2d {
    coordinates,
    precision2d: Precision::Digits5,
};

let encoded = polyline.encode().unwrap();
assert_eq!(encoded, "BFoz5xJ67i1B1B7PzIhaxL7Y");

// decode
let decoded = Polyline::decode("BFoz5xJ67i1B1B7PzIhaxL7Y").unwrap();
assert_eq!(
    decoded,
    Polyline::Data2d {
        coordinates: vec![
            (50.10228, 8.69821),
            (50.10201, 8.69567),
            (50.10063, 8.69150),
            (50.09878, 8.68752)
        ],
        precision2d: Precision::Digits5
    }
);
```