/*
 * Copyright (C) 2024 HERE Europe B.V.
 * Licensed under MIT, see full license in LICENSE
 * SPDX-License-Identifier: MIT
 * License-Filename: LICENSE
 */

export const ABSENT = 0;
export const LEVEL = 1;
export const ALTITUDE = 2;
export const ELEVATION = 3;

export interface Header {
    precision: number,
    thirdDim: typeof ABSENT | typeof LEVEL | typeof ALTITUDE | typeof ELEVATION,
    thirdDimPrecision: number,
}

export interface DecodedResult extends Header {
    polyline: Array<Array<number>>
}

export declare function decode(encoded: string): DecodedResult;

export interface EncodeParameters extends Partial<Header> {
    polyline: Array<Array<number>>
}

export declare function encode(params: EncodeParameters): string;
