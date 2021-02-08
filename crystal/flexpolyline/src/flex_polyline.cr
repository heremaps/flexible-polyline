# Copyright Nikola Motor 2021
#
# Released under the MIT License as follows:
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#
# Crystal code implementation of the HERE Map Flexible Polyline
#
# The polyline encoding is a lossy compressed representation of a list of coordinate pairs or coordinate triples.
# It achieves that by:
#
# * Reducing the decimal digits of each value.
# * Encoding only the offset from the previous point.
# * Using variable length for each coordinate delta.
# * Using 64 URL-safe characters to display the result.
#
# The advantage of this encoding are the following:
# *  Output string is composed by only URL-safe characters
# *  Floating point precision is configurable
# *  It allows to encode a 3rd dimension with a given precision, which may be a level, altitude, elevation or some other custom value
#
module PolylineEncoderDecoder
  # All encoded lines include the version in the header
  FORMAT_VERSION = 1

  enum ThirdDimension
    ABSENT
    LEVEL
    ALTITUDE
    ELEVATION
    RESERVED1
    RESERVED2
    CUSTOM1
    CUSTOM2
  end

  # Instance of a Flexible Polyline with Lat, Lng, Z points  and properties
  class FlexiblePolyline
    getter coordinates = Array(LatLngZ).new
    property precision : Int8 = 0
    property thirdDimension : ThirdDimension = ThirdDimension::ABSENT
    property thirdDimPrecision : Int8 = 0

    def ==(other)
      return false unless @precision == other.precision
      return false unless @thirdDimension == other.thirdDimension
      return false unless @thirdDimPrecision == other.thirdDimPrecision || @thirdDimension == ThirdDimension::ABSENT
      return false unless @coordinates.size == other.coordinates.size
      coordinates.each_with_index do |llz, index|
        return false unless llz.equalish(other.coordinates[index], @precision, @thirdDimPrecision)
      end
      return true
    end

    def to_s
      String.build do |str|
        str << "Prec:" << @precision
        str << " Third:" << @thirdDimension
        str << " ThirdDim:" << @thirdDimPrecision
        coordinates.each do |llz|
          str << "\n" << llz
        end
      end
    end
  end

  # A single latitude, longitude and optional Z location
  #
  # Z value of Float64::MIN indicates Z is unused
  struct LatLngZ
    property lat : Float64
    property lng : Float64
    property z : Float64

    def initialize(@lat : Float64 = 0, @lng : Float64 = 0, @z : Float64 = Float64::MIN)
    end

    def to_s(io : IO)
      io << "LatLngZ [lat=#{lat}, lng=#{lng}"
      io << ", z=#{z}]" unless z == Float64::MIN
    end

    def ==(other)
      return lat == other.lat && lng == other.lng && z == other.z
    end

    def equalish(other : LatLngZ, precision, thirdDimPrecision)
      return equalish(lat, other.lat, precision) &&
        equalish(lng, other.lng, precision) &&
        equalish(z, other.z, thirdDimPrecision)
    end
  end

  # Returns an encoded string
  # Throws exception on invalid input
  def encode(flexPolyLine)
    return encode(
      flexPolyLine.coordinates,
      flexPolyLine.precision,
      flexPolyLine.thirdDimension,
      flexPolyLine.thirdDimPrecision)
  end

  # Returns an encoded string
  # Throws exception on invalid input
  def encode(coordinates : Array(LatLngZ), precision : Int, thirdDimension : ThirdDimension, thirdDimPrecision : Int)
    raise "Empty coodinate set" if coordinates.size == 0
    encoder = Encoder.new(precision, thirdDimension, thirdDimPrecision)
    coordinates.each do |llz|
      encoder.add(llz)
    end
    return encoder.getResult
  end

  # Decode a string into a FlexiblePolyline
  # Throws exception on invalid input
  def decode(encoded : String)
    raise "Empty input" if encoded.strip.empty?
    decoder = Decoder.new(encoded)
    fpl = FlexiblePolyline.new
    fpl.precision = decoder.precision
    fpl.thirdDimension = decoder.thirdDimension
    fpl.thirdDimPrecision = decoder.thirdDimPrecision

    while (llz = decoder.decodeOne)
      fpl.coordinates << llz
    end
    return fpl
  end

  # This table represents the 64 unique values that can be used in encoding
  private ENCODING_TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

  # The ascii value of the character - 45 can be used as a lookup into this table
  private DECODING_TABLE = [
    62, -1, -1, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1,
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, -1, -1, -1, -1, 63, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
    36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
  ]

  # Instance for encoding a string
  private class Encoder
    @result = String::Builder.new

    def initialize(@precision : Int8, @thirdDimension : ThirdDimension, @thirdDimPrecision : Int8)
      raise "Invalid precision #{@precision}" unless (0..15).includes?(@precision)
      raise "Invalid third dimension precision #{@thirdDimPrecision}" unless (0..15).includes?(@thirdDimPrecision)
      @latConverter = Converter.new(@precision)
      @lngConverter = Converter.new(@precision)
      @zConverter = Converter.new(@thirdDimPrecision)
      encodeHeader()
    end

    private def encodeHeader
      raise "Precision out of range" if @precision < 0 || @precision > 15
      raise "Precision out of range" if @thirdDimPrecision < 0 || @thirdDimPrecision > 15
      meta = @thirdDimPrecision.to_i32 << 7 | @thirdDimension.value.to_i32 << 4 | @precision.to_i32
      Converter.encodeUnsigned(FORMAT_VERSION, @result)
      Converter.encodeUnsigned(meta, @result)
    end

    def add(llz : LatLngZ)
      @latConverter.encodeValue(llz.lat, @result)
      @lngConverter.encodeValue(llz.lng, @result)
      if @thirdDimension != ThirdDimension::ABSENT
        @zConverter.encodeValue(llz.z, @result)
      end
    end

    def getResult
      return @result.to_s
    end
  end

  # Instance for decoding a string
  private class Decoder
    property precision : Int8 = 0
    property thirdDimension : ThirdDimension = ThirdDimension::ABSENT
    property thirdDimPrecision : Int8 = 0

    def initialize(encoded : String)
      @decodeString = SimpleStringReader.new(encoded)
      decodeHeader
      @latConverter = Converter.new(@precision)
      @lonConverter = Converter.new(@precision)
      @zConverter = Converter.new(@thirdDimPrecision)
    end

    private def decodeHeader
      result = Converter.decodeUnsigned(@decodeString)
      raise "Version mismatch" unless result == FORMAT_VERSION
      result = Converter.decodeUnsigned(@decodeString)
      @precision = (result & 0xF).to_i8
      result >>= 4
      @thirdDimension = ThirdDimension.new((result & 0x7).to_i32)
      if @thirdDimension != ThirdDimension::ABSENT
        result >>= 3
        @thirdDimPrecision = (result & 0xF).to_i8
      end
      raise "Invalid precision #{@precision}" unless (0..15).includes?(@precision)
      raise "Invalid third dimension precision #{@thirdDimPrecision}" unless (0..15).includes?(@thirdDimPrecision)
    end

    # return false if no more to process OR populate the LatLngZ and return true
    def decodeOne
      return nil unless @decodeString.hasMore
      location = LatLngZ.new
      location.lat = @latConverter.decodeValue(@decodeString)
      location.lng = @lonConverter.decodeValue(@decodeString)
      if @thirdDimension != ThirdDimension::ABSENT
        location.z = @zConverter.decodeValue(@decodeString)
      end
      # puts "Decoded #{location}"
      return location
    end
  end

  # Instance for coding one of lat, lng or z
  private class Converter
    @multiplier : Float64 = 0
    @lastValue : Int64 = 0

    def initialize(precision)
      raise "Precision must be >= 0" if precision < 0
      @multiplier = 10**precision.to_f64
    end

    def encodeValue(value, result : String::Builder)
      scaledValue = getScaled(value, @multiplier)
      delta = scaledValue - @lastValue
      # puts "Value #{value} Scaled #{scaledValue} Last #{@lastValue} Delta #{delta}"
      @lastValue = scaledValue
      negative = delta < 0
      delta <<= 1
      delta = ~delta if negative
      Converter.encodeUnsigned(delta, result)
    end

    def Converter.encodeUnsigned(value, result : String::Builder)
      while value > 0x1F
        pos = (value & 0x1F) | 0x20
        # puts "Adding #{pos} is #{ENCODING_TABLE[pos]}"
        result << ENCODING_TABLE[pos]
        value >>= 5
      end
      # puts "Finally #{value & 0x1F} is #{ENCODING_TABLE[value & 0x1F]}"
      result << ENCODING_TABLE[value & 0x1F]
    end

    # reads a signed floating point value from the string
    def decodeValue(decodeString)
      delta = Converter.decodeUnsigned(decodeString)
      if delta & 0x1 != 0
        delta = ~delta
      end
      delta >>= 1
      # puts "Decoded value: #{delta}"
      @lastValue += delta
      return @lastValue.to_f64 / @multiplier
    end

    # reads a raw unsigned value from the string
    def Converter.decodeUnsigned(decodeString)
      shift = 0
      delta : Int64 = 0
      while decodeString.hasMore
        char = decodeString.next
        value = decodeChar(char).to_i64
        delta |= (value & 0x1f) << shift
        # put "Next: #{char} Value #{value} Delta #{delta} Shift #{shift}"
        if (value & 0x20) == 0
          return delta
        end
        shift += 5
      end
      raise "Invalid encoding. Unexpected end of string"
    end
  end

  # Needless reimplementation of Char::Reader because I don't like dealing with the null
  private class SimpleStringReader
    def initialize(@encoded : String)
      @index = 0
    end

    def hasMore
      return @index < @encoded.size
    end

    def next
      ret = @encoded[@index]
      @index += 1
      return ret
    end
  end

  # Return true if the two values are equivalent within the precion and limits of Float64
  private def equalish(a : Float64, b : Float64, precision : Int)
    return true if a == b
    begin
      multiplier = 10**precision.to_f64
      # Double values only guarantee 15 base 10 digits of precision
      aTest = (a*multiplier).to_i64
      bTest = (b*multiplier).to_i64
      while (aTest.abs > 999_999_999_999_999)
        aTest = (aTest / 10_i64).to_i64
        bTest = (bTest / 10_i64).to_i64
      end
      return aTest == bTest
    rescue OverflowError
      return false
    end
  end

  # convert a character to it's decoded 6 bit value
  private def decodeChar(charValue)
    pos = charValue.ord - 45
    if (pos < 0 || pos > 77 || DECODING_TABLE[pos] < 0)
      raise "Invalid encoding. Unexpected character #{charValue}"
    end
    return DECODING_TABLE[pos]
  end

  private def getScaled(value : Float64, multiplier : Float64) : Int64
    raise "Invalid input" if value.nil? || multiplier.nil?
    ret = (value*multiplier).abs.round(0).to_i64
    ret *= -1 if value < 0
    # puts "Value #{value} ret #{ret} mult #{multiplier} mathed #{value*multiplier}"
    return ret
  end
end
