<?php

namespace Heremaps\FlexiblePolyline\Tests;

use Heremaps\FlexiblePolyline\FlexiblePolyline;
use Heremaps\FlexiblePolyline\Tests\FlexiblePolylineTest;

class EncoderTest extends FlexiblePolylineTest
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

        $results = [];

        for($i = 0; $i < count($encodedLines); $i++) {
            $input = self::parseLine($originalLines[$i]);
            $encodedInput = $encodedLines[$i];
            
            if ($input['thirdDim'] === 4 || $input['thirdDim'] === 5 || $input['thirdDimPrecision'] > 10 || $input['precision'] > 10) {
                continue;
            }

            $encodedResult = FlexiblePolyline::encode($input['polyline'], $input['precision'], $input['thirdDim'], $input['thirdDimPrecision']);
            
            $this->assertEquals($encodedInput, $encodedResult);
        }
    }

}