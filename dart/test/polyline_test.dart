import 'dart:convert';
import 'dart:io' show Platform, File;

import 'package:flexible_polyline/converter.dart';
import 'package:flexible_polyline/flexible_polyline.dart';
import 'package:flexible_polyline/latlngz.dart';
import "package:path/path.dart" show dirname, join;
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

void main() {
  test('testInvalidCoordinates', () {
    //Null coordinates
    expect(() => FlexiblePolyline.encode(null, 5, ThirdDimension.ABSENT, 0),
        throwsArgumentError);

    //Empty coordinates list test
    expect(
        () => FlexiblePolyline.encode(
            List<LatLngZ>(), 5, ThirdDimension.ABSENT, 0),
        throwsArgumentError);
  });

  test('testInvalidThirdDimension', () {
    List<LatLngZ> pairs = List<LatLngZ>();
    pairs.add(LatLngZ(50.1022829, 8.6982122));
    ThirdDimension invalid = null;

    //Invalid Third Dimension
    expect(() => FlexiblePolyline.encode(pairs, 5, invalid, 0),
        throwsArgumentError);
  });

  test('testConvertValue', () {
    Converter conv = Converter(5);
    String result = conv.encodeValue(-179.98321);
    expect(result, equals("h_wqiB"));
  });

  test('testSimpleLatLngEncoding', () {
    List<LatLngZ> pairs = List<LatLngZ>();
    pairs.add(LatLngZ(50.1022829, 8.6982122));
    pairs.add(LatLngZ(50.1020076, 8.6956695));
    pairs.add(LatLngZ(50.1006313, 8.6914960));
    pairs.add(LatLngZ(50.0987800, 8.6875156));

    String expected = "BFoz5xJ67i1B1B7PzIhaxL7Y";
    String computed =
        FlexiblePolyline.encode(pairs, 5, ThirdDimension.ABSENT, 0);
    expect(computed, expected);
  });

  test('testComplexLatLngEncoding', () {
    List<LatLngZ> pairs = List<LatLngZ>();
    pairs.add(LatLngZ(52.5199356, 13.3866272));
    pairs.add(LatLngZ(52.5100899, 13.2816896));
    pairs.add(LatLngZ(52.4351807, 13.1935196));
    pairs.add(LatLngZ(52.4107285, 13.1964502));
    pairs.add(LatLngZ(52.38871, 13.1557798));
    pairs.add(LatLngZ(52.3727798, 13.1491003));
    pairs.add(LatLngZ(52.3737488, 13.1154604));
    pairs.add(LatLngZ(52.3875198, 13.0872202));
    pairs.add(LatLngZ(52.4029388, 13.0706196));
    pairs.add(LatLngZ(52.4105797, 13.0755529));

    String expected =
        "BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e";
    String computed =
        FlexiblePolyline.encode(pairs, 5, ThirdDimension.ABSENT, 0);
    expect(computed, expected);
  });

  test('testLatLngZEncode', () {
    List<LatLngZ> tuples = List<LatLngZ>();
    tuples.add(LatLngZ(50.1022829, 8.6982122, 10));
    tuples.add(LatLngZ(50.1020076, 8.6956695, 20));
    tuples.add(LatLngZ(50.1006313, 8.6914960, 30));
    tuples.add(LatLngZ(50.0987800, 8.6875156, 40));

    String expected = "BlBoz5xJ67i1BU1B7PUzIhaUxL7YU";
    String computed =
        FlexiblePolyline.encode(tuples, 5, ThirdDimension.ALTITUDE, 0);
    expect(computed, expected);
  });

  /********** Decoder test starts ***************/
  test('testInvalidEncoderInput', () {
    //Null coordinates
    expect(() => FlexiblePolyline.decode(null), throwsArgumentError);

    //Empty coordinates list test
    expect(() => FlexiblePolyline.decode(""), throwsArgumentError);
  });

  test('testThirdDimension', () {
    expect(FlexiblePolyline.getThirdDimension("BFoz5xJ67i1BU".split('')),
        equals(ThirdDimension.ABSENT));
    expect(FlexiblePolyline.getThirdDimension("BVoz5xJ67i1BU".split('')),
        equals(ThirdDimension.LEVEL));
    expect(FlexiblePolyline.getThirdDimension("BlBoz5xJ67i1BU".split('')),
        equals(ThirdDimension.ALTITUDE));
    expect(FlexiblePolyline.getThirdDimension("B1Boz5xJ67i1BU".split('')),
        equals(ThirdDimension.ELEVATION));
  });

  test('testDecodeConvertValue', () {
    final encoded = "h_wqiB".split('');
    double expected = -179.98321;
    Converter conv = new Converter(5);
    Tuple2<double, int> result = conv.decodeValue(encoded, 0);
    expect(result.item1, expected);
  });

  test('testSimpleLatLngDecoding', () {
    List<LatLngZ> computed =
        FlexiblePolyline.decode("BFoz5xJ67i1B1B7PzIhaxL7Y");
    List<LatLngZ> expected = List<LatLngZ>();
    expected.add(LatLngZ(50.10228, 8.69821));
    expected.add(LatLngZ(50.10201, 8.69567));
    expected.add(LatLngZ(50.10063, 8.69150));
    expected.add(LatLngZ(50.09878, 8.68752));

    expect(computed, orderedEquals(expected));
  });

  test('testComplexLatLngDecoding', () {
    List<LatLngZ> computed = FlexiblePolyline.decode(
        "BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e");

    List<LatLngZ> expected = List<LatLngZ>();
    expected.add(LatLngZ(52.51994, 13.38663));
    expected.add(LatLngZ(52.51009, 13.28169));
    expected.add(LatLngZ(52.43518, 13.19352));
    expected.add(LatLngZ(52.41073, 13.19645));
    expected.add(LatLngZ(52.38871, 13.15578));
    expected.add(LatLngZ(52.37278, 13.14910));
    expected.add(LatLngZ(52.37375, 13.11546));
    expected.add(LatLngZ(52.38752, 13.08722));
    expected.add(LatLngZ(52.40294, 13.07062));
    expected.add(LatLngZ(52.41058, 13.07555));

    expect(computed, orderedEquals(expected));
  });

  test('testLatLngZDecode', () {
    List<LatLngZ> computed =
        FlexiblePolyline.decode("BlBoz5xJ67i1BU1B7PUzIhaUxL7YU");
    List<LatLngZ> expected = List<LatLngZ>();

    expected.add(LatLngZ(50.10228, 8.69821, 10));
    expected.add(LatLngZ(50.10201, 8.69567, 20));
    expected.add(LatLngZ(50.10063, 8.69150, 30));
    expected.add(LatLngZ(50.09878, 8.68752, 40));

    expect(computed, orderedEquals(expected));
  });

  test('encodingSmokeTest', () {
    List<String> input = List<String>();
    final inputFile =
        File(join(dirname(Platform.script.path), 'res/original.txt'));
    Stream<List<int>> inputStream = inputFile.openRead();
    inputStream
        .transform(utf8.decoder) // Decode bytes to UTF-8.
        .transform(LineSplitter()) // Convert stream to individual lines.
        .listen((String line) {
      // Process results.
      input.add(line);
    }, onError: (e) {
      print(e.toString());
    });

    List<String> encoded = List<String>();
    final encodedFile =
        File(join(dirname(Platform.script.path), 'res/encoded.txt'));
    Stream<List<int>> encodedStream = encodedFile.openRead();
    encodedStream
        .transform(utf8.decoder) // Decode bytes to UTF-8.
        .transform(LineSplitter()) // Convert stream to individual lines.
        .listen((String line) {
      // Process results.
      encoded.add(line);
    }, onError: (e) {
      print(e.toString());
    });

    // Assert both files have the same number of lines before comparing data.
    expect(input.length, equals(encoded.length));

    for (int i = 0; i < input.length; i++) {
      int precision = 0;
      int thirdDimPrecision = 0;
      bool hasThirdDimension = false;
      ThirdDimension thirdDimension = ThirdDimension.ABSENT;
      String inputLine = input[i].trim();
      String encodedLine = encoded[i].trim();

      //File parsing
      List<String> inputs =
          inputLine.substring(1, inputLine.length - 1).split(";");
      List<String> meta =
          inputs[0].trim().substring(1, inputs[0].trim().length - 1).split(",");
      precision = int.parse(meta[0]);

      if (meta.length > 1) {
        thirdDimPrecision = int.parse(meta[1].trim());
        thirdDimension = ThirdDimension.values[int.parse(meta[2].trim())];
        hasThirdDimension = true;
      }
      List<LatLngZ> latLngZs = extractLatLngZ(inputs[1], hasThirdDimension);
      String encodedComputed = FlexiblePolyline.encode(
          latLngZs, precision, thirdDimension, thirdDimPrecision);
      String encodedExpected = encodedLine;
      expect(encodedComputed, encodedExpected);
    }
  });

  test('decodingSmokeTest', () {
    List<String> encoded = List<String>();
    final encodedFile =
        File(join(dirname(Platform.script.path), 'res/encoded.txt'));
    Stream<List<int>> encodedStream = encodedFile.openRead();
    encodedStream
        .transform(utf8.decoder) // Decode bytes to UTF-8.
        .transform(LineSplitter()) // Convert stream to individual lines.
        .listen((String line) {
      // Process results.
      encoded.add(line);
    }, onError: (e) {
      print(e.toString());
    });

    List<String> decoded = List<String>();
    final decodedFile =
        File(join(dirname(Platform.script.path), 'res/decoded.txt'));
    Stream<List<int>> decodedStream = decodedFile.openRead();
    decodedStream
        .transform(utf8.decoder) // Decode bytes to UTF-8.
        .transform(LineSplitter()) // Convert stream to individual lines.
        .listen((String line) {
      // Process results.
      decoded.add(line);
    }, onError: (e) {
      print(e.toString());
    });

    // Assert both files have the same number of lines before comparing data.
    expect(encoded.length, equals(decoded.length));

    for (int i = 0; i < encoded.length; i++) {
      bool hasThirdDimension = false;
      ThirdDimension expectedDimension = ThirdDimension.ABSENT;
      String encodedLine = encoded[i].trim();
      final splittedLine = encodedLine.split('');
      String decodedLine = decoded[i].trim();

      //File parsing
      List<String> output =
          decodedLine.substring(1, decodedLine.length - 1).split(";");
      List<String> meta =
          output[0].trim().substring(1, output[0].trim().length - 1).split(",");
      if (meta.length > 1) {
        expectedDimension = ThirdDimension.values[int.parse(meta[2].trim())];
        hasThirdDimension = true;
      }
      String decodedInputLine =
          decodedLine.substring(1, decodedLine.length - 1).split(";")[1];
      List<LatLngZ> expectedLatLngZs =
          extractLatLngZ(decodedInputLine, hasThirdDimension);

      //Validate thirdDimension
      ThirdDimension computedDimension =
          FlexiblePolyline.getThirdDimension(splittedLine);
      expect(computedDimension, expectedDimension);

      //Validate LatLngZ
      List<LatLngZ> computedLatLngZs = FlexiblePolyline.decode(encodedLine);

      expect(computedLatLngZs, orderedEquals(expectedLatLngZs));
    }
  });
}

List<LatLngZ> extractLatLngZ(String line, bool hasThirdDimension) {
  List<LatLngZ> latLngZs = List<LatLngZ>();

  List<String> coordinates =
      line.trim().substring(1, line.trim().length - 1).split(",");
  for (int itr = 0;
      itr < coordinates.length && !isNullOrEmpty(coordinates[itr]);) {
    double lat = double.parse(coordinates[itr++].trim().replaceAll("(", ""));
    double lng = double.parse(coordinates[itr++].trim().replaceAll(")", ""));
    double z = 0;
    if (hasThirdDimension) {
      z = double.parse(coordinates[itr++].trim().replaceAll(")", ""));
    }
    latLngZs.add(new LatLngZ(lat, lng, z));
  }
  return latLngZs;
}

bool isNullOrEmpty(String str) {
  if (str != null && !str.trim().isEmpty) {
    return false;
  }
  return true;
}
