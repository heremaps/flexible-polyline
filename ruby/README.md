# FlexPolyline

This is a ruby implementation of the Flexible Polyline format.

The polyline encoding is a lossy compressed representation of a list of coordinate pairs or
coordinate triples. It achieves that by:

1. Reducing the decimal digits of each value.
2. Encoding only the offset from the previous point.
3. Using variable length for each coordinate delta.
4. Using 64 URL-safe characters to display the result.

## Install

```bash
gem install flexpolyline
```

## Usage

### Encoding

#### `FlexPolyline.encode(iterable, precision: 5, third_dim: FlexPolyline::ABSENT, third_dim_precision: 0)`

Encodes a list (or iterator) of coordinates to the corresponding string representation. See the optional parameters below for further customization. Coordinate order is `(lat, lng[, third_dim])`.
```

**Optional parameters**

* `precision` - Defines how many decimal digits to round latitude and longitude to (ranges from `0` to `15`).
* `third_dim` - Defines the type of the third dimension when present. Possible values are defined in the module: `ALTITUDE`, `LEVEL`, `ELEVATION`, `CUSTOM1` and `CUSTOM2`. The last two values can be used in case your third dimension has a user defined meaning.
* `third_dim_precision` - Defines how many decimal digits to round the third dimension to (ranges from `0` to `15`). This parameter is ignored when `third_dim` is `ABSENT` (default).
* `format` - Defines the output format, `:array` (default) or `:hash`.


#### `FlexPolyline.encode(iterable, precision: 5, third_dim: ABSENT, third_dim_precision: 0, format: :hash)`

Similar to the `encode` function, but accepts a list (or iterator) of dictionaries instead. Required keys are `"lat"` and `"lng"`. If `third_dim` is set, the corresponding key is expected `"alt"`, `"elv"`, `"lvl"`, `"cst1"` or `"cst2"`.


#### Examples

Following is a simple example encoding a 2D poyline with 5 decimal digits of precision:

```ruby
require 'flexpolyline'

example = [
    [50.1022829, 8.6982122],
    [50.1020076, 8.6956695],
    [50.1006313, 8.6914960],
    [50.0987800, 8.6875156],
]

puts FlexPolyline.encode(example)
```

**Output**: `BFoz5xJ67i1B1B7PzIhaxL7Y`.

Another example for the 3D case with altitude as the third coordinate:

```ruby
require 'flexpolyline'

example = [
    [50.1022829, 8.6982122, 10],
    [50.1020076, 8.6956695, 20],
    [50.1006313, 8.6914960, 30],
    [50.0987800, 8.6875156, 40],
]

puts FlexPolyline.encode(example, third_dim: FlexPolyline::ALTITUDE)
```

**Output**: `BlBoz5xJ67i1BU1B7PUzIhaUxL7YU`

### Decoding

#### `FlexPolyline.decode(encoded_string)`

Decodes the passed encoded string and returns a list of arrays `[lat, lng[, third_dim]]`, or hashes `{ lat: _, lng: _[, alt: _] }`

When the format is a hash, the keys `"lat"` and `"lng"` are always present, while the third dimension key depends on the type of third dimension encoded. It can be one of the following: `:alt`, `:elv`, `:lvl`, `:cst1` or `:cst2`.

#### `FlexPolyline.iter_decode(encoded_string)`

Similar to `decode` but returns an Enumerator instead.

#### `FlexPolyline.third_dimension(encoded_string)`

Returns the value corresponding to the third dimension encoded in the string. Possible values are: `FlexPolyline::ABSENT`, `FlexPolyline::ALTITUDE`, `FlexPolyline::LEVEL`, `FlexPolyline::ELEVATION`, `FlexPolyline::CUSTOM1` and `FlexPolyline::CUSTOM2`

#### Examples

Example of decoding of a 2D polyline:

```ruby
require 'flexpolyline'

puts FlexPolyline.decode("BFoz5xJ67i1B1B7PzIhaxL7Y").inspect
```

**Output**:

```ruby
[
    [50.10228, 8.69821],
    [50.10201, 8.69567],
    [50.10063, 8.69150],
    [50.09878, 8.68752]
]
```


Example of decoding dicts from a 3D polyline:

```ruby
require 'flexpolyline'

puts FlexPolyline.decode("BFoz5xJ67i1B1B7PzIhaxL7Y", format: :hash).inspect
```

**Output**:

```ruby
[
    { lat: 50.10228, lng: 8.69821, alt: 10 },
    { lat: 50.10201, lng: 8.69567, alt: 20 },
    { lat: 50.10063, lng: 8.69150, alt: 30 },
    { lat: 50.09878, lng: 8.68752, alt: 40 }
]
```


