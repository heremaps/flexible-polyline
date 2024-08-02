#!/usr/bin/env node

/*
 * Copyright (C) 2024 HERE Europe B.V.
 * Licensed under MIT, see full license in LICENSE
 * SPDX-License-Identifier: MIT
 * License-Filename: LICENSE
 */

const fs = require('fs');
const { encode, decode } = require('./index');

const param = process.argv[2];

if (param?.includes('help')) {
    console.log('Usage:', process.argv[0], process.argv[1], '[OPTION]');
    console.log();
    console.log('Encodes or decodes flexible polylines from stdin to stdout')
    console.log();
    console.log('Options:');
    console.log('    decode: Decode the input polyline. Default is to encode');
    console.log('    --help: Display this help message');
    console.log();
    console.log('Input:');
    console.log('    encoding: The input is either a JSON array of coordinates or a JSON object that can be passed directly to the "encode" function');
    console.log('    decoding: The input is a string of an encoded polyline');
    process.exit(0);
}

const isDecoding = param === 'decode';

try {
    if (isDecoding) {
        const input = fs.readFileSync(0, 'utf-8').trim();
        const decoded = decode(input);
        process.stdout.write(JSON.stringify(decoded.polyline));
        process.stdout.write('\n');
    } else {
        const input = JSON.parse(fs.readFileSync(0, 'utf-8'));
        const encoded = encode(Array.isArray(input) ? { polyline: input } : input);
        process.stdout.write(encoded);
        process.stdout.write('\n');
    }
} catch (e) {
    console.error(e);
    process.exit(1);
}
