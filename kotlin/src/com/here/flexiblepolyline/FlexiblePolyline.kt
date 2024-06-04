/*
 * Copyright (C) 2019 HERE Europe B.V.
 * Licensed under MIT, see full license in LICENSE
 * SPDX-License-Identifier: MIT
 * License-Filename: LICENSE
 */
package com.here.flexiblepolyline

import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
/**
 * The polyline encoding is a lossy compressed representation of a list of coordinate pairs or coordinate triples.
 * It achieves that by:
 *
 *  1. Reducing the decimal digits of each value.
 *  1. Encoding only the offset from the previous point.
 *  1. Using variable length for each coordinate delta.
 *  1. Using 64 URL-safe characters to display the result.
 *
 * The advantage of this encoding are the following:
 *  -  Output string is composed by only URL-safe characters
 *  -  Floating point precision is configurable
 *  -  It allows to encode a 3rd dimension with a given precision, which may be a level, altitude, elevation or some other custom value
 */
object FlexiblePolyline {

    private const val version: Int = 1
    //Base64 URL-safe characters
    private val ENCODING_TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_".toCharArray()
    private val DECODING_TABLE = intArrayOf(
        62, -1, -1, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
        22, 23, 24, 25, -1, -1, -1, -1, 63, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
        36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51
    )

    /**
     * Encode the list of coordinate triples.<BR></BR><BR></BR>
     * The third dimension value will be eligible for encoding only when ThirdDimension is other than ABSENT.
     * This is lossy compression based on precision accuracy.
     *
     * @param coordinates [List] of coordinate triples that to be encoded.
     * @param precision   Floating point precision of the coordinate to be encoded.
     * @param thirdDimension [ThirdDimension] which may be a level, altitude, elevation or some other custom value
     * @param thirdDimPrecision Floating point precision for thirdDimension value
     * @return URL-safe encoded [String] for the given coordinates.
     */
    @JvmStatic
    fun encode(coordinates: List<LatLngZ?>?, precision: Int, thirdDimension: ThirdDimension?, thirdDimPrecision: Int): String {
        require(!coordinates.isNullOrEmpty()) { "Invalid coordinates!" }
        requireNotNull(thirdDimension) { "Invalid thirdDimension" }
        val enc = Encoder(precision, thirdDimension, thirdDimPrecision)
        val iterator = coordinates.iterator()
        while (iterator.hasNext()) {
            enc.add(iterator.next())
        }
        return enc.getEncoded()
    }

    /**
     * Decode the encoded input [String] to [List] of coordinate triples.<BR></BR><BR></BR>
     * @param encoded URL-safe encoded [String]
     * @return [List] of coordinate triples that are decoded from input
     *
     * @see PolylineDecoder.getThirdDimension
     * @see LatLngZ
     */
    @JvmStatic
    fun decode(encoded: String?): List<LatLngZ> {
        require(!(encoded == null || encoded.trim { it <= ' ' }.isEmpty())) { "Invalid argument!" }
        val result: MutableList<LatLngZ> = ArrayList()
        val dec = Decoder(encoded)
        var lat = AtomicReference(0.0)
        var lng = AtomicReference(0.0)
        var z = AtomicReference(0.0)
        while (dec.decodeOne(lat, lng, z)) {
            result.add(LatLngZ(lat.get(), lng.get(), z.get()))
            lat = AtomicReference(0.0)
            lng = AtomicReference(0.0)
            z = AtomicReference(0.0)
        }
        return result
    }

    /**
     * ThirdDimension type from the encoded input [String]
     * @param encoded URL-safe encoded coordinate triples [String]
     * @return type of [ThirdDimension]
     */
    @JvmStatic
    fun getThirdDimension(encoded: String): ThirdDimension? {
        val index = AtomicInteger(0)
        val header = AtomicLong(0)
        Decoder.decodeHeaderFromString(encoded.toCharArray(), index, header)
        return ThirdDimension.fromNum(header.get() shr 4 and 7)
    }

    //Decode a single char to the corresponding value
    private fun decodeChar(charValue: Char): Int {
        val pos = charValue.code - 45
        return if (pos < 0 || pos > 77) {
            -1
        } else DECODING_TABLE[pos]
    }

    /*
     * Single instance for configuration, validation and encoding for an input request.
     */
    private class Encoder(precision: Int, private val thirdDimension: ThirdDimension, thirdDimPrecision: Int) {
        private val result: StringBuilder = StringBuilder()
        private val latConveter: Converter = Converter(precision)
        private val lngConveter: Converter = Converter(precision)
        private val zConveter: Converter = Converter(thirdDimPrecision)
        private fun encodeHeader(precision: Int, thirdDimensionValue: Int, thirdDimPrecision: Int) {
            /*
             * Encode the `precision`, `third_dim` and `third_dim_precision` into one encoded char
             */
            require(!(precision < 0 || precision > 15)) { "precision out of range" }
            require(!(thirdDimPrecision < 0 || thirdDimPrecision > 15)) { "thirdDimPrecision out of range" }
            require(!(thirdDimensionValue < 0 || thirdDimensionValue > 7)) { "thirdDimensionValue out of range" }
            val res = (thirdDimPrecision shl 7 or (thirdDimensionValue shl 4) or precision).toLong()
            Converter.encodeUnsignedVarint(version.toLong(), result)
            Converter.encodeUnsignedVarint(res, result)
        }

        private fun add(lat: Double, lng: Double) {
            latConveter.encodeValue(lat, result)
            lngConveter.encodeValue(lng, result)
        }

        private fun add(lat: Double, lng: Double, z: Double) {
            add(lat, lng)
            if (thirdDimension != ThirdDimension.ABSENT) {
                zConveter.encodeValue(z, result)
            }
        }

        fun add(tuple: LatLngZ?) {
            requireNotNull(tuple) { "Invalid LatLngZ tuple" }
            add(tuple.lat, tuple.lng, tuple.z)
        }

        fun getEncoded(): String {
            return result.toString()
        }

        init {
            encodeHeader(precision, this.thirdDimension.num, thirdDimPrecision)
        }
    }

    /*
     * Single instance for decoding an input request.
     */
    private class Decoder(encoded: String) {
        private val encoded: CharArray = encoded.toCharArray()
        private val index: AtomicInteger = AtomicInteger(0)
        private val latConverter: Converter
        private val lngConverter: Converter
        private val zConverter: Converter
        private var precision = 0
        private var thirdDimPrecision = 0
        private var thirdDimension: ThirdDimension? = null
        private fun hasThirdDimension(): Boolean {
            return thirdDimension != ThirdDimension.ABSENT
        }

        private fun decodeHeader() {
            val header = AtomicLong(0)
            decodeHeaderFromString(encoded, index, header)
            precision = (header.get() and 15).toInt() // we pick the first 4 bits only
            header.set(header.get() shr 4)
            thirdDimension = ThirdDimension.fromNum(header.get() and 7) // we pick the first 3 bits only
            thirdDimPrecision = (header.get() shr 3 and 15).toInt()
        }

        fun decodeOne(
            lat: AtomicReference<Double>,
            lng: AtomicReference<Double>,
            z: AtomicReference<Double>
        ): Boolean {
            if (index.get() == encoded.size) {
                return false
            }
            require(latConverter.decodeValue(encoded, index, lat)) { "Invalid encoding" }
            require(lngConverter.decodeValue(encoded, index, lng)) { "Invalid encoding" }
            if (hasThirdDimension()) {
                require(zConverter.decodeValue(encoded, index, z)) { "Invalid encoding" }
            }
            return true
        }

        companion object {
            fun decodeHeaderFromString(encoded: CharArray, index: AtomicInteger, header: AtomicLong) {
                val value = AtomicLong(0)

                // Decode the header version
                require(Converter.decodeUnsignedVarint(encoded, index, value)) { "Invalid encoding" }
                require(value.get() == version.toLong()) { "Invalid format version" }
                // Decode the polyline header
                require(Converter.decodeUnsignedVarint(encoded, index, value)) { "Invalid encoding" }
                header.set(value.get())
            }
        }

        init {
            decodeHeader()
            latConverter = Converter(precision)
            lngConverter = Converter(precision)
            zConverter = Converter(thirdDimPrecision)
        }
    }

    /*
     * Stateful instance for encoding and decoding on a sequence of Coordinates part of an request.
     * Instance should be specific to type of coordinates (e.g. Lat, Lng)
     * so that specific type delta is computed for encoding.
     * Lat0 Lng0 3rd0 (Lat1-Lat0) (Lng1-Lng0) (3rdDim1-3rdDim0)
     */
    class Converter(precision: Int) {
        private var multiplier: Long = 0
        private var lastValue: Long = 0
        private fun setPrecision(precision: Int) {
            //multiplier = Math.pow(10.0, java.lang.Double.valueOf(precision.toDouble())).toLong()
            multiplier = Math.pow(10.0, precision.toDouble()).toLong()
        }

        fun encodeValue(value: Double, result: StringBuilder) {
            /*
		     * Round-half-up
		     * round(-1.4) --> -1
		     * round(-1.5) --> -2
		     * round(-2.5) --> -3
		     */
            val scaledValue = Math.round(Math.abs(value * multiplier)) * Math.round(Math.signum(value))
            var delta = scaledValue - lastValue
            val negative = delta < 0
            lastValue = scaledValue

            // make room on lowest bit
            delta = delta shl 1

            // invert bits if the value is negative
            if (negative) {
                delta = delta.inv()
            }
            encodeUnsignedVarint(delta, result)
        }

        //Decode single coordinate (say lat|lng|z) starting at index
        fun decodeValue(
            encoded: CharArray,
            index: AtomicInteger,
            coordinate: AtomicReference<Double>
        ): Boolean {
            val delta = AtomicLong()
            if (!decodeUnsignedVarint(encoded, index, delta)) {
                return false
            }
            if (delta.get() and 1 != 0L) {
                delta.set(delta.get().inv())
            }
            delta.set(delta.get() shr 1)
            lastValue += delta.get()
            coordinate.set(lastValue.toDouble() / multiplier)
            return true
        }

        companion object {
            fun encodeUnsignedVarint(value: Long, result: StringBuilder) {
                // TODO: check performance impact
                /*val estimatedCapacity = 10000 // Adjust as needed
                result.ensureCapacity(estimatedCapacity)*/
                // end TODO
                var number = value
                while (number > 0x1F) {
                    val pos = (number and 0x1F or 0x20).toByte()
                    result.append(ENCODING_TABLE[pos.toInt()])
                    number = number shr 5
                }
                result.append(ENCODING_TABLE[number.toByte().toInt()])
            }

            fun decodeUnsignedVarint(
                encoded: CharArray,
                index: AtomicInteger,
                result: AtomicLong
            ): Boolean {
                var shift: Short = 0
                var delta: Long = 0
                var value: Long
                while (index.get() < encoded.size) {
                    value = decodeChar(encoded[index.get()]).toLong()
                    if (value < 0) {
                        return false
                    }
                    index.incrementAndGet()
                    delta = delta or (value and 0x1F shl shift.toInt())
                    if (value and 0x20 == 0L) {
                        result.set(delta)
                        return true
                    } else {
                        shift = (shift + 5).toShort()
                    }
                    // TODO: Check performance and tests
                    /*if (shift <= 0) {
                        return true
                    }*/
                    // end TODO
                }
                return shift <= 0
            }
        }

        init {
            setPrecision(precision)
        }
    }

    /**
     * 3rd dimension specification.
     * Example a level, altitude, elevation or some other custom value.
     * ABSENT is default when there is no third dimension en/decoding required.
     */
    enum class ThirdDimension(val num: Int) {
        ABSENT(0), LEVEL(1), ALTITUDE(2), ELEVATION(3), RESERVED1(4), RESERVED2(5), CUSTOM1(6), CUSTOM2(7);

        companion object {
            fun fromNum(value: Long): ThirdDimension? {
                for (dim in values()) {
                    if (dim.num.toLong() == value) {
                        return dim
                    }
                }
                return null
            }
        }
    }

    /**
     * Coordinate triple
     */
    class LatLngZ @JvmOverloads constructor(val lat: Double, val lng: Double, val z: Double = 0.0) {
        override fun toString(): String {
            return "LatLngZ [lat=$lat, lng=$lng, z=$z]"
        }

        override fun equals(other: Any?): Boolean {
            if (this === other) {
                return true
            }
            if (other is LatLngZ) {
                val passed = other
                if (passed.lat == lat && passed.lng == lng && passed.z == z) {
                    return true
                }
            }
            return false
        }

        override fun hashCode(): Int {
            var result = lat.hashCode()
            result = 31 * result + lng.hashCode()
            result = 31 * result + z.hashCode()
            return result
        }
    }
}