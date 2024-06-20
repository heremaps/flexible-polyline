using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using NUnit.Framework;

namespace FlexiblePolylineEncoder.Tests
{
    public class FlexiblePolylineEncoderTests
    {
        [Test]
        public void EncodedFlexilineMatchesDecodedResultTest()
        {
            using (var decodedEnumerator = File.ReadLines("../../../../../../test/round_half_up/decoded.txt").GetEnumerator())
            {
                foreach (var flexiline in File.ReadLines("../../../../../../test/round_half_up/encoded.txt"))
                {
                    decodedEnumerator.MoveNext();
                    var testResultStr = decodedEnumerator.Current;

                    var expectedResult = ParseExpectedTestResult(testResultStr);

                    var decoded = PolylineEncoderDecoder.Decode(flexiline);
                    var encoded = PolylineEncoderDecoder.Encode(
                        decoded,
                        expectedResult.Precision.Precision2d,
                        expectedResult.Precision.Type3d,
                        expectedResult.Precision.Precision3d);

                    ThirdDimension thirdDimension = PolylineEncoderDecoder.GetThirdDimension(encoded);
                    Assert.AreEqual(expectedResult.Precision.Type3d, thirdDimension);

                    for (int i = 0; i < decoded.Count; i++)
                    {
                        AssertEqualWithPrecision(
                            expectedResult.Coordinates[i].Lat,
                            decoded[i].Lat,
                            expectedResult.Precision.Precision2d);

                        AssertEqualWithPrecision(
                            expectedResult.Coordinates[i].Lng,
                            decoded[i].Lng,
                            expectedResult.Precision.Precision2d);

                        AssertEqualWithPrecision(
                            expectedResult.Coordinates[i].Z,
                            decoded[i].Z,
                            expectedResult.Precision.Precision3d);
                    }

                    if (flexiline != encoded)
                    {
                        Console.WriteLine(
$@"WARNING expected {flexiline} but got
                 {encoded}
");
                    }
                }
            }
        }

        private void AssertEqualWithPrecision(double expected, double actual, int precision)
        {
            long expectedLong = (long)(Math.Round(expected * (int)Math.Pow(10, precision), MidpointRounding.AwayFromZero));
            long actualLong = (long)(Math.Round(actual * (int)Math.Pow(10, precision), MidpointRounding.AwayFromZero));

            Assert.AreEqual(expectedLong, actualLong);
        }

        private static readonly Regex EncodedResultRegex = new Regex(@"^\{\((?:(?<prec>\d+)(?:, ?)?)+\); \[(?<latlngz>\((?:(?:-?\d+\.\d+)(?:, ?)?){2,3}\)(?:, ?)?)+\]\}", RegexOptions.Compiled);
        private static readonly Regex EncodedResultCoordinatesRegex = new Regex(@"^\((?:(?<number>-?\d+\.\d+)(?:, ?)?){2,3}\)(?:, ?)?", RegexOptions.Compiled);
        private ExpectedResult ParseExpectedTestResult(string encodedResult)
        {
            var resultMatch = EncodedResultRegex.Match(encodedResult);
            if (!resultMatch.Success)
                throw new ArgumentException("encodedResult");

            Precision precision;
            if (resultMatch.Groups["prec"].Captures.Count == 1)
            {
                precision = new Precision(int.Parse(resultMatch.Groups["prec"].Captures[0].Value));
            }
            else if (resultMatch.Groups["prec"].Captures.Count == 3)
            {
                precision = new Precision(
                    int.Parse(resultMatch.Groups["prec"].Captures[0].Value),
                    int.Parse(resultMatch.Groups["prec"].Captures[1].Value),
                    (ThirdDimension)int.Parse(resultMatch.Groups["prec"].Captures[2].Value));
            }
            else
            {
                throw new ArgumentException("encodedResult");
            }

            var coordinates = new List<LatLngZ>();
            foreach (Capture latlngzCapture in resultMatch.Groups["latlngz"].Captures)
            {
                LatLngZ coordinate;
                var coordinateMatch = EncodedResultCoordinatesRegex.Match(latlngzCapture.Value);
                if (coordinateMatch.Groups["number"].Captures.Count == 2)
                {
                    coordinate = new LatLngZ(
                        double.Parse(coordinateMatch.Groups["number"].Captures[0].Value),
                        double.Parse(coordinateMatch.Groups["number"].Captures[1].Value));
                }
                else if (coordinateMatch.Groups["number"].Captures.Count == 3)
                {
                    coordinate = new LatLngZ(
                        double.Parse(coordinateMatch.Groups["number"].Captures[0].Value),
                        double.Parse(coordinateMatch.Groups["number"].Captures[1].Value),
                        double.Parse(coordinateMatch.Groups["number"].Captures[2].Value));
                }
                else
                {
                    throw new ArgumentException("latlngz");
                }

                coordinates.Add(coordinate);
            }

            return new ExpectedResult(precision, coordinates);
        }

        private class Precision
        {
            public int Precision2d { get; }
            public int Precision3d { get; }
            public ThirdDimension Type3d { get; }

            public Precision(int precision2d, int precision3d = 0, ThirdDimension type3d = ThirdDimension.Absent)
            {
                Precision2d = precision2d;
                Precision3d = precision3d;
                Type3d = type3d;
            }
        }

        private class ExpectedResult
        {
            public Precision Precision { get; }

            public List<LatLngZ> Coordinates { get; }

            public ExpectedResult(Precision precision, List<LatLngZ> coordinates)
            {
                Precision = precision;
                Coordinates = coordinates;
            }
        }
    }
}
