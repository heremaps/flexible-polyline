# Copyright (C) 2019 HERE Europe B.V.
# Licensed under MIT, see full license in LICENSE
# SPDX-License-Identifier: MIT
# License-Filename: LICENSE

from .encoding import _dict_to_tuple, ABSENT, ALTITUDE, LEVEL, ELEVATION, CUSTOM1, CUSTOM2
from .decoding import THIRD_DIM_MAP, get_third_dimension

from .decoding import iter_decode
from .encoding import encode


def dict_encode(coordinates, precision=5, third_dim=ABSENT, third_dim_precision=0):
    """Encode the sequence of coordinates dicts into a polyline string"""
    return encode(
        _dict_to_tuple(coordinates, third_dim),
        precision=precision,
        third_dim=third_dim,
        third_dim_precision=third_dim_precision
    )


def decode(encoded):
    """Return a list of coordinates. The number of coordinates are 2 or 3
    depending on the polyline content."""
    return list(iter_decode(encoded))


def iter_dict_decode(encoded):
    """Return an iterator over coordinates dicts. The dict contains always the keys 'lat', 'lng' and
    depending on the polyline can contain a third key ('elv', 'lvl', 'alt', ...)."""
    third_dim_key = THIRD_DIM_MAP[get_third_dimension(encoded)]
    for row in iter_decode(encoded):
        yield {
            'lat': row[0],
            'lng': row[1],
            third_dim_key: row[2]
        }


def dict_decode(encoded):
    """Return an list of coordinates dicts. The dict contains always the keys 'lat', 'lng' and
    depending on the polyline can contain a third key ('elv', 'lvl' or 'alt')."""
    return list(iter_dict_decode(encoded))