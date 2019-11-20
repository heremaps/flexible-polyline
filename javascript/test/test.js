/*
 * Copyright (C) 2019 HERE Europe B.V.
 * Licensed under MIT, see full license in LICENSE
 * SPDX-License-Identifier: MIT
 * License-Filename: LICENSE
 */
const poly = require("../");
const assert = require('assert');
const fs = require('fs');

const originalLines = fs.readFileSync('../test/original.txt', { encoding: 'utf-8' }).split('\n');
const encodedLines = fs.readFileSync('../test/encoded.txt', { encoding: 'utf-8' }).split('\n');
const decodedLines = fs.readFileSync('../test/decoded.txt', { encoding: 'utf-8' }).split('\n');

function runTests() {
    originalLines.forEach((original, index) => {
        if (!original) {
            return;
        }
        const input = parseLine(original);
        if (input.thirdDim === 4 || input.thirdDim === 5 || input.precision > 10 || input.thirdDimPrecision > 10) {
            return;
        }
        const encoded = encodedLines[index];
        const decoded = decodedLines[index].replace(/ /g, '');

        const encodedInput = poly.encode(input);
        assert.strictEqual(encodedInput, encoded);

        const expectedDecoded = parseLine(decoded);
        const resDecoded = poly.decode(encodedInput);
        assert.strictEqual(resDecoded.precision, expectedDecoded.precision);
        assert.strictEqual(resDecoded.thirdDim, expectedDecoded.thirdDim || 0);
        assert.strictEqual(resDecoded.thirdDimPrecision, expectedDecoded.thirdDimPrecision);
        expectedDecoded.polyline.forEach((expectedPos, i0) => {
            expectedPos.forEach((val, i1) => {
                const precision = i1 === 2 ? resDecoded.thirdDimPrecision : resDecoded.precision;
                assert(approxEq(val, resDecoded.polyline[i0][i1], 1 / (10 ** precision)));
            });
        });
    });
}

runTests();

function parseLine(line) {
    // Strip off all spaces, curly braces, square brackets and trailing comma
    const [rawHeader, rawPolyline] = line.replace(/[ {}\[\]]/g, '').slice(0, -1).split(';');
    const [precision, thirdDimPrecision, thirdDim] = rawHeader.slice(1, -1).split(',').map((num) => num ? +num : undefined);
    const polyline = rawPolyline.split('),(').map((rawLocation) => {
        return rawLocation.replace(/[()]/g, '').split(',').map((num) => +num);
    });

    return { precision, thirdDim, thirdDimPrecision, polyline };
}

function approxEq(v1, v2, epsilon) {
    if (epsilon == null) {
        epsilon = 0.001;
    }
    return Math.abs(v1 - v2) < epsilon;
}

console.log('Tests succeeded');
