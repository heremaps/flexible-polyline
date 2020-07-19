## Testing

```
composer test
```

## Usage

### Decode

FlexiblePolyline::decode(string $encoded): array

```
$data = FlexiblePolyline::decode('BlBoz5xJ67i1BU1B7PUzIhaUxL7YU');
/** $data:
[
    'precision' => 5,
    'thirdDim' => 2,
    'thirdDimPrecision' => 0,
    'polyline' => [
        [50.10228, 8.69821, 10],
        [50.10201, 8.69567, 20],
        [50.10063, 8.6915, 30],
        [50.09878, 8.68752, 40]
    ]
]
*/
```

### Encode

FlexiblePolyline::encode(array $coordinates [, int $precision = null, int $thirdDim = null, int $thirdDimPrecision = 0]): string

```
$encoded = FlexiblePolyline::encode([
    [50.10228, 8.69821, 10],
    [50.10201, 8.69567, 20],
    [50.10063, 8.6915, 30],
    [50.09878, 8.68752, 40]
], 5, 2, 0);
/** $encoded:
BlBoz5xJ67i1BU1B7PUzIhaUxL7YU
*/
```

### Third Dimension

FlexiblePolyline::getThirdDimension(string $encoded): int

```
$thirdDimension = FlexiblePolyline::getThirdDimension('BVoz5xJ67i1BU')
/** $thirdDimension:
1
*/
```