# frozen_string_literal: true

require 'logger'
require 'flexpolyline/constants'
require 'flexpolyline/errors'
require 'flexpolyline/decoder'
require 'flexpolyline/encoder'

module FlexPolyline
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.encode(coordinates, precision: 5, third_dim: ABSENT, third_dim_precision: 0, format: :array)
    Encoder.new(
      coordinates, precision: precision, third_dim: third_dim,
                   third_dim_precision: third_dim_precision, format: format
    ).encode
  end

  def self.decode(encoded, format: :array)
    Decoder.new(encoded, format: format).decode
  end

  def self.enum_decode(encoded, format: :array)
    Decoder.new(encoded, format: format).enum_decode
  end

  def self.third_dimension(encoded)
    Decoder.new(encoded).third_dimension
  end
end
