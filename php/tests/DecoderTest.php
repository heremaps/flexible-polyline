<?php

namespace Heremaps\FlexiblePolyline\Tests;

use Heremaps\FlexiblePolyline\FlexiblePolyline;
use Heremaps\FlexiblePolyline\Tests\FlexiblePolylineTest;

class DecoderTest extends FlexiblePolylineTest
{
    public function testLines(): void
    {
        $folders = ['round_half_even', 'round_half_up'];

        foreach($folders as $folder) {
            $this->runFolder($folder);
        }
    }

    public function runFolder(string $folder): void
    {
        $originalLines = self::getOriginalLines();
        $encodedLines = self::getEncodedLines($folder);
        $decodedLines = self::getDecodedLines($folder);

        $results = [];

        for($i = 0; $i < count($encodedLines); $i++)
        {
            $input = self::parseLine($originalLines[$i]);
            $encoded = $encodedLines[$i];
            $decoded = $decodedLines[$i];

            if ($input['thirdDim'] === 4 || $input['thirdDim'] === 5 || $input['thirdDimPrecision'] > 10 || $input['precision'] > 10) {
                // Test decoding only
                $expectedDecoded = self::parseLine($decoded);
                $decodedEncodedValue = FlexiblePolyline::decode($encoded);
                $this->assertEqualsCanonicalizing($expectedDecoded, $decodedEncodedValue);
            } else {
                // Test full
                $expectedDecoded = self::parseLine($decoded);
                $encodedInput = FlexiblePolyline::encode($input['polyline'], $input['precision'], $input['thirdDim'], $input['thirdDimPrecision']);
                $decodedInput = FlexiblePolyline::decode($encodedInput);

                $this->assertEqualsCanonicalizing($expectedDecoded, $decodedInput);
            }
        }
    }

}