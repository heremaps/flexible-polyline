<?php

/**
 * Flexible Polyline Encoder
 *
 * @package FlexiblePolyline
 */

namespace Heremaps\FlexiblePolyline\Traits;

use Exception;

trait EncodableTrait
{
    
    public static function encode(
        array $coordinates,
        int $precision = null,
        int $thirdDim = null,
        int $thirdDimPrecision = 0
    ): string {
        if (is_null($precision)) {
            $precision = self::DEFAULT_PRECISION;
        }

        $multiplierDegree = 10 ** $precision;
        $multiplierZ = 10 ** $thirdDimPrecision;
        $encodedHeaderList = self::encodeHeader($precision, $thirdDim, $thirdDimPrecision);
        $encodedCoords = [];
    
        $lastLat = 0;
        $lastLng = 0;
        $lastZ = 0;

        foreach ($coordinates as $location) {
            $lat = (int)round($location[0] * $multiplierDegree);
            $encodedCoords[] = self::encodeScaledValue($lat - $lastLat);
            $lastLat = $lat;
    
            $lng = (int)round($location[1] * $multiplierDegree);
            $encodedCoords[] = self::encodeScaledValue($lng - $lastLng);
            $lastLng = $lng;
    
            if ($thirdDim) {
                $z = (int)round($location[2] * $multiplierZ);
                $encodedCoords[] = self::encodeScaledValue($z - $lastZ);
                $lastZ = $z;
            }
        };

        return implode('', array_merge([$encodedHeaderList], $encodedCoords));
    }

    public static function encodeHeader(int $precision, int $thirdDim, int $thirdDimPrecision): string
    {
        if ($precision < 0 || $precision > 15) {
            throw new Exception('precision out of range. Should be between 0 and 15');
        }
        if ($thirdDimPrecision < 0 || $thirdDimPrecision > 15) {
            throw new Exception('thirdDimPrecision out of range. Should be between 0 and 15');
        }
        if ($thirdDim < 0 || $thirdDim > 7 || $thirdDim === 4 || $thirdDim === 5) {
            throw new Exception('thirdDim should be between 0, 1, 2, 3, 6 or 7');
        }
    
        $res = ($thirdDimPrecision << 7) | ($thirdDim << 4) | $precision;
        return self::encodeUnsignedNumber(self::FORMAT_VERSION) . self::encodeUnsignedNumber($res);
    }
    
    public static function encodeUnsignedNumber(float $val): string
    {
        $res = '';
        $numVal = (float)$val;
        while ($numVal > 0x1F) {
            $pos = ($numVal & 0x1F) | 0x20;
            $pos = (int)$pos;
            $res .= self::ENCODING_TABLE[$pos];
            $numVal >>= 5;
        }
        $numVal = (int)$numVal;
        return $res . self::ENCODING_TABLE[$numVal];
    }

    public static function encodeScaledValue(float $value): string
    {
        $negative = $value < 0;
        $value <<= 1;
        if ($negative) {
            $value = ~$value;
        }
    
        return self::encodeUnsignedNumber($value);
    }
}
