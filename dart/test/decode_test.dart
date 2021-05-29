import 'package:test/test.dart';

import '../lib/flexible_polyline.dart';

void main() {
  test('decode polyline - null safety', () {
    final encoded = "BFoz5xJ67i1B1B7PzIhaxL7Y";
    final coords = FlexiblePolyline.decode(encoded);
    expect(coords.isNotEmpty, true);
  });
}
