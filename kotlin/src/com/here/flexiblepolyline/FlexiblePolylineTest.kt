/*
 * Copyright (C) 2019 HERE Europe B.V.
 * Licensed under MIT, see full license in LICENSE
 * SPDX-License-Identifier: MIT
 * License-Filename: LICENSE
 */
import com.here.flexiblepolyline.*
import com.here.flexiblepolyline.FlexiblePolyline.Converter
import com.here.flexiblepolyline.FlexiblePolyline.ThirdDimension
import com.here.flexiblepolyline.FlexiblePolyline.LatLngZ
import java.nio.file.Files
import java.nio.file.Paths
import java.util.*
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference

/**
 * Validate polyline encoding with different input combinations.
 */
class FlexiblePolylineTest {
    private fun testInvalidCoordinates() {

        //Null coordinates
        assertThrows(
            IllegalArgumentException::class.java
        ) { FlexiblePolyline.encode(null, 5, ThirdDimension.ABSENT, 0) }


        //Empty coordinates list test
        assertThrows(
            IllegalArgumentException::class.java
        ) { FlexiblePolyline.encode(ArrayList<LatLngZ>(), 5, ThirdDimension.ABSENT, 0) }
    }

    private fun testInvalidThirdDimension() {
        val pairs: MutableList<LatLngZ> = ArrayList()
        pairs.add(LatLngZ(50.1022829, 8.6982122))
        val invalid: ThirdDimension? = null

        //Invalid Third Dimension
        assertThrows(
            IllegalArgumentException::class.java
        ) { FlexiblePolyline.encode(pairs, 5, invalid, 0) }
    }

    private fun testConvertValue() {
        val conv: FlexiblePolyline.Converter = Converter(5)
        val result = StringBuilder()
        conv.encodeValue(-179.98321, result)
        assertEquals(result.toString(), "h_wqiB")
    }

    private fun testSimpleLatLngEncoding() {
        val pairs: MutableList<LatLngZ> = ArrayList()
        pairs.add(LatLngZ(50.1022829, 8.6982122))
        pairs.add(LatLngZ(50.1020076, 8.6956695))
        pairs.add(LatLngZ(50.1006313, 8.6914960))
        pairs.add(LatLngZ(50.0987800, 8.6875156))
        val expected = "BFoz5xJ67i1B1B7PzIhaxL7Y"
        val computed: String = FlexiblePolyline.encode(pairs, 5, ThirdDimension.ABSENT, 0)
        assertEquals(computed, expected)
    }

    private fun testComplexLatLngEncoding() {
        val pairs: MutableList<LatLngZ> = ArrayList()
        pairs.add(LatLngZ(52.5199356, 13.3866272))
        pairs.add(LatLngZ(52.5100899, 13.2816896))
        pairs.add(LatLngZ(52.4351807, 13.1935196))
        pairs.add(LatLngZ(52.4107285, 13.1964502))
        pairs.add(LatLngZ(52.38871, 13.1557798))
        pairs.add(LatLngZ(52.3727798, 13.1491003))
        pairs.add(LatLngZ(52.3737488, 13.1154604))
        pairs.add(LatLngZ(52.3875198, 13.0872202))
        pairs.add(LatLngZ(52.4029388, 13.0706196))
        pairs.add(LatLngZ(52.4105797, 13.0755529))
        val expected = "BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e"
        val computed: String = FlexiblePolyline.encode(pairs, 5, ThirdDimension.ABSENT, 0)
        assertEquals(computed, expected)
    }

    private fun testLatLngZEncode() {
        val tuples: MutableList<LatLngZ> = ArrayList()
        tuples.add(LatLngZ(50.1022829, 8.6982122, 10.0))
        tuples.add(LatLngZ(50.1020076, 8.6956695, 20.0))
        tuples.add(LatLngZ(50.1006313, 8.6914960, 30.0))
        tuples.add(LatLngZ(50.0987800, 8.6875156, 40.0))
        val expected = "BlBoz5xJ67i1BU1B7PUzIhaUxL7YU"
        val computed: String = FlexiblePolyline.encode(tuples, 5, ThirdDimension.ALTITUDE, 0)
        assertEquals(computed, expected)
    }
    /** */
    /********** Decoder test starts  */
    /** */
    private fun testInvalidEncoderInput() {

        //Null coordinates
        assertThrows(
            IllegalArgumentException::class.java
        ) { FlexiblePolyline.decode(null) }


        //Empty coordinates list test
        assertThrows(
            IllegalArgumentException::class.java
        ) { FlexiblePolyline.decode("") }
    }

    private fun testThirdDimension() {
        assertTrue(FlexiblePolyline.getThirdDimension("BFoz5xJ67i1BU") === ThirdDimension.ABSENT)
        assertTrue(FlexiblePolyline.getThirdDimension("BVoz5xJ67i1BU") === ThirdDimension.LEVEL)
        assertTrue(FlexiblePolyline.getThirdDimension("BlBoz5xJ67i1BU") === ThirdDimension.ALTITUDE)
        assertTrue(FlexiblePolyline.getThirdDimension("B1Boz5xJ67i1BU") === ThirdDimension.ELEVATION)
    }

    private fun testDecodeConvertValue() {
        val encoded = ("h_wqiB").iterator()
        val expected = -179.98321
        val conv = Converter(5)
        val computed = conv.decodeValue(encoded)
        assertEquals(computed, expected)
    }

    private fun testSimpleLatLngDecoding() {
        val computed: List<LatLngZ> = FlexiblePolyline.decode("BFoz5xJ67i1B1B7PzIhaxL7Y")
        val expected: MutableList<LatLngZ> = ArrayList()
        expected.add(LatLngZ(50.10228, 8.69821))
        expected.add(LatLngZ(50.10201, 8.69567))
        expected.add(LatLngZ(50.10063, 8.69150))
        expected.add(LatLngZ(50.09878, 8.68752))
        assertEquals(computed.size, expected.size)
        for (i in computed.indices) {
            assertEquals(computed[i], expected[i])
        }
    }

    private fun testComplexLatLngDecoding() {
        val computed: List<LatLngZ> = FlexiblePolyline.decode("BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e")
        val pairs: MutableList<LatLngZ> = ArrayList()
        pairs.add(LatLngZ(52.51994, 13.38663))
        pairs.add(LatLngZ(52.51009, 13.28169))
        pairs.add(LatLngZ(52.43518, 13.19352))
        pairs.add(LatLngZ(52.41073, 13.19645))
        pairs.add(LatLngZ(52.38871, 13.15578))
        pairs.add(LatLngZ(52.37278, 13.14910))
        pairs.add(LatLngZ(52.37375, 13.11546))
        pairs.add(LatLngZ(52.38752, 13.08722))
        pairs.add(LatLngZ(52.40294, 13.07062))
        pairs.add(LatLngZ(52.41058, 13.07555))
        assertEquals(computed.size, pairs.size)
        for (i in computed.indices) {
            assertEquals(computed[i], pairs[i])
        }
    }

    private fun testLatLngZDecode() {
        val computed: List<LatLngZ> = FlexiblePolyline.decode("BlBoz5xJ67i1BU1B7PUzIhaUxL7YU")
        val tuples: MutableList<LatLngZ> = ArrayList()
        tuples.add(LatLngZ(50.10228, 8.69821, 10.0))
        tuples.add(LatLngZ(50.10201, 8.69567, 20.0))
        tuples.add(LatLngZ(50.10063, 8.69150, 30.0))
        tuples.add(LatLngZ(50.09878, 8.68752, 40.0))
        assertEquals(computed.size, tuples.size)
        for (i in computed.indices) {
            assertEquals(computed[i], tuples[i])
        }
    }

    private fun encodingSmokeTest() {
        var lineNo = 0
        try {
            Files.newBufferedReader(Paths.get(TEST_FILES_RELATIVE_PATH + "original.txt")).use { input ->
                Files.newBufferedReader(Paths.get(TEST_FILES_RELATIVE_PATH + "round_half_up/encoded.txt")).use { encoded ->
                    var encodedFileLine : String? = "";
                    var inputFileLine : String? = "";

                    // read line by line and validate the test
                    while (encodedFileLine != null && inputFileLine != null) {
                        encodedFileLine = encoded.readLine()
                        inputFileLine = input.readLine()

                        if(encodedFileLine != null && inputFileLine != null){
                            lineNo++
                            var precision = 0
                            var thirdDimPrecision = 0
                            var hasThirdDimension = false
                            var thirdDimension: ThirdDimension? = ThirdDimension.ABSENT
                            inputFileLine = inputFileLine.trim()
                            encodedFileLine = encodedFileLine.trim()

                            //File parsing
                            val inputs = inputFileLine.substring(1, inputFileLine.length - 1).split(";").toTypedArray()
                            val meta = inputs[0].trim().substring(1, inputs[0].trim().length - 1).split(",").toTypedArray()
                            precision = Integer.valueOf(meta[0])
                            if (meta.size > 1) {
                                thirdDimPrecision = Integer.valueOf(meta[1].trim())
                                thirdDimension = ThirdDimension.fromNum(Integer.valueOf(meta[2].trim()).toLong())
                                hasThirdDimension = true
                            }
                            val latLngZs = extractLatLngZ(inputs[1], hasThirdDimension)
                            val encodedComputed: String = FlexiblePolyline.encode(latLngZs, precision, thirdDimension, thirdDimPrecision)
                            val encodedExpected = encodedFileLine
                            assertEquals(encodedComputed, encodedExpected)
                        } else { break; }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            System.err.format("LineNo: $lineNo validation got exception: %s%n", e)
        }
    }

    private fun decodingSmokeTest() {
        var lineNo = 0
        try {
            Files.newBufferedReader(Paths.get(TEST_FILES_RELATIVE_PATH + "round_half_up/encoded.txt")).use { encoded ->
                Files.newBufferedReader(Paths.get(TEST_FILES_RELATIVE_PATH + "round_half_up/decoded.txt")).use { decoded ->
                    var encodedFileLine : String? = "";
                    var decodedFileLine : String? = "";

                    // read line by line and validate the test
                    while (encodedFileLine != null && decodedFileLine != null) {
                            encodedFileLine = encoded.readLine()
                            decodedFileLine = decoded.readLine()

                            if(encodedFileLine != null && decodedFileLine != null){

                                lineNo++
                                var hasThirdDimension = false
                                var expectedDimension: ThirdDimension? = ThirdDimension.ABSENT
                                encodedFileLine = encodedFileLine.trim()
                                decodedFileLine = decodedFileLine.trim()

                                //File parsing
                                val output = decodedFileLine.substring(1, decodedFileLine.length - 1).split(";").toTypedArray()
                                val meta = output[0].trim().substring(1, output[0].trim().length - 1).split(",").toTypedArray()
                                if (meta.size > 1) {
                                    expectedDimension = ThirdDimension.fromNum(Integer.valueOf(meta[2].trim()).toLong())
                                    hasThirdDimension = true
                                }
                                val decodedInputLine = decodedFileLine.substring(1, decodedFileLine.length - 1).split(";").toTypedArray()[1]
                                val expectedLatLngZs = extractLatLngZ(decodedInputLine, hasThirdDimension)

                                //Validate thirdDimension
                                val computedDimension: ThirdDimension = FlexiblePolyline.getThirdDimension(encodedFileLine)!!
                                assertEquals(computedDimension, expectedDimension)

                                //Validate LatLngZ
                                val computedLatLngZs: List<LatLngZ> = FlexiblePolyline.decode(encodedFileLine)
                                assertEquals(computedLatLngZs.size, expectedLatLngZs.size)
                                for (i in computedLatLngZs.indices) {
                                    assertEquals(computedLatLngZs[i], expectedLatLngZs[i])
                                }
                            } else { break; }
                        }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            System.err.format("LineNo: $lineNo validation got exception: %s%n", e)
        }
    }

    private fun testVeryLongLine(lineLength: Int) {
        val PRECISION = 10
        val random = Random()
        val coordinates: MutableList<LatLngZ> = ArrayList()
        for (i in 0..lineLength) {
            val nextPoint = LatLngZ(random.nextDouble(), random.nextDouble(), random.nextDouble())
            coordinates.add(nextPoint)
        }
        val encoded: String = FlexiblePolyline.encode(coordinates, PRECISION, ThirdDimension.ALTITUDE, PRECISION)
        val startTime = System.nanoTime()
        val decoded: List<LatLngZ> = FlexiblePolyline.decode(encoded)
        val duration = System.nanoTime() - startTime
        println("duration: " + duration / 1000 + "us")
        println("FlexiblePolyline.decoded total number of LatLngZ: " + decoded.size)
    }

    companion object {
        private const val TEST_FILES_RELATIVE_PATH = "../test/"

        private fun extractLatLngZ(line: String, hasThirdDimension: Boolean): List<LatLngZ> {
            val latLngZs: MutableList<LatLngZ> = ArrayList()
            val coordinates = line.trim().substring(1, line.trim().length - 1).split(",").toTypedArray()
            var itr = 0
            while (itr < coordinates.size && !isNullOrEmpty(coordinates[itr])) {
                val lat = java.lang.Double.valueOf(coordinates[itr++].trim().replace("(", ""))
                val lng = java.lang.Double.valueOf(coordinates[itr++].trim().replace(")", ""))
                var z = 0.0
                if (hasThirdDimension) {
                    z = java.lang.Double.valueOf(coordinates[itr++].trim().replace(")", ""))
                }
                latLngZs.add(LatLngZ(lat, lng, z))
            }
            return latLngZs
        }

        private fun isNullOrEmpty(str: String?): Boolean {
            return str == null || str.trim().isEmpty()
        }

        private fun assertEquals(lhs: Any, rhs: Any?) {
            if (lhs !== rhs) {
                if (lhs != rhs) {
                    throw RuntimeException("Assert failed, $lhs != $rhs")
                }
            }
        }

        private fun assertTrue(value: Boolean) {
            if (!value) {
                throw RuntimeException("Assert failed")
            }
        }

        private fun <T : Throwable?> assertThrows(expectedType: Class<T>, runnable: Runnable) {
            try {
                runnable.run()
            } catch (actualException: Throwable) {
                if (!expectedType.isInstance(actualException)) {
                    println("Working Directory = " + actualException.javaClass.name + " "+ actualException);

                    throw RuntimeException("Assert failed, Invalid exception found!")
                }
                return
            }
            throw RuntimeException("Assert failed, No exception found!")
        }

        @JvmStatic
        fun main(args: Array<String>) {
            println("Working Directory = " + System.getProperty("user.dir"));

            val DEFAULT_LINE_LENGTH = 1000
            var lineLength = DEFAULT_LINE_LENGTH
            if (args.size > 0) {
                lineLength = args[0].toInt()
            }
            val test = FlexiblePolylineTest()
            test.testInvalidCoordinates()
            test.testInvalidThirdDimension()
            test.testConvertValue()
            test.testSimpleLatLngEncoding()
            test.testComplexLatLngEncoding()
            test.testLatLngZEncode()
            test.encodingSmokeTest()

            //Decode test
            test.testInvalidEncoderInput()
            test.testThirdDimension()
            test.testDecodeConvertValue()
            test.testSimpleLatLngDecoding()
            test.testComplexLatLngDecoding()
            test.testLatLngZDecode()
            test.decodingSmokeTest()
            test.testVeryLongLine(lineLength)
        }
    }
}