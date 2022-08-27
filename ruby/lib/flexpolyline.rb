# frozen_string_literal: true

require 'logger'
require 'flexpolyline/constants'
require 'flexpolyline/decoder'
require 'flexpolyline/encoder'

# The FlexPolyline module provides functionality for encoding and decoding
module FlexPolyline
  # Get the current logger. Default: `Logger.new(STDOUT)`.
  #
  # @return [Logger]
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  # Set the logger.
  #
  # @param logger [Logger]
  # @return [Logger]
  def self.logger=(logger)
    @logger = logger
  end

  # Encodes a sequence of [lat, lng] or [lat, lng ,third_dim] into a polyline string.
  #
  # @param coordinates [Array<Array<Numeric>>, Array<Hash>] the coordinates to encode.
  # @param precision [Integer] how many decimal digits of precision to store the latitude and longitude.
  # @param third_dim [Integer] type of the third dimension if present in the input.
  # @param third_dim_precision [Integer] how many decimal digits of precision to store the third dimension.
  # @param format [:hash, :array] the format. Acceptable values: :hash, :array.
  # @return [String]
  # @raise [ArgumentError] if the `precision` is not in the range [0, 15]
  # @raise [ArgumentError] if the `third_dim_precision` is not in the range [0, 15]
  # @raise [ArgumentError] if the `third_dim` is not in the range [0, 7]
  def self.encode(coordinates, precision: 5, third_dim: ABSENT, third_dim_precision: 0, format: :array)
    Encoder.new(
      coordinates, precision: precision, third_dim: third_dim,
                   third_dim_precision: third_dim_precision, format: format
    ).encode
  end

  # Decodes a polyline string into a sequence of [lat, lng] or [lat, lng ,third_dim].
  #
  # @param encoded [String] input polyline string.
  # @param format [:hash, :array] the output format. Acceptable values: :hash, :array.
  # @return [Array<Array<Numeric>>, Array<Hash>]
  def self.decode(encoded, format: :array)
    Decoder.new(encoded, format: format).decode
  end

  # Decodes a polyline string into a sequence of [lat, lng] or [lat, lng ,third_dim]. It yields each decoded block or returns an enumerator.
  #
  # @param encoded [String] input polyline string.
  # @param format [:hash, :array] the output format. Acceptable values: :hash, :array.
  # @yield [[Array<Numeric>, Hash]]
  # @return [Enumerator<Array<Numeric>>, Enumerator<Hash>]
  def self.decode_each(encoded, format: :array, &block)
    Decoder.new(encoded, format: format).decode_each(&block)
  end

  # Return the third dimension of an encoded polyline. Possible returned values are: ABSENT, LEVEL, ALTITUDE, ELEVATION, CUSTOM1, CUSTOM2.
  #
  # @param encoded [String] input polyline string.
  # @return [Integer] type of the third dimension.
  def self.third_dimension(encoded)
    Decoder.new(encoded).third_dimension
  end
end
