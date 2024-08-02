# Flexible Polyline encoding

The flexible polyline encoding is a lossy compressed representation of a list of coordinate pairs or
coordinate triples.

For a detailed description, please visit [GitHub](https://github.com/heremaps/flexible-polyline/).

## Sample usage

To encode a polyline:

```js
import { encode } from '@here/flexpolyline';

// Define an array of coordinates
const coordinates = [
    [50.1022829, 8.6982122],
    [50.1020076, 8.6956695],
    [50.1006313, 8.6914960],
    [50.0987800, 8.6875156]
];

// encode the polyline
const flexPolyline = encode({ polyline: coordinates });

// The output should be the flex polyline "BFoz5xJ67i1B1B7PzIhaxL7Y"
console.log(flexPolyline);
```

To decode a polyline:

```js
import { decode } from '@here/flexpolyline';

// Use "decode" to get back the coordinates from the sample above
const decoded = decode(flexPolyline);
console.log(decoded.polyline);
```

### CLI

The package comes with a simple CLI to encode / decode flexible polylines.

Example usage:

```sh
# to encode:
echo '[[50.1022829, 8.6982122],[50.1020076, 8.6956695],[50.1006313, 8.6914960],[50.0987800, 8.6875156]]' | npx @here/flexpolyline

# to decode:
echo -n 'BFoz5xJ67i1B1B7PzIhaxL7Y' | npx @here/flexpolyline decode
```

## License

Copyright (C) 2024 HERE Europe B.V.

See the [LICENSE](https://github.com/heremaps/flexible-polyline/blob/master/LICENSE) file in the root of this project for license details.
