/*
 * Copyright (C) 2019 HERE Europe B.V.
 * Licensed under MIT, see full license in LICENSE
 * SPDX-License-Identifier: MIT
 * License-Filename: LICENSE
 */
package com.here.flexpolyline;

import java.text.CharacterIterator;
import java.text.StringCharacterIterator;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

/**
 * The polyline encoding is a lossy compressed representation of a list of coordinate pairs or coordinate triples.
 * It achieves that by:
 * <p><ol>
 * <li>Reducing the decimal digits of each value.
 * <li>Encoding only the offset from the previous point.
 * <li>Using variable length for each coordinate delta.
 * <li>Using 64 URL-safe characters to display the result.
 * </ol><p>
 *
 * The advantage of this encoding are the following:
 * <p><ul>
 * <li> Output string is composed by only URL-safe characters
 * <li> Floating point precision is configurable
 * <li> It allows to encode a 3rd dimension with a given precision, which may be a level, altitude, elevation or some other custom value
 * </ul><p>
 */
public class PolylineEncoderDecoder {

    /**
     * Header version
     * A change in the version may affect the logic to encode and decode the rest of the header and data
     */
    public static final byte FORMAT_VERSION = 1;

    //Base64 URL-safe characters
    public static final char[] ENCODING_TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_".toCharArray();

    public static final  int[] DECODING_TABLE = {
            62, -1, -1, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
            22, 23, 24, 25, -1, -1, -1, -1, 63, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
            36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51
    };

    /**
     * Encode the list of coordinate triples.
     *
     * The third dimension value will be eligible for encoding only when ThirdDimension is other than ABSENT.
     * This is lossy compression based on precision accuracy.
     *
     * @param coordinates {@link List} of coordinate triples that to be encoded.
     * @param precision   Floating point precision of the coordinate to be encoded.
     * @param thirdDimension {@link ThirdDimension} which may be a level, altitude, elevation or some other custom value
     * @param thirdDimPrecision Floating point precision for thirdDimension value
     * @return URL-safe encoded {@link String} for the given coordinates.
     */
    public static String encode(List<LatLngZ> coordinates, int precision, ThirdDimension thirdDimension, int thirdDimPrecision) {
        if (coordinates == null || coordinates.isEmpty()) {
            throw new IllegalArgumentException("Invalid coordinates!");
        }
        if (thirdDimension == null) {
            throw new IllegalArgumentException("Invalid thirdDimension");
        }
        Encoder enc = new Encoder(precision, thirdDimension, thirdDimPrecision);
        Iterator<LatLngZ> iter = coordinates.iterator();
        while (iter.hasNext()) {
            enc.add(iter.next());
        }
        return enc.getEncoded();
    }

    /**
     * Decode the encoded input {@link String} to {@link List} of coordinate triples.
     *
     * @param encoded URL-safe encoded {@link String}
     * @return {@link List} of coordinate triples that are decoded from input
     *
     * @see PolylineDecoder#getThirdDimension(String) getThirdDimension
     * @see LatLngZ
     */
    public static List<LatLngZ> decode(String encoded) {

        if (encoded == null || encoded.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid argument!");
        }
        List<LatLngZ> result = new ArrayList<>();
        Decoder dec = new Decoder(encoded);

        LatLngZ coord;
        while ((coord = dec.decodeOne()) != null) {
            result.add(coord);
        }
        return result;
    }

    /**
     * ThirdDimension type from the encoded input {@link String}
     * @param encoded URL-safe encoded coordinate triples {@link String}
     * @return type of {@link ThirdDimension}
     */
    public static ThirdDimension getThirdDimension(String encoded) {
        return new Decoder(encoded).getThirdDimension();
    }

    public byte getVersion() {
        return FORMAT_VERSION;
    }

    /*
     * Single instance for configuration, validation and encoding for an input request.
     */
    private static class Encoder {

        private final StringBuilder result;
        private final Converter latConverter;
        private final Converter lngConverter;
        private final Converter zConverter;
        private final ThirdDimension thirdDimension;

        public Encoder(int precision, ThirdDimension thirdDimension, int thirdDimPrecision) {
            this.latConverter = new Converter(precision);
            this.lngConverter = new Converter(precision);
            this.zConverter = new Converter(thirdDimPrecision);
            this.thirdDimension = thirdDimension;
            this.result = new StringBuilder();
            encodeHeader(precision, this.thirdDimension.getNum(), thirdDimPrecision);
        }

        private void encodeHeader(int precision, int thirdDimensionValue, int thirdDimPrecision) {
            /*
             * Encode the `precision`, `third_dim` and `third_dim_precision` into one encoded char
             */
            if (precision < 0 || precision > 15) {
                throw new IllegalArgumentException("precision out of range");
            }

            if (thirdDimPrecision < 0 || thirdDimPrecision > 15) {
                throw new IllegalArgumentException("thirdDimPrecision out of range");
            }

            if (thirdDimensionValue < 0 || thirdDimensionValue > 7) {
                throw new IllegalArgumentException("thirdDimensionValue out of range");
            }
            long res = (thirdDimPrecision << 7) | (thirdDimensionValue << 4) | precision;
            Converter.encodeUnsignedVarint(PolylineEncoderDecoder.FORMAT_VERSION, result);
            Converter.encodeUnsignedVarint(res, result);
        }

        private void add(double lat, double lng) {
            latConverter.encodeValue(lat, result);
            lngConverter.encodeValue(lng, result);
        }

        private void add(double lat, double lng, double z) {
            add(lat, lng);
            if (this.thirdDimension != ThirdDimension.ABSENT) {
                zConverter.encodeValue(z, result);
            }
        }

        private void add(LatLngZ tuple) {
            if(tuple == null) {
                throw new IllegalArgumentException("Invalid LatLngZ tuple");
            }
            add(tuple.lat, tuple.lng, tuple.z);
        }

        private String getEncoded() {
            return this.result.toString();
        }
    }

    /*
     * Single instance for decoding an input request.
     */
    private static class Decoder {

        private final CharacterIterator encoded;
        private final Converter latConverter;
        private final Converter lngConverter;
        private final Converter zConverter;

        private final ThirdDimension thirdDimension;

        public Decoder(String encoded) {
            this.encoded = new StringCharacterIterator(encoded);
            int header = decodeHeader();
            int precision = header & 0x0f;
            thirdDimension = ThirdDimension.fromNum((header >> 4) & 0x07);
            int thirdDimPrecision = ((header >> 7) & 0x0f);
            this.latConverter = new Converter(precision);
            this.lngConverter = new Converter(precision);
            this.zConverter = new Converter(thirdDimPrecision);
        }

        private boolean hasThirdDimension() {
            return thirdDimension != ThirdDimension.ABSENT;
        }

        private ThirdDimension getThirdDimension() {
            return thirdDimension;
        }

        private int decodeHeader() {

            long version = Converter.decodeUnsignedVarint(encoded);
            if (version != FORMAT_VERSION) {
                throw new IllegalArgumentException("Invalid format version");
            }

            // Decode the polyline header
            return (int) Converter.decodeUnsignedVarint(encoded);
        }


        private LatLngZ decodeOne() {
            if (encoded.current() == StringCharacterIterator.DONE) {
                return null;
            }

            final double lat = latConverter.decodeValue(encoded);
            final double lng = lngConverter.decodeValue(encoded);

            if (hasThirdDimension()) {
                final double z = zConverter.decodeValue(encoded);
                return new LatLngZ(lat, lng, z);
            }
            return new LatLngZ(lat, lng);
        }
    }

    //Decode a single char to the corresponding value
    private static int decodeChar(char charValue) {
        int pos = charValue - 45;
        if (pos < 0 || pos > 77) {
            return -1;
        }
        return DECODING_TABLE[pos];
    }

    /*
     * Stateful instance for encoding and decoding on a sequence of Coordinates part of an request.
     * Instance should be specific to type of coordinates (e.g. Lat, Lng)
     * so that specific type delta is computed for encoding.
     * Lat0 Lng0 3rd0 (Lat1-Lat0) (Lng1-Lng0) (3rdDim1-3rdDim0)
     */
    public static class Converter {

        private final long multiplier;
        private long lastValue = 0;

        public Converter(int precision) {
            multiplier = (long) Math.pow(10, precision);
        }

        private static void encodeUnsignedVarint(long value, StringBuilder result) {
            while (value > 0x1F) {
                byte pos =  (byte) ((value & 0x1F) | 0x20);
                result.append(ENCODING_TABLE[pos]);
                value >>= 5;
            }
            result.append(ENCODING_TABLE[(byte) value]);
        }

        void encodeValue(double value, StringBuilder result) {
            /*
             * Round-half-up
             * round(-1.4) --> -1
             * round(-1.5) --> -2
             * round(-2.5) --> -3
             */
            long scaledValue = Math.round(Math.abs(value * multiplier)) * Math.round(Math.signum(value));
            long delta = scaledValue - lastValue;
            boolean negative = delta < 0;

            lastValue = scaledValue;

            // make room on lowest bit
            delta <<= 1;

            // invert bits if the value is negative
            if (negative) {
                delta = ~delta;
            }
            encodeUnsignedVarint(delta, result);
        }

        private static long decodeUnsignedVarint(CharacterIterator encoded) {
            short shift = 0;
            long result = 0;
            char c;

            while ((c = encoded.current()) != CharacterIterator.DONE) {
                encoded.next();
                final long value = decodeChar(c);
                if (value < 0) {
                    throw new IllegalArgumentException("Unexpected value found '" + c + "' at index " + encoded.getIndex());
                }
                result |= (value & 0x1F) << shift;
                if ((value & 0x20) == 0) {
                    return result;
                } else {
                    shift += 5;
                }

            }
            throw new IllegalArgumentException("Unexpected end of encoded string");
        }

        //Decode single coordinate (say lat|lng) starting at index
        double decodeValue(CharacterIterator encoded) {
            long l = decodeUnsignedVarint(encoded);
            if ((l & 1) != 0) {
                l = ~l;
            }
            l = l >> 1;
            lastValue += l;

            return (double) lastValue / multiplier;
        }
    }

    /**
     * 	3rd dimension specification.
     *  Example a level, altitude, elevation or some other custom value.
     *  ABSENT is default when there is no third dimension en/decoding required.
     */
    public enum ThirdDimension {
        ABSENT(0),
        LEVEL(1),
        ALTITUDE(2),
        ELEVATION(3),
        RESERVED1(4),
        RESERVED2(5),
        CUSTOM1(6),
        CUSTOM2(7);

        private final int num;

        ThirdDimension(int num) {
            this.num = num;
        }

        public int getNum() {
            return num;
        }

        public static ThirdDimension fromNum(long value) {
            for (ThirdDimension dim : ThirdDimension.values()) {
                if (dim.getNum() == value) {
                    return dim;
                }
            }
            return null;
        }
    }

    /**
     * Coordinate triple
     */
    public static class LatLngZ {
        public final double lat;
        public final double lng;
        public final double z;

        public LatLngZ (double latitude, double longitude) {
            this(latitude, longitude, 0);
        }

        public LatLngZ (double latitude, double longitude, double thirdDimension) {
            this.lat = latitude;
            this.lng = longitude;
            this.z   = thirdDimension;
        }

        @Override
        public String toString() {
            return "LatLngZ [lat=" + lat + ", lng=" + lng + ", z=" + z + "]";
        }

        @Override
        public boolean equals(Object anObject) {
            if (this == anObject) {
                return true;
            }
            if (anObject instanceof LatLngZ) {
                LatLngZ passed = (LatLngZ)anObject;
                if (passed.lat == this.lat && passed.lng == this.lng && passed.z == this.z) {
                    return true;
                }
            }
            return false;
        }
    }
}
