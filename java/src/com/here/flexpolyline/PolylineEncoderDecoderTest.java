/*
 * Copyright (C) 2019 HERE Europe B.V.
 * Licensed under MIT, see full license in LICENSE
 * SPDX-License-Identifier: MIT
 * License-Filename: LICENSE
 */
package com.here.flexpolyline;

import static com.here.flexpolyline.PolylineEncoderDecoder.decode;
import static com.here.flexpolyline.PolylineEncoderDecoder.encode;
import static com.here.flexpolyline.PolylineEncoderDecoder.getThirdDimension;
import static com.here.flexpolyline.PolylineEncoderDecoder.ThirdDimension.ABSENT;
import static com.here.flexpolyline.PolylineEncoderDecoder.ThirdDimension.ALTITUDE;
import static com.here.flexpolyline.PolylineEncoderDecoder.ThirdDimension.ELEVATION;
import static com.here.flexpolyline.PolylineEncoderDecoder.ThirdDimension.LEVEL;

import java.io.BufferedReader;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import com.here.flexpolyline.PolylineEncoderDecoder.Converter;
import com.here.flexpolyline.PolylineEncoderDecoder.LatLngZ;
import com.here.flexpolyline.PolylineEncoderDecoder.ThirdDimension;

/**
 * Validate polyline encoding with different input combinations.
 */
public class PolylineEncoderDecoderTest {
    
    private void testInvalidCoordinates() {
        
        //Null coordinates
        assertThrows(IllegalArgumentException.class,
                     () -> { encode(null, 5, ThirdDimension.ABSENT, 0); });

        
        //Empty coordinates list test
        assertThrows(IllegalArgumentException.class,
                     () -> { encode(new ArrayList<LatLngZ>(), 5, ThirdDimension.ABSENT, 0); });
    }

    private void testInvalidThirdDimension() {
        
        List<LatLngZ> pairs = new ArrayList<>();
        pairs.add(new LatLngZ(50.1022829, 8.6982122));
        ThirdDimension invalid = null;
        
        //Invalid Third Dimension
        assertThrows(IllegalArgumentException.class,
                     () -> { encode(pairs, 5, invalid, 0); });
    }

    private void testConvertValue() {

        PolylineEncoderDecoder.Converter conv = new PolylineEncoderDecoder.Converter(5);
        StringBuilder result = new StringBuilder();
        conv.encodeValue(-179.98321, result);
        assertEquals(result.toString(), "h_wqiB");
    }

    private void testSimpleLatLngEncoding() {

        List<LatLngZ> pairs = new ArrayList<>();
        pairs.add(new LatLngZ(50.1022829, 8.6982122));
        pairs.add(new LatLngZ(50.1020076, 8.6956695));
        pairs.add(new LatLngZ(50.1006313, 8.6914960));
        pairs.add(new LatLngZ(50.0987800, 8.6875156));

        String expected = "BFoz5xJ67i1B1B7PzIhaxL7Y";
        String computed = encode(pairs, 5, ThirdDimension.ABSENT, 0);
        assertEquals(computed, expected);
    }

    private void testComplexLatLngEncoding() {

        List<LatLngZ> pairs = new ArrayList<>();
        pairs.add(new LatLngZ(52.5199356, 13.3866272));
        pairs.add(new LatLngZ(52.5100899, 13.2816896));
        pairs.add(new LatLngZ(52.4351807, 13.1935196));
        pairs.add(new LatLngZ(52.4107285, 13.1964502));
        pairs.add(new LatLngZ(52.38871,   13.1557798));
        pairs.add(new LatLngZ(52.3727798, 13.1491003));
        pairs.add(new LatLngZ(52.3737488, 13.1154604));
        pairs.add(new LatLngZ(52.3875198, 13.0872202));
        pairs.add(new LatLngZ(52.4029388, 13.0706196));
        pairs.add(new LatLngZ(52.4105797, 13.0755529));

        String expected = "BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e";
        String computed = encode(pairs, 5, ThirdDimension.ABSENT, 0);
        assertEquals(computed, expected);
    }

    private void testLatLngZEncode() {

        List<LatLngZ> tuples = new ArrayList<>();
        tuples.add(new LatLngZ(50.1022829, 8.6982122, 10));
        tuples.add(new LatLngZ(50.1020076, 8.6956695, 20));
        tuples.add(new LatLngZ(50.1006313, 8.6914960, 30));
        tuples.add(new LatLngZ(50.0987800, 8.6875156, 40));

        String expected = "BlBoz5xJ67i1BU1B7PUzIhaUxL7YU";
        String computed = encode(tuples, 5, ThirdDimension.ALTITUDE, 0);
        assertEquals(computed, expected);
    }
    
    
    /**********************************************/
    /********** Decoder test starts ***************/
    /**********************************************/
    private void testInvalidEncoderInput() {
        
        //Null coordinates
        assertThrows(IllegalArgumentException.class,
                     () -> { decode(null); });

        
        //Empty coordinates list test
        assertThrows(IllegalArgumentException.class,
                     () -> { decode(""); });
    }
    
    private void testThirdDimension() {
        assertTrue(getThirdDimension("BFoz5xJ67i1BU") == ABSENT);
        assertTrue(getThirdDimension("BVoz5xJ67i1BU") == LEVEL);
        assertTrue(getThirdDimension("BlBoz5xJ67i1BU") == ALTITUDE);
        assertTrue(getThirdDimension("B1Boz5xJ67i1BU") == ELEVATION);
    }

    private void testDecodeConvertValue() {

        String encoded = "h_wqiB";
        double expected = -179.98321;
        AtomicReference<Double> computed = new AtomicReference<>(0d);
        Converter conv = new Converter(5);
        conv.decodeValue(encoded,
                         new AtomicInteger(0),
                         computed);
        assertEquals(computed.get(), expected);
    }
    
    
    private void testSimpleLatLngDecoding() {

        List<LatLngZ> computed = decode("BFoz5xJ67i1B1B7PzIhaxL7Y");
        List<LatLngZ> expected = new ArrayList<>();
        expected.add(new LatLngZ(50.10228, 8.69821));
        expected.add(new LatLngZ(50.10201, 8.69567));
        expected.add(new LatLngZ(50.10063, 8.69150));
        expected.add(new LatLngZ(50.09878, 8.68752));

        assertEquals(computed.size(), expected.size());
        for (int i = 0; i < computed.size(); ++i) {
            assertEquals(computed.get(i), expected.get(i));
        }
    }

    private void testComplexLatLngDecoding() {

        List<LatLngZ> computed = decode("BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e");

        List<LatLngZ> pairs = new ArrayList<>();
        pairs.add(new LatLngZ(52.51994, 13.38663));
        pairs.add(new LatLngZ(52.51009, 13.28169));
        pairs.add(new LatLngZ(52.43518, 13.19352));
        pairs.add(new LatLngZ(52.41073, 13.19645));
        pairs.add(new LatLngZ(52.38871, 13.15578));
        pairs.add(new LatLngZ(52.37278, 13.14910));
        pairs.add(new LatLngZ(52.37375, 13.11546));
        pairs.add(new LatLngZ(52.38752, 13.08722));
        pairs.add(new LatLngZ(52.40294, 13.07062));
        pairs.add(new LatLngZ(52.41058, 13.07555));

        assertEquals(computed.size(), pairs.size());
        for (int i = 0; i < computed.size(); ++i) {
            assertEquals(computed.get(i), pairs.get(i));
        }
    }

    private void testLatLngZDecode() {
        List<LatLngZ> computed = decode("BlBoz5xJ67i1BU1B7PUzIhaUxL7YU");
        List<LatLngZ> tuples = new ArrayList<>();

        tuples.add(new LatLngZ(50.10228, 8.69821, 10));
        tuples.add(new LatLngZ(50.10201, 8.69567, 20));
        tuples.add(new LatLngZ(50.10063, 8.69150, 30));
        tuples.add(new LatLngZ(50.09878, 8.68752, 40));
        
        assertEquals(computed.size(), tuples.size());
        for (int i = 0; i < computed.size(); ++i) {
            assertEquals(computed.get(i), tuples.get(i));
        }
    }

    private static final String TEST_FILES_RELATIVE_PATH = "../test/";

    private void encodingSmokeTest() {

        int lineNo = 0;
        try (BufferedReader input = Files.newBufferedReader(Paths.get(TEST_FILES_RELATIVE_PATH + "original.txt"));
             BufferedReader encoded = Files.newBufferedReader(Paths.get(TEST_FILES_RELATIVE_PATH + "round_half_up/encoded.txt"))) {

            String inputFileLine;
            String encodedFileLine;

            // read line by line and validate the test
            while ((inputFileLine = input.readLine()) != null && (encodedFileLine = encoded.readLine()) != null) {

                lineNo++;
                int precision = 0;
                int thirdDimPrecision = 0;
                boolean hasThirdDimension = false;
                ThirdDimension thirdDimension = ThirdDimension.ABSENT;
                inputFileLine = inputFileLine.trim();
                encodedFileLine = encodedFileLine.trim();

                //File parsing
                String[] inputs = inputFileLine.substring(1, inputFileLine.length() - 1).split(";");
                String[] meta = inputs[0].trim().substring(1, inputs[0].trim().length() - 1).split(",");
                precision = Integer.valueOf(meta[0]);

                if (meta.length > 1) {
                    thirdDimPrecision = Integer.valueOf(meta[1].trim());
                    thirdDimension = ThirdDimension.fromNum(Integer.valueOf(meta[2].trim()));
                    hasThirdDimension = true;
                }
                List<LatLngZ> latLngZs = extractLatLngZ(inputs[1], hasThirdDimension);
                String encodedComputed = encode(latLngZs, precision, thirdDimension, thirdDimPrecision);
                String encodedExpected = encodedFileLine;
                assertEquals(encodedComputed, encodedExpected);
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.err.format("LineNo: " + lineNo + " validation got exception: %s%n", e);
        }
    }

    private void decodingSmokeTest() {

        int lineNo = 0;
        try (BufferedReader encoded = Files.newBufferedReader(Paths.get(TEST_FILES_RELATIVE_PATH + "round_half_up/encoded.txt"));
             BufferedReader decoded = Files.newBufferedReader(Paths.get(TEST_FILES_RELATIVE_PATH + "round_half_up/decoded.txt"))) {

            String encodedFileLine;
            String decodedFileLine;

            // read line by line and validate the test
            while ((encodedFileLine = encoded.readLine()) != null && (decodedFileLine = decoded.readLine()) != null) {

                lineNo++;
                boolean hasThirdDimension = false;
                ThirdDimension expectedDimension = ThirdDimension.ABSENT;
                encodedFileLine = encodedFileLine.trim();
                decodedFileLine = decodedFileLine.trim();

                //File parsing
                String[] output = decodedFileLine.substring(1, decodedFileLine.length() - 1).split(";");
                String[] meta = output[0].trim().substring(1, output[0].trim().length() - 1).split(",");
                if (meta.length > 1) {
                    expectedDimension = ThirdDimension.fromNum(Integer.valueOf(meta[2].trim()));
                    hasThirdDimension = true;
                }
                String decodedInputLine = decodedFileLine.substring(1, decodedFileLine.length() - 1).split(";")[1];
                List<LatLngZ> expectedLatLngZs = extractLatLngZ(decodedInputLine, hasThirdDimension);

                //Validate thirdDimension
                ThirdDimension computedDimension = getThirdDimension(encodedFileLine);
                assertEquals(computedDimension, expectedDimension);

                //Validate LatLngZ
                List<LatLngZ> computedLatLngZs = decode(encodedFileLine);
                assertEquals(computedLatLngZs.size(), expectedLatLngZs.size());
                for (int i = 0; i < computedLatLngZs.size(); ++i) {
                    assertEquals(computedLatLngZs.get(i), expectedLatLngZs.get(i));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.err.format("LineNo: " + lineNo + " validation got exception: %s%n", e);
        }
    }

    private void testVeryLongLine(int lineLength) {
        final int PRECISION = 10;
        Random random = new Random();
        List<LatLngZ> coordinates = new ArrayList<LatLngZ>();
        for (int i = 0; i <= lineLength; i++) {
            LatLngZ nextPoint = new LatLngZ(random.nextDouble(), random.nextDouble(), random.nextDouble());
            coordinates.add(nextPoint);
        }
        String encoded = encode(coordinates, PRECISION, ThirdDimension.ALTITUDE, PRECISION);
        long startTime = System.nanoTime();
        List<LatLngZ> decoded = decode(encoded);
        long duration = (System.nanoTime() - startTime);
        System.out.println("duration: " + duration/1000 + "us");
    }

    private static List<LatLngZ> extractLatLngZ(String line, boolean hasThirdDimension) {
        List<LatLngZ> latLngZs = new ArrayList<LatLngZ>();

        String[] coordinates  = line.trim().substring(1, line.trim().length()-1).split(",");
        for(int itr = 0; itr < coordinates.length && !isNullOrEmpty(coordinates[itr]); ) {
            double lat = Double.valueOf(coordinates[itr++].trim().replace("(", ""));
            double lng = Double.valueOf(coordinates[itr++].trim().replace(")", ""));
            double z   = 0;
            if(hasThirdDimension) {
                 z   = Double.valueOf(coordinates[itr++].trim().replace(")", ""));
            }
            latLngZs.add(new LatLngZ(lat, lng, z));
        }
        return latLngZs;
    }

    public static boolean isNullOrEmpty(String str) {
        if(str != null && !str.trim().isEmpty()) {
            return false;
        }
        return true;
    }

    private static void assertEquals(Object lhs, Object rhs) {
        if (lhs != rhs) {
            if (!lhs.equals(rhs)) {
                throw new RuntimeException("Assert failed, " + lhs + " != " + rhs);
            }
        }
    }
    
    private static void assertTrue(boolean value) {
        if (!value) {
            throw new RuntimeException("Assert failed");
        }
    }
    
    private static <T extends Throwable> void assertThrows(Class<T> expectedType, Runnable runnable) {
        try {
            runnable.run();
        }
        catch (Throwable actualException) {
            if (!expectedType.isInstance(actualException)) {
                throw new RuntimeException("Assert failed, Invalid exception found!");
            }
            return;
        }
        throw new RuntimeException("Assert failed, No exception found!");
    }

    public static void main(String[] args) {
        final int DEFAULT_LINE_LENGTH = 1000;
        int lineLength = DEFAULT_LINE_LENGTH;
        if (args.length > 0) {
            lineLength = Integer.parseInt(args[0]);
        }

        PolylineEncoderDecoderTest test = new PolylineEncoderDecoderTest();
        test.testInvalidCoordinates();
        test.testInvalidThirdDimension();
        test.testConvertValue();
        test.testSimpleLatLngEncoding();
        test.testComplexLatLngEncoding();
        test.testLatLngZEncode();
        test.encodingSmokeTest();

        //Decode test
        test.testInvalidEncoderInput();
        test.testThirdDimension();
        test.testDecodeConvertValue();
        test.testSimpleLatLngDecoding();
        test.testComplexLatLngDecoding();
        test.testLatLngZDecode();
        test.decodingSmokeTest();

        test.testVeryLongLine(lineLength);
    }
}
