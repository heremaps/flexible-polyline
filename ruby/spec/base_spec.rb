# frozen_string_literal: true

require 'spec_helper'

describe FlexPolyline do
  it 'basic encoding' do
    input = [
      [50.1022829, 8.6982122],
      [50.1020076, 8.6956695],
      [50.1006313, 8.6914960],
      [50.0987800, 8.6875156]
    ]

    res = described_class.encode(input)
    expect(res).to eq('BFoz5xJ67i1B1B7PzIhaxL7Y')
  end

  it 'dictionary encoding' do
    input = [
      { lat: 50.1022829, lng: 8.6982122 },
      { lat: 50.1020076, lng: 8.6956695 },
      { lat: 50.1006313, lng: 8.6914960 },
      { lat: 50.0987800, lng: 8.6875156 }
    ]

    res = described_class.encode(input, format: :hash)
    expect(res).to eq('BFoz5xJ67i1B1B7PzIhaxL7Y')
  end

  it 'encoding with ALTITUDE' do
    input = [
      [50.1022829, 8.6982122, 10],
      [50.1020076, 8.6956695, 20],
      [50.1006313, 8.6914960, 30],
      [50.0987800, 8.6875156, 40]
    ]
    res = described_class.encode(input, third_dim: described_class::ALTITUDE)
    expect(res).to eq('BlBoz5xJ67i1BU1B7PUzIhaUxL7YU')
  end

  it 'encoding with ELEVATION' do
    input = [
      [50.1022829, 8.6982122, 10],
      [50.1020076, 8.6956695, 20],
      [50.1006313, 8.6914960, 30],
      [50.0987800, 8.6875156, 40]
    ]
    res = described_class.encode(input, third_dim: described_class::ELEVATION)
    expect(res).to eq('B1Boz5xJ67i1BU1B7PUzIhaUxL7YU')
  end

  it 'complex encoding' do
    input = [
      [52.5199356, 13.3866272],
      [52.5100899, 13.2816896],
      [52.4351807, 13.1935196],
      [52.4107285, 13.1964502],
      [52.38871, 13.1557798],
      [52.3727798, 13.1491003],
      [52.3737488, 13.1154604],
      [52.3875198, 13.0872202],
      [52.4029388, 13.0706196],
      [52.4105797, 13.0755529]
    ]

    res = described_class.encode(input)

    expect(res).to eq('BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e')
  end

  it 'fails with invalid encoding' do
    expect do
      described_class.decode('BFoz5xJ67i1B1B7PzIhaxL7')
    end.to raise_error(ArgumentError)

    expect do
      described_class.decode('CFoz5xJ67i1B1B7PzIhaxL7')
    end.to raise_error(ArgumentError)
  end

  it 'decoding each' do
    expected = [
      [50.10228, 8.69821],
      [50.10201, 8.69567],
      [50.10063, 8.69150],
      [50.09878, 8.68752]
    ]

    described_class.decode_each('BFoz5xJ67i1B1B7PzIhaxL7Y').with_index do |row, i|
      expect(row[0]).to be_within(0.000001).of(expected[i][0])
      expect(row[1]).to be_within(0.000001).of(expected[i][1])
    end
  end

  it 'array decoding' do
    input = 'BlBoz5xJ67i1BU1B7PUzIhaUxL7YU'
    res = described_class.decode(input)
    expected = [
      [50.10228, 8.69821],
      [50.10201, 8.69567],
      [50.10063, 8.69150],
      [50.09878, 8.6875]
    ]

    expected.each_with_index do |row, i|
      expect(row[0]).to be_within(0.0001).of(res[i][0])
      expect(row[1]).to be_within(0.0001).of(res[i][1])
    end
  end

  it 'dictionary decoding' do
    input = 'BlBoz5xJ67i1BU1B7PUzIhaUxL7YU'
    res = described_class.decode(input, format: :hash)
    expected = [
      { lat: 50.10228, lng: 8.69821, alt: 10 },
      { lat: 50.10201, lng: 8.69567, alt: 20 },
      { lat: 50.10063, lng: 8.69150, alt: 30 },
      { lat: 50.09878, lng: 8.68752, alt: 40 }
    ]

    expected.each_with_index do |row, i|
      expect(row[:lat]).to be_within(0.00001).of(res[i][:lat])
      expect(row[:lng]).to be_within(0.00001).of(res[i][:lng])
      expect(row[:alt]).to be_within(0.00001).of(res[i][:alt])
    end
  end

  it 'complex decoding' do
    polyline = described_class.decode('BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e')
    expected = [
      [52.51994, 13.38663],
      [52.51009, 13.28169],
      [52.43518, 13.19352],
      [52.41073, 13.19645],
      [52.38871, 13.15578],
      [52.37278, 13.14910],
      [52.37375, 13.11546],
      [52.38752, 13.08722],
      [52.40294, 13.07062],
      [52.41058, 13.07555]
    ]
    expected.each_with_index do |(lat, lng), i|
      expect(lat).to be_within(0.00001).of(polyline[i][0])
      expect(lng).to be_within(0.00001).of(polyline[i][1])
    end
  end

  it '#third_dimension' do
    expect(described_class.third_dimension('BFoz5xJ67i1BU')).to eq(described_class::ABSENT)
    expect(described_class.third_dimension('BVoz5xJ67i1BU')).to eq(described_class::LEVEL)
    expect(described_class.third_dimension('BlBoz5xJ67i1BU')).to eq(described_class::ALTITUDE)
    expect(described_class.third_dimension('B1Boz5xJ67i1BU')).to eq(described_class::ELEVATION)
  end
end
