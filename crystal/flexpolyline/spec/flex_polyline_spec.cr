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
require "spec"
require "../src/flexpolyline.cr"

include PolylineEncoderDecoder

describe "Flexible Polyline" do
  it "Has a Lat, Lon, Alt class" do
    llz = LatLngZ.new(1.0, 2.0, 3.0)
    llz.lat.should eq 1.0
    llz.lng.should eq 2.0
    llz.z.should eq 3.0
    llzB = LatLngZ.new(4.0, 5.0)
    llzB.lat.should eq 4.0
    llzB.lng.should eq 5.0
    llzB.z.should eq Float64::MIN
    (llz == llzB).should be_false
    llzC = LatLngZ.new(1.0, 2.0, 3.0)
    (llz == llzC).should be_true
  end

  it "Encodes lines" do
    encodedLines = File.read_lines("../../test/round_half_up/encoded.txt")
    decodedLines = File.read_lines("../../test/round_half_up/decoded.txt")
    encodedLines.each_with_index do |encodedAnswer, index|
      begin
        fplAnswer = parseDecoded(decodedLines[index])
        encoded = encode(fplAnswer)
        if encoded != encodedAnswer
          # Whelp we have a problem, let's see if it is in the noise.
          # Answers were generated with different languages and math impls.
          # We will check the decoded value to make sure it matches
          # within the precision and limits of double precision floats.
          puts "Notice: encoding not identical in test #{index}. Decoded value will be tested instead."
          puts "Expected: #{encodedAnswer}"
          puts "Actual:   #{encoded}"
          errorBar = String.build do |str|
            str << "          "
            encoded.each_char_with_index do |char, index|
              if char == encodedAnswer[index]?
                str << "-"
              else
                str << "^"
              end
            end
          end
          puts errorBar

          fplDecoded = decode(encoded)
          (fplAnswer == fplDecoded).should be_true
        end
      rescue ex
        puts "Error encoding test #{index} : #{encodedAnswer}"
        raise ex
      end
    end
  end

  it "Decodes lines" do
    encodedLines = File.read_lines("../../test/round_half_up/encoded.txt")
    decodedLines = File.read_lines("../../test/round_half_up/decoded.txt")
    encodedLines.each_with_index do |encodedAnswer, index|
      begin
        # decode the line
        fplDecodeAttempt = decode(encodedAnswer)
        # get what the line should be
        fplExpected = parseDecoded(decodedLines[index])
        if fplDecodeAttempt != fplExpected
          puts "Error decoding test #{index} : #{encodedAnswer}"
          puts fplDecodeAttempt.to_s
          puts fplExpected.to_s
        end
        (fplDecodeAttempt == fplExpected).should be_true
      rescue ex
        puts "Error decoding test #{index} : #{encodedAnswer}"
        raise ex
      end
    end
  end

  it "Helps me with line decoding" do
    decode = SimpleStringReader.new("Test")
    decode.hasMore.should be_true
    decode.next.should eq 'T'
    decode.next.should eq 'e'
    decode.next.should eq 's'
    decode.hasMore.should be_true
    decode.next.should eq 't'
    decode.hasMore.should be_false
  end

  it "converts chars to 6 bit values or -1" do
    decodeChar('A').should eq 0
    decodeChar('a').should eq 26
    expect_raises(Exception) do
      decodeChar('[')
    end
    expect_raises(Exception) do
      decodeChar('$')
    end
  end

  it "rounds floating points nicely when it converts to int" do
    getScaled(1.2345, 1.0).should eq 1
    getScaled(1.2345, 100000.0).should eq 123450
    getScaled(1.5, 1.0).should eq 2
    getScaled(1.49, 1.0).should eq 1
    getScaled(1.5, 10.0).should eq 15
    getScaled(1.49, 10.0).should eq 15
    getScaled(-1.5, 1.0).should eq -2
    getScaled(-1.49, 1.0).should eq -1
    getScaled(-1.2345, 100.0).should eq -123
  end
end

# Returns a FlexiblePolyline instance initialized with the test data
def parseDecoded(decodedLine)
  output = decodedLine.strip[1..-2].split(';')
  meta = output[0].strip[1..-2].split(',')
  fpl = FlexiblePolyline.new
  fpl.precision = meta[0].to_i8
  if meta[1]?
    fpl.thirdDimPrecision = meta[1].to_i8
    fpl.thirdDimension = ThirdDimension.new(meta[2].to_i)
  end

  output[1].strip[1..-2].split("),").each do |location|
    next if location.strip.empty?
    values = location.strip[1..-1].split(',')
    if fpl.thirdDimension != ThirdDimension::ABSENT
      fpl.coordinates << LatLngZ.new(values[0].to_f, values[1].to_f, values[2].to_f)
    else
      fpl.coordinates << LatLngZ.new(values[0].to_f, values[1].to_f)
    end
  end
  return fpl
end
