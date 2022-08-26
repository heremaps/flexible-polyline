# frozen_string_literal: true

module FlexPolyline
  class Decoder
    DECODING_TABLE = [
      62, -1, -1, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1,
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
      22, 23, 24, 25, -1, -1, -1, -1, 63, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
      36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51
    ].freeze

    PolylineHeader = Struct.new(:precision, :third_dim, :third_dim_precision)

    def initialize(encoded, format: :array)
      @encoded = encoded
      @format = format
    end

    # Decode an encoded polyline
    #
    # @return [Array<Array<Float>>, Array<Hash>] the decoded polyline
    def decode
      decoder = enum_decode
      if @format == :array
        decoder.to_a
      else
        key = THIRD_DIM_MAP[third_dimension]
        decoder.map do |(lat, lng, third)|
          key ? { lat: lat, lng: lng, key => third } : { lat: lat, lng: lng }
        end
      end
    end

    # Decode an encoded polyline
    #
    # @yield [lat, lng, alt] the decoded coordinates
    def enum_decode
      return to_enum(:enum_decode) unless block_given?

      last_lat = last_lng = last_z = 0
      decoder = decode_unsigned_values(@encoded)

      header = decode_header(decoder)

      factor_degree = 10.0**header.precision
      factor_z = 10.0**header.third_dim_precision
      third_dim = header.third_dim

      loop do
        begin
          last_lat += to_signed(decoder.next)
        rescue StopIteration
          return
        end

        begin
          last_lng += to_signed(decoder.next)

          if !third_dim.zero?
            last_z += to_signed(decoder.next)
            yield [last_lat / factor_degree, last_lng / factor_degree, last_z / factor_z]
          else
            yield [last_lat / factor_degree, last_lng / factor_degree]
          end
        rescue StopIteration
          raise ValueError, 'Invalid encoding. Premature ending reached'
        end
      end
    end

    # Return the third dimension of an encoded polyline.
    # Possible returned values are: ABSENT, LEVEL, ALTITUDE, ELEVATION, CUSTOM1, CUSTOM2.
    #
    # @return [Integer] the third dimension
    def third_dimension
      decode_header(decode_unsigned_values(@encoded)).third_dim
    end

    private

    # Return an iterator over encoded unsigned values part of an `encoded` polyline
    #
    # @param encoded [String] the encoded polyline
    def decode_unsigned_values(encoded)
      return to_enum(:decode_unsigned_values, encoded) unless block_given?

      result = shift = 0

      encoded.each_char do |char|
        value = decode_char(char)

        result |= (value & 0x1F) << shift
        if (value & 0x20).zero?
          yield result
          result = shift = 0
        else
          shift += 5
        end
      end

      raise ValueError, 'Invalid encoding' if shift.positive?
    end

    # Returns a PolylineHeader
    #
    # @param decoder [Enumerator] an enumerator over unsigned values
    # @return [PolylineHeader] the header
    def decode_header(decoder)
      version = decoder.next
      raise ValueError, 'Invalid format version' if version != FORMAT_VERSION

      value = decoder.next
      precision = value & 15
      value >>= 4
      third_dim = value & 7
      third_dim_precision = (value >> 3) & 15
      PolylineHeader.new(precision, third_dim, third_dim_precision)
    end

    # Decode a single char to the corresponding value
    #
    # @param char [String] the char to decode
    # @return [Integer] the value
    def decode_char(char)
      char_value = char.ord
      value = DECODING_TABLE[char_value - 45]

      raise ValueError('Invalid encoding') if value.nil? || value.negative?

      value
    end

    # Decode the sign from an unsigned value
    #
    # @param value [Integer] the unsigned value
    # @return [Integer] the signed value
    def to_signed(value)
      value = ~value if (value & 1) != 0
      value >>= 1
      value
    end
  end
end
