/*
 * Copyright (C) 2019 HERE Europe B.V.
 * Licensed under MIT, see full license in LICENSE
 * SPDX-License-Identifier: MIT
 * License-Filename: LICENSE
 */
package com.here.flexiblepolyline

import kotlin.math.abs
import kotlin.math.roundToLong
import kotlin.math.sign
import kotlin.math.pow

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
    const val VERSION = 1L

    // Base64 URL-safe characters
    private val ENCODING_TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_".toCharArray()
    private val DECODING_TABLE = intArrayOf(
        62, -1, -1, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
        22, 23, 24, 25, -1, -1, -1, -1, 63, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
        36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51
    )

    /**
     * Encode the list of coordinate triples.
     *
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
        coordinates.iterator().forEach {
            enc.add(it)
        }
        return enc.getEncoded()
    }

    /**
     * Decode the encoded input [String] to [List] of coordinate triples.
     *
     * @param encoded URL-safe encoded [String]
     * @return [List] of coordinate triples that are decoded from input
     *
     * @see getThirdDimension
     * @see LatLngZ
     */
    @JvmStatic
    fun decode(encoded: String?): List<LatLngZ> {
        require(!encoded.isNullOrBlank()) { "Invalid argument!" }
        val result: MutableList<LatLngZ> = ArrayList()
        val dec = Decoder(encoded)
        dec.iterator().forEach {
            result.add(it)
        }
        return result
    }

    /**
     * ThirdDimension type from the encoded input [String]
     *
     * @param encoded URL-safe encoded coordinate triples [String]
     * @return type of [ThirdDimension]
     */
    @JvmStatic
    fun getThirdDimension(encoded: String): ThirdDimension? {
        return Decoder(encoded).thirdDimension
    }

    // Decode a single char to the corresponding value
    private fun decodeChar(charValue: Char): Int {
        val pos = charValue.code - 45
        return if (pos < 0 || pos > 77) {
            -1
        } else DECODING_TABLE[pos]
    }

    // Single instance for configuration, validation and encoding for an input request.
    private class Encoder(precision: Int, private val thirdDimension: ThirdDimension, thirdDimPrecision: Int) {
        private val result: StringBuilder = StringBuilder()
        private val latConverter: Converter = Converter(precision)
        private val lngConverter: Converter = Converter(precision)
        private val zConverter: Converter = Converter(thirdDimPrecision)

        init {
            encodeHeader(precision, this.thirdDimension.num, thirdDimPrecision)
        }

        private fun encodeHeader(precision: Int, thirdDimensionValue: Int, thirdDimPrecision: Int) {
            // Encode the `precision`, `third_dim` and `third_dim_precision` into one encoded char
            require(!(precision < 0 || precision > 15)) { "precision out of range" }
            require(!(thirdDimPrecision < 0 || thirdDimPrecision > 15)) { "thirdDimPrecision out of range" }
            require(!(thirdDimensionValue < 0 || thirdDimensionValue > 7)) { "thirdDimensionValue out of range" }
            val res = ((thirdDimPrecision shl 7) or (thirdDimensionValue shl 4) or precision).toLong()
            Converter.encodeUnsignedVarInt(VERSION, result)
            Converter.encodeUnsignedVarInt(res, result)
        }

        private fun add(lat: Double, lng: Double) {
            latConverter.encodeValue(lat, result)
            lngConverter.encodeValue(lng, result)
        }

        private fun add(lat: Double, lng: Double, z: Double) {
            add(lat, lng)
            if (thirdDimension != ThirdDimension.ABSENT) {
                zConverter.encodeValue(z, result)
            }
        }

        fun add(tuple: LatLngZ?) {
            requireNotNull(tuple) { "Invalid LatLngZ tuple" }
            add(tuple.lat, tuple.lng, tuple.z)
        }

        fun getEncoded(): String {
            return result.toString()
        }
    }

    // Single instance for decoding an input request.
    private class Decoder(encoded: String) : Iterator<LatLngZ> {
        private val encoded: CharIterator = encoded.iterator()
        private val latConverter: Converter
        private val lngConverter: Converter
        private val zConverter: Converter
        var thirdDimension: ThirdDimension? = null

        init {
            val header = decodeHeader()
            val precision = header and 0x0f
            thirdDimension = ThirdDimension.fromNum(((header shr 4) and 0x07).toLong())
            val thirdDimPrecision = ((header shr 7) and 0x0f)
            latConverter = Converter(precision)
            lngConverter = Converter(precision)
            zConverter = Converter(thirdDimPrecision)
        }

        private fun hasThirdDimension(): Boolean {
            return thirdDimension != ThirdDimension.ABSENT
        }

        private fun decodeHeader(): Int {
            val version = Converter.decodeUnsignedVarInt(encoded)
            require(version == VERSION) { "Invalid format version :: encoded.$version vs FlexiblePolyline.$VERSION" }
            // Decode the polyline header
            return Converter.decodeUnsignedVarInt(encoded).toInt()
        }

        override fun next(): LatLngZ {
            val lat = latConverter.decodeValue(encoded)
            val lng = lngConverter.decodeValue(encoded)

            if (hasThirdDimension()) {
                val z = zConverter.decodeValue(encoded)
                return LatLngZ(lat, lng, z)
            }
            return LatLngZ(lat, lng)
        }

        override fun hasNext(): Boolean {
            return encoded.hasNext()
        }
    }

    /**
     * Stateful instance for encoding and decoding on a sequence of Coordinates part of an request.
     * Instance should be specific to type of coordinates (e.g. Lat, Lng)
     * so that specific type delta is computed for encoding.
     * Lat0 Lng0 3rd0 (Lat1-Lat0) (Lng1-Lng0) (3rdDim1-3rdDim0)
     *
     * @param precision [Int]
     */
    class Converter(precision: Int) {
        private val multiplier = (10.0.pow(precision.toDouble())).toLong()
        private var lastValue: Long = 0

        fun encodeValue(value: Double, result: StringBuilder) {
            /*
		     * Round-half-up
		     * round(-1.4) --> -1
		     * round(-1.5) --> -2
		     * round(-2.5) --> -3
		     */
            val scaledValue = abs(value * multiplier).roundToLong() * sign(value).roundToLong()
            var delta = scaledValue - lastValue
            val negative = delta < 0
            lastValue = scaledValue

            // make room on lowest bit
            delta = delta shl 1

            // invert bits if the value is negative
            if (negative) {
                delta = delta.inv()
            }
            encodeUnsignedVarInt(delta, result)
        }

        // Decode single coordinate (say lat|lng|z) starting at index
        fun decodeValue(encoded: CharIterator): Double {
            var l = decodeUnsignedVarInt(encoded)
            if ((l and 1L) != 0L) {
                l = l.inv()
            }
            l = l shr 1
            lastValue += l

            return lastValue.toDouble() / multiplier
        }

        companion object {
            fun encodeUnsignedVarInt(value: Long, result: StringBuilder) {
                var number = value
                while (number > 0x1F) {
                    val pos = (number and 0x1F or 0x20).toByte()
                    result.append(ENCODING_TABLE[pos.toInt()])
                    number = number shr 5
                }
                result.append(ENCODING_TABLE[number.toByte().toInt()])
            }

            fun decodeUnsignedVarInt(encoded: CharIterator): Long {
                var shift: Short = 0
                var result: Long = 0

                encoded.withIndex().forEach {
                    val value = decodeChar(it.value).toLong()
                    if (value < 0) {
                        throw IllegalArgumentException("Unexpected value found :: '${it.value}' at ${it.index}")
                    }
                    result = result or ((value and 0x1FL) shl shift.toInt())
                    if ((value and 0x20L) == 0L) {
                        return result
                    } else {
                        shift = (shift + 5).toShort()
                    }
                }
                return result
            }
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
                for (dim in entries) {
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
    data class LatLngZ(
        val lat: Double,
        val lng: Double,
        val z: Double = 0.0
    ){}
}