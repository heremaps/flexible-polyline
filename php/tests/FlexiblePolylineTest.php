<?php

namespace Heremaps\FlexiblePolyline\Tests;

use PHPUnit\Framework\TestCase;

abstract class FlexiblePolylineTest extends TestCase
{
    protected static function getFilepath(string $relativePath): string
    {
        return sprintf(__DIR__ . '/../../test/%s', $relativePath);
    }

    protected static function getOriginalLines(): array
    {
        return self::getLinesFromTestFile('original.txt');
    }

    protected static function getEncodedLines(string $folder = 'round_half_even'): array
    {
        return self::getLinesFromTestFile('round_half_even/encoded.txt');
    }

    protected static function getDecodedLines(string $folder = 'round_half_even'): array
    {
        return self::getLinesFromTestFile('round_half_even/decoded.txt');
    }

    protected static function getLinesFromTestFile(string $filepath): array
    {
        return self::getLines(self::getFilepath($filepath));
    }

    protected static function getLines(string $filepath): array
    {
        return array_filter(explode("\n", file_get_contents($filepath)));
    }

    protected static function parseLine(string $line): array 
    {
        list($rawHeader, $rawPolyline) = explode(';', preg_replace('/[ {}\[\]]/', '', $line));
        list($precision, $thirdDimPrecision, $thirdDim) = array_replace(
            [0, 0, 0], array_map(
                function ($value) {
                    return (int)$value ?: 0;
                }, explode(',', trim($rawHeader, '()'))
            )
        );
        $polyline = array_map(
            function ($point) use ($thirdDim) {
                $coordinates = array_map(
                    function ($coordinate) { 
                        return (float)$coordinate ?: null;
                    }, explode(',', preg_replace('/[()]/', '', $point))
                );
                $values = array_map(
                    function ($coordinate) {
                        return is_null($coordinate) ? 0 : $coordinate;
                    }, $coordinates
                );
                return array_slice($values, 0, $thirdDim ? 3 : 2);
            }, explode('),(', $rawPolyline)
        );
        return compact('precision', 'thirdDim', 'thirdDimPrecision', 'polyline');
    }
}