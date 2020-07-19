<?php

namespace Heremaps\FlexiblePolyline;

use Heremaps\FlexiblePolyline\Traits\DecodableTrait;
use Heremaps\FlexiblePolyline\Traits\EncodableTrait;

class FlexiblePolyline
{

    public const FORMAT_VERSION = 1;
    public const DEFAULT_PRECISION = 5;
    public const ENCODING_TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    public const DECODING_TABLE = [
        62, -1, -1, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
        22, 23, 24, 25, -1, -1, -1, -1, 63, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
        36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51
    ];

    public const ABSENT     = 0;
    public const LEVEL      = 1;
    public const ALTITUDE   = 2;
    public const ELEVATION  = 3;
    public const RESERVED1  = 4;
    public const RESERVED2  = 5;
    public const CUSTOM1    = 6;
    public const CUSTOM2    = 7;

    use DecodableTrait, EncodableTrait;
}
