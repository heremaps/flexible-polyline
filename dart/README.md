# Flexible Polyline encoder/decoder for Dart

The flexible polyline encoding is a lossy compressed representation of a list of coordinate pairs or
coordinate triples.

For more information see the [github repo].

# Usage

## Encoding
```
List<LatLngZ> pairs = List<LatLngZ>();
pairs.add(LatLngZ(50.1022829, 8.6982122));
pairs.add(LatLngZ(50.1020076, 8.6956695));
pairs.add(LatLngZ(50.1006313, 8.6914960));
pairs.add(LatLngZ(50.0987800, 8.6875156));

String encoded = FlexiblePolyline.encode(pairs /* coordinates */,
	5 /* coordinate precision */, ThirdDimension.ABSENT /* third dimension */,
	0 /* third dimension precision */);

// encoded == 'BFoz5xJ67i1B1B7PzIhaxL7Y'
```

## Decoding
```
List<LatLngZ> decoded =
    FlexiblePolyline.decode("BFoz5xJ67i1B1B7PzIhaxL7Y");

/*
decoded == [
	LatLngZ(50.10228, 8.69821),
	LatLngZ(50.10201, 8.69567),
	LatLngZ(50.10063, 8.69150),
	LatLngZ(50.09878, 8.68752),
]
*/
```

[github repo]: https://github.com/heremaps/flexible-polyline