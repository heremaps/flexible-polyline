# Copyright (C) 2019 HERE Europe B.V.
# Licensed under MIT, see full license in LICENSE
# SPDX-License-Identifier: MIT
# License-Filename: LICENSE

from collections import namedtuple

from .encoding import THIRD_DIM_MAP, FORMAT_VERSION

__all__ = [
    'decode', 'dict_decode', 'iter_decode',
    'get_third_dimension', 'decode_header', 'PolylineHeader'
]

DECODING_TABLE = [
    62, -1, -1, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1,
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, -1, -1, -1, -1, 63, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
    36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51
]


PolylineHeader = namedtuple('PolylineHeader', 'precision,third_dim,third_dim_precision')


def decode_header(decoder):
    """Decode the polyline header from an `encoded_char`. Returns a PolylineHeader object."""
    version = next(decoder)
    if version != FORMAT_VERSION:
        raise ValueError('Invalid format version')
    value = next(decoder)
    precision = value & 15
    value >>= 4
    third_dim = value & 7
    third_dim_precision = (value >> 3) & 15
    return PolylineHeader(precision, third_dim, third_dim_precision)


def get_third_dimension(encoded):
    """Return the third dimension of an encoded polyline.
    Possible returned values are: ABSENT, LEVEL, ALTITUDE, ELEVATION, CUSTOM1, CUSTOM2."""
    header = decode_header(decode_unsigned_values(encoded))
    return header.third_dim


def decode_char(char):
    """Decode a single char to the corresponding value"""
    char_value = ord(char)

    try:
        value = DECODING_TABLE[char_value - 45]
    except IndexError:
        raise ValueError('Invalid encoding')
    if value < 0:
        raise ValueError('Invalid encoding')
    return value


def to_signed(value):
    """Decode the sign from an unsigned value"""
    if value & 1:
        value = ~value
    value >>= 1
    return value


def decode_unsigned_values(encoded):
    """Return an iterator over encoded unsigned values part of an `encoded` polyline"""
    result = shift = 0

    for char in encoded:
        value = decode_char(char)

        result |= (value & 0x1F) << shift
        if (value & 0x20) == 0:
            yield result
            result = shift = 0
        else:
            shift += 5

    if shift > 0:
        raise ValueError('Invalid encoding')


def iter_decode(encoded):
    """Return an iterator over coordinates. The number of coordinates are 2 or 3
    depending on the polyline content."""

    last_lat = last_lng = last_z = 0
    decoder = decode_unsigned_values(encoded)

    header = decode_header(decoder)
    factor_degree = 10.0 ** header.precision
    factor_z = 10.0 ** header.third_dim_precision
    third_dim = header.third_dim

    while True:
        try:
            last_lat += to_signed(next(decoder))
        except StopIteration:
            return  # sequence completed

        try:
            last_lng += to_signed(next(decoder))

            if third_dim:
                last_z += to_signed(next(decoder))
                yield (last_lat / factor_degree, last_lng / factor_degree, last_z / factor_z)
            else:
                yield (last_lat / factor_degree, last_lng / factor_degree)
        except StopIteration:
            raise ValueError("Invalid encoding. Premature ending reached")
