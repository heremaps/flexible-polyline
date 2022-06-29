<?php

namespace Heremaps\FlexiblePolyline\Tests;

use Heremaps\FlexiblePolyline\FlexiblePolyline;
use Heremaps\FlexiblePolyline\Tests\FlexiblePolylineTest;

class OtherTest extends FlexiblePolylineTest
{
    public function testReadmeExampleDecode(): void
    {
        $decoded = FlexiblePolyline::decode('BlBoz5xJ67i1BU1B7PUzIhaUxL7YU');

        $expected = [
            'precision' => 5,
            'thirdDim' => 2,
            'thirdDimPrecision' => 0,
            'polyline' => [
                [50.10228, 8.69821, 10],
                [50.10201, 8.69567, 20],
                [50.10063, 8.6915, 30],
                [50.09878, 8.68752, 40]
            ]
        ];

        $this->assertEqualsCanonicalizing($expected, $decoded);
    }

    public function testReadmeExampleEncode(): void
    {
        $encoded = FlexiblePolyline::encode(
            [
            [50.10228, 8.69821, 10],
            [50.10201, 8.69567, 20],
            [50.10063, 8.6915, 30],
            [50.09878, 8.68752, 40]
            ], 5, 2, 0
        );

        $expected = 'BlBoz5xJ67i1BU1B7PUzIhaUxL7YU';

        $this->assertEquals($expected, $encoded);
    }

    public function testThirdDimension(): void
    {
        $this->assertEquals(FlexiblePolyline::getThirdDimension('BFoz5xJ67i1BU'), FlexiblePolyline::ABSENT);
        $this->assertEquals(FlexiblePolyline::getThirdDimension('BVoz5xJ67i1BU'), FlexiblePolyline::LEVEL);
        $this->assertEquals(FlexiblePolyline::getThirdDimension('BlBoz5xJ67i1BU'), FlexiblePolyline::ALTITUDE);
        $this->assertEquals(FlexiblePolyline::getThirdDimension('B1Boz5xJ67i1BU'), FlexiblePolyline::ELEVATION);
    }

}