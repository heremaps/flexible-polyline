# frozen_string_literal: true

module FlexPolyline
  class Encoder
    ENCODING_TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'

    # @param coordinates [Array<Array<Integer>>]
    # @param precision [Integer] how many decimal digits of precision to store the latitude and longitude.
    # @param third_dim [Integer] type of the third dimension if present in the input.
    # @param third_dim_precision [Integer] how many decimal digits of precision to store the third dimension.
    def initialize(coordinates, precision: 5, third_dim: ABSENT, third_dim_precision: 0, format: :array)
      @coordinates = parse_coordinates(coordinates, format: format, third_dim: third_dim)
      @precision = precision
      @third_dim = third_dim
      @third_dim_precision = third_dim_precision
    end

    # Encode a sequence of lat,lng or lat,lng(,third_dim).
    #
    # @return [String]
    def encode
      multiplier_degree = 10**@precision
      multiplier_z = 10**@third_dim_precision

      last_lat = last_lng = last_z = 0

      res = []
      appender = ->(el) { res << el }
      encode_header(appender, @precision, @third_dim, @third_dim_precision)

      @coordinates.each do |location|
        lat = (location[0] * multiplier_degree).round.to_i
        encode_scaled_value(lat - last_lat, appender)
        last_lat = lat

        lng = (location[1] * multiplier_degree).round.to_i
        encode_scaled_value(lng - last_lng, appender)
        last_lng = lng

        next if @third_dim == ABSENT

        z = (location[2] * multiplier_z).round.to_i
        encode_scaled_value(z - last_z, appender)
        last_z = z
      end

      res.join
    end

    private

    def parse_coordinates(coordinates, format: :array, third_dim: ABSENT)
      return coordinates if format == :array

      key = THIRD_DIM_MAP[third_dim]

      coordinates.map do |c|
        if third_dim == ABSENT
          [c[:lat], c[:lng]]
        else
          [c[:lat], c[:lng], c[key]]
        end
      end
    end

    # Uses veriable integer encoding to encode an unsigned integer.
    #
    # Returns the encoded string.
    # @param value [Integer]
    # @param appender [Proc]
    def encode_unsigned_varint(value, appender)
      while value > 0x1F
        pos = (value & 0x1F) | 0x20
        appender.call(ENCODING_TABLE[pos])
        value >>= 5
      end
      appender.call(ENCODING_TABLE[value])
    end

    # Transform a integer `value` into a variable length sequence of characters.
    #
    # @param value [Integer] the value to encode.
    # @param appender [Proc] is a callable where the produced chars will land to
    def encode_scaled_value(value, appender)
      negative = value.negative?

      value = value << 1

      value = ~value if negative

      encode_unsigned_varint(value, appender)
    end

    # Encode the `precision`, `third_dim` and `third_dim_precision` into one
    # encoded char
    #
    # @param appender [Proc]
    # @param precision [Integer]
    # @param third_dim [Integer]
    # @param third_dim_precision [Integer]
    def encode_header(appender, precision, third_dim, third_dim_precision)
      raise ValueError, 'precision out of range' if precision.negative? || precision > 15
      raise ValueError, 'third_dim_precision out of range' if third_dim_precision.negative? || third_dim_precision > 15
      raise ValueError, 'third_dim out of range' if third_dim.negative? || third_dim > 7

      if [4, 5].include?(third_dim)
        FlexPolyline.logger.warn('Third dimension types 4 and 5 are reserved and should not be used ' \
          'as meaning may change in the future')
      end

      res = (third_dim_precision << 7) | (third_dim << 4) | precision

      encode_unsigned_varint(FORMAT_VERSION, appender)
      encode_unsigned_varint(res, appender)
    end
  end
end
