import 'dart:math';

import 'package:flexible_polyline/flexible_polyline.dart';
import 'package:tuple/tuple.dart';

///
/// Stateful instance for encoding and decoding on a sequence of Coordinates
/// part of a request.
/// Instance should be specific to type of coordinates (e.g. Lat, Lng)
/// so that specific type delta is computed for encoding.
/// Lat0 Lng0 3rd0 (Lat1-Lat0) (Lng1-Lng0) (3rdDim1-3rdDim0)
///
class Converter {
  final int precision;
  int multiplier;
  int lastValue = 0;

  Converter(this.precision) {
    multiplier = pow(10, precision);
  }

  // Returns decoded int, new index in tuple
  static Tuple2<int, int> decodeUnsignedVarint(
      List<String> encoded, int index) {
    int shift = 0;
    int delta = 0;
    int value;

    while (index < encoded.length) {
      value = decodeChar(encoded[index]);
      if (value < 0) {
        throw ArgumentError("Invalid encoding");
      }
      index++;
      delta |= (value & 0x1F) << shift;
      if ((value & 0x20) == 0) {
        return Tuple2(delta, index);
      } else {
        shift += 5;
      }
    }

    if (shift > 0) {
      throw ArgumentError("Invalid encoding");
    }
    return Tuple2(0, index);
  }

  // Decode single coordinate (say lat|lng|z) starting at index
  // Returns decoded coordinate, new index in tuple
  Tuple2<double, int> decodeValue(List<String> encoded, int index) {
    final Tuple2<int, int> result =
        decodeUnsignedVarint(encoded, index);
    double coordinate = 0;
    int delta = result.item1;
    if ((delta & 1) != 0) {
      delta = ~delta;
    }
    delta = delta >> 1;
    lastValue += delta;
    coordinate = lastValue / multiplier;
    return Tuple2(coordinate, result.item2);
  }

  static String encodeUnsignedVarint(int value) {
    String result = '';
    while (value > 0x1F) {
      int pos = ((value & 0x1F) | 0x20);
      result += FlexiblePolyline.encodingTable[pos];
      value >>= 5;
    }
    result += (FlexiblePolyline.encodingTable[value]);
    return result;
  }

  // Encode a single double to a string
  String encodeValue(double value) {
    /*
     * Round-half-up
     * round(-1.4) --> -1
     * round(-1.5) --> -2
     * round(-2.5) --> -3
     */
    final double scaledValue = (value * multiplier).abs().round() * value.sign;
    int delta = (scaledValue - lastValue).toInt();
    final bool negative = delta < 0;

    lastValue = scaledValue.toInt();

    // make room on lowest bit
    delta <<= 1;

    // invert bits if the value is negative
    if (negative) {
      delta = ~delta;
    }
    return encodeUnsignedVarint(delta);
  }

  //Decode a single char to the corresponding value
  static int decodeChar(String charValue) {
    final int pos = charValue.codeUnitAt(0) - 45;
    if (pos < 0 || pos > 77) {
      return -1;
    }
    return FlexiblePolyline.decodingTable[pos];
  }
}
