#![doc = include_str!("../README.md")]
#![doc(html_playground_url = "https://play.rust-lang.org/")]
#![deny(warnings, missing_docs)]
#![allow(clippy::unreadable_literal)]

/// Coordinate precision in the polyline
///
/// Represents how many digits are to be encoded after the decimal point, e.g.
/// precision 3 would encode 4.456787 as 4.457.
///
/// Supported values: `[0,16)`
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Precision {
    /// 0 decimal digits
    Digits0 = 0,
    /// 1 decimal digits
    Digits1 = 1,
    /// 2 decimal digits
    Digits2 = 2,
    /// 3 decimal digits
    Digits3 = 3,
    /// 4 decimal digits
    Digits4 = 4,
    /// 5 decimal digits
    Digits5 = 5,
    /// 6 decimal digits
    Digits6 = 6,
    /// 7 decimal digits
    Digits7 = 7,
    /// 8 decimal digits
    Digits8 = 8,
    /// 9 decimal digits
    Digits9 = 9,
    /// 10 decimal digits
    Digits10 = 10,
    /// 11 decimal digits
    Digits11 = 11,
    /// 12 decimal digits
    Digits12 = 12,
    /// 13 decimal digits
    Digits13 = 13,
    /// 14 decimal digits
    Digits14 = 14,
    /// 15 decimal digits
    Digits15 = 15,
}

impl Precision {
    /// Converts `u32` to precision.
    pub fn from_u32(digits: u32) -> Option<Precision> {
        match digits {
            0 => Some(Precision::Digits0),
            1 => Some(Precision::Digits1),
            2 => Some(Precision::Digits2),
            3 => Some(Precision::Digits3),
            4 => Some(Precision::Digits4),
            5 => Some(Precision::Digits5),
            6 => Some(Precision::Digits6),
            7 => Some(Precision::Digits7),
            8 => Some(Precision::Digits8),
            9 => Some(Precision::Digits9),
            10 => Some(Precision::Digits10),
            11 => Some(Precision::Digits11),
            12 => Some(Precision::Digits12),
            13 => Some(Precision::Digits13),
            14 => Some(Precision::Digits14),
            15 => Some(Precision::Digits15),
            _ => None,
        }
    }

    /// Converts precision to `u32`.
    pub fn to_u32(self) -> u32 {
        self as u32
    }
}

/// Informs about the type of the 3rd dimension of a 3D coordinate vector
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Type3d {
    /// E.g. floor of a building
    Level = 1,
    /// E.g. altitude (in the air) relative to ground level or mean sea level
    Altitude = 2,
    /// E.g. elevation above mean-sea-level
    Elevation = 3,
    /// Reserved for future types
    Reserved1 = 4,
    /// Reserved for future types
    Reserved2 = 5,
    /// Reserved for custom types
    Custom1 = 6,
    /// Reserved for custom types
    Custom2 = 7,
}

/// 2- or 3-dimensional polyline
#[derive(Debug, Clone, PartialEq)]
pub enum Polyline {
    /// 2-dimensional polyline
    Data2d {
        /// List of 2D coordinates making up this polyline
        coordinates: Vec<(f64, f64)>,
        /// Precision of the coordinates (e.g. used for encoding,
        /// or to report the precision supplied in encoded data)
        precision2d: Precision,
    },
    /// 3-dimensional polyline
    Data3d {
        /// List of 3D coordinates making up this polyline
        coordinates: Vec<(f64, f64, f64)>,
        /// Precision of the 2D part of the coordinates (e.g. used for encoding,
        /// or to report the precision supplied in encoded data)
        precision2d: Precision,
        /// Precision of the 3D part of the coordinates (e.g. used for encoding,
        /// or to report the precision supplied in encoded data)
        precision3d: Precision,
        /// Type of the 3D component
        type3d: Type3d,
    },
}

impl std::fmt::Display for Polyline {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            Polyline::Data2d {
                coordinates,
                precision2d,
            } => {
                let prec_2d = f.precision().unwrap_or(precision2d.to_u32() as usize);
                write!(f, "{{({}); [", precision2d.to_u32())?;
                for coord in coordinates {
                    write!(
                        f,
                        "({:.*}, {:.*}), ",
                        { prec_2d },
                        coord.0,
                        { prec_2d },
                        coord.1
                    )?;
                }
                write!(f, "]}}")?;
            }
            Polyline::Data3d {
                coordinates,
                precision2d,
                precision3d,
                type3d,
            } => {
                let prec_2d = f.precision().unwrap_or(precision2d.to_u32() as usize);
                let prec_3d = f.precision().unwrap_or(precision3d.to_u32() as usize);
                write!(
                    f,
                    "{{({}, {}, {}); [",
                    precision2d.to_u32(),
                    precision3d.to_u32(),
                    *type3d as usize
                )?;
                for coord in coordinates {
                    write!(
                        f,
                        "({:.*}, {:.*}, {:.*}), ",
                        { prec_2d },
                        coord.0,
                        { prec_2d },
                        coord.1,
                        { prec_3d },
                        coord.2
                    )?;
                }
                write!(f, "]}}")?;
            }
        }
        Ok(())
    }
}

/// Error reported when encoding or decoding polylines
#[derive(Debug, PartialEq, Eq)]
#[non_exhaustive]
pub enum Error {
    /// Data is encoded with unsupported version
    UnsupportedVersion,
    /// Precision is not supported by encoding
    InvalidPrecision,
    /// Encoding is corrupt
    InvalidEncoding,
}

impl std::fmt::Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            Error::UnsupportedVersion => write!(f, "UnsupportedVersion"),
            Error::InvalidPrecision => write!(f, "InvalidPrecision"),
            Error::InvalidEncoding => write!(f, "InvalidEncoding"),
        }
    }
}

impl std::error::Error for Error {}

impl Polyline {
    /// Encodes a polyline into a string.
    ///
    /// The precision of the polyline is used to round coordinates, so the transformation is lossy
    /// in nature.
    pub fn encode(&self) -> Result<String, Error> {
        match self {
            Polyline::Data2d {
                coordinates,
                precision2d,
            } => encode_2d(coordinates, precision2d.to_u32()),
            Polyline::Data3d {
                coordinates,
                precision2d,
                precision3d,
                type3d,
            } => encode_3d(
                coordinates,
                precision2d.to_u32(),
                precision3d.to_u32(),
                *type3d as u32,
            ),
        }
    }

    /// Decodes an encoded polyline.
    pub fn decode<S: AsRef<str>>(encoded: S) -> Result<Self, Error> {
        let mut bytes = encoded.as_ref().bytes();

        let (precision2d, precision3d, type3d) = decode_header(&mut bytes)?;

        let type3d = match type3d {
            1 => Some(Type3d::Level),
            2 => Some(Type3d::Altitude),
            3 => Some(Type3d::Elevation),
            4 => Some(Type3d::Reserved1),
            5 => Some(Type3d::Reserved2),
            6 => Some(Type3d::Custom1),
            7 => Some(Type3d::Custom2),
            0 => None,
            _ => panic!(), // impossible, we only decoded 3 bits
        };

        if let Some(type3d) = type3d {
            let coordinates = decode3d(bytes, precision2d, precision3d)?;
            Ok(Polyline::Data3d {
                coordinates,
                precision2d: Precision::from_u32(precision2d).ok_or(Error::InvalidPrecision)?,
                precision3d: Precision::from_u32(precision3d).ok_or(Error::InvalidPrecision)?,
                type3d,
            })
        } else {
            let coordinates = decode2d(bytes, precision2d)?;
            Ok(Polyline::Data2d {
                coordinates,
                precision2d: Precision::from_u32(precision2d).ok_or(Error::InvalidPrecision)?,
            })
        }
    }
}

fn precision_to_scale(precision: u32) -> impl Fn(f64) -> i64 {
    let scale = 10_u64.pow(precision) as f64;
    move |value: f64| (value * scale).round() as i64
}

fn precision_to_inverse_scale(precision: u32) -> impl Fn(i64) -> f64 {
    let scale = 10_u64.pow(precision) as f64;
    move |value: i64| value as f64 / scale
}

fn encode_header(
    precision2d: u32,
    precision3d: u32,
    type3d: u32,
    result: &mut String,
) -> Result<(), Error> {
    if precision2d > 15 || precision3d > 15 {
        return Err(Error::InvalidPrecision);
    }
    var_encode_u64(1, result); // Version 1
    let header = (precision3d << 7) | (type3d << 4) | precision2d;
    var_encode_u64(u64::from(header), result);
    Ok(())
}

fn encode_2d(coords: &[(f64, f64)], precision2d: u32) -> Result<String, Error> {
    let mut result = String::with_capacity((coords.len() * 2) + 2);

    encode_header(precision2d, 0, 0, &mut result)?;
    let scale2d = precision_to_scale(precision2d);

    let mut last_coord = (0, 0);
    for coord in coords {
        let scaled_coord = (scale2d(coord.0), scale2d(coord.1));
        var_encode_i64(scaled_coord.0 - last_coord.0, &mut result);
        var_encode_i64(scaled_coord.1 - last_coord.1, &mut result);
        last_coord = scaled_coord;
    }

    Ok(result)
}

fn encode_3d(
    coords: &[(f64, f64, f64)],
    precision2d: u32,
    precision3d: u32,
    type3d: u32,
) -> Result<String, Error> {
    let mut result = String::with_capacity((coords.len() * 3) + 2);

    encode_header(precision2d, precision3d, type3d, &mut result)?;
    let scale2d = precision_to_scale(precision2d);
    let scale3d = precision_to_scale(precision3d);

    let mut last_coord = (0, 0, 0);
    for coord in coords {
        let scaled_coord = (scale2d(coord.0), scale2d(coord.1), scale3d(coord.2));
        var_encode_i64(scaled_coord.0 - last_coord.0, &mut result);
        var_encode_i64(scaled_coord.1 - last_coord.1, &mut result);
        var_encode_i64(scaled_coord.2 - last_coord.2, &mut result);
        last_coord = scaled_coord;
    }

    Ok(result)
}

fn var_encode_i64(value: i64, result: &mut String) {
    // make room on lowest bit
    let mut encoded = (value << 1) as u64;

    // invert bits if the value is negative
    if value < 0 {
        encoded = !encoded;
    }

    var_encode_u64(encoded, result);
}

fn var_encode_u64(mut value: u64, result: &mut String) {
    const ENCODING_TABLE: &str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    // var-length encode the number in chunks of 5 bits starting with the least significant
    // to the most significant
    while value > 0x1F {
        let pos = (value & 0x1F) | 0x20;
        let c = ENCODING_TABLE.as_bytes()[pos as usize] as char;
        result.push(c);
        value >>= 5;
    }
    let c = ENCODING_TABLE.as_bytes()[value as usize] as char;
    result.push(c);
}

fn decode_header<I: Iterator<Item = u8>>(bytes: &mut I) -> Result<(u32, u32, u32), Error> {
    let version = var_decode_u64(bytes)?;

    if version != 1 {
        return Err(Error::UnsupportedVersion);
    }

    let header = var_decode_u64(bytes)?;

    if header >= (1_u64 << 11) {
        return Err(Error::InvalidEncoding);
    }
    let precision2d = (header & 15) as u32;
    let type3d = ((header >> 4) & 7) as u32;
    let precision3d = ((header >> 7) & 15) as u32;

    Ok((precision2d, precision3d, type3d))
}

fn decode2d<I: ExactSizeIterator<Item = u8>>(
    mut bytes: I,
    precision2d: u32,
) -> Result<Vec<(f64, f64)>, Error> {
    let mut result = Vec::with_capacity(bytes.len() / 2);
    let scale2d = precision_to_inverse_scale(precision2d);
    let mut last_coord = (0, 0);
    while bytes.len() > 0 {
        let delta = (var_decode_i64(&mut bytes)?, var_decode_i64(&mut bytes)?);
        last_coord = (last_coord.0 + delta.0, last_coord.1 + delta.1);

        result.push((scale2d(last_coord.0), scale2d(last_coord.1)));
    }
    Ok(result)
}

fn decode3d<I: ExactSizeIterator<Item = u8>>(
    mut bytes: I,
    precision2d: u32,
    precision3d: u32,
) -> Result<Vec<(f64, f64, f64)>, Error> {
    let mut result = Vec::with_capacity(bytes.len() / 2);
    let scale2d = precision_to_inverse_scale(precision2d);
    let scale3d = precision_to_inverse_scale(precision3d);
    let mut last_coord = (0, 0, 0);
    while bytes.len() > 0 {
        let delta = (
            var_decode_i64(&mut bytes)?,
            var_decode_i64(&mut bytes)?,
            var_decode_i64(&mut bytes)?,
        );
        last_coord = (
            last_coord.0 + delta.0,
            last_coord.1 + delta.1,
            last_coord.2 + delta.2,
        );

        result.push((
            scale2d(last_coord.0),
            scale2d(last_coord.1),
            scale3d(last_coord.2),
        ));
    }
    Ok(result)
}

fn var_decode_i64<I: Iterator<Item = u8>>(bytes: &mut I) -> Result<i64, Error> {
    match var_decode_u64(bytes) {
        Ok(mut value) => {
            let negative = (value & 1) != 0;
            value >>= 1;
            if negative {
                value = !value;
            }
            Ok(value as i64)
        }
        Err(err) => Err(err),
    }
}

fn var_decode_u64<I: Iterator<Item = u8>>(bytes: &mut I) -> Result<u64, Error> {
    #[rustfmt::skip]
    const DECODING_TABLE: &[i8] = &[
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, 62, -1, -1, 52, 53,
        54, 55, 56, 57, 58, 59, 60, 61, -1, -1,
        -1, -1, -1, -1, -1,  0,  1,  2,  3,  4,
         5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
        15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
        25, -1, -1, -1, -1, 63, -1, 26, 27, 28,
        29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
        39, 40, 41, 42, 43, 44, 45, 46, 47, 48,
        49, 50, 51, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1,
    ];

    let mut result: u64 = 0;
    let mut shift = 0;

    for byte in bytes {
        let value = DECODING_TABLE[byte as usize];
        if value < 0 {
            return Err(Error::InvalidEncoding);
        }

        let value = value as u64;
        result |= (value & 0x1F) << shift;

        if (value & 0x20) == 0 {
            return Ok(result);
        }

        shift += 5;

        if shift >= 64 {
            return Err(Error::InvalidEncoding);
        }
    }

    Err(Error::InvalidEncoding)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_var_encode_i64() {
        let mut buf = String::new();
        var_encode_i64(-17998321, &mut buf);
        assert_eq!(buf, "h_wqiB");
    }

    #[test]
    fn test_encode_2d_example_1() {
        let coordinates = vec![
            (50.1022829, 8.6982122),
            (50.1020076, 8.6956695),
            (50.1006313, 8.6914960),
            (50.0987800, 8.6875156),
        ];

        let expected = "BFoz5xJ67i1B1B7PzIhaxL7Y";
        assert_eq!(
            &Polyline::Data2d {
                coordinates,
                precision2d: Precision::Digits5
            }
            .encode()
            .unwrap(),
            expected
        );
    }

    #[test]
    fn test_encode_2d_example_2() {
        let coordinates = vec![
            (52.5199356, 13.3866272),
            (52.5100899, 13.2816896),
            (52.4351807, 13.1935196),
            (52.4107285, 13.1964502),
            (52.3887100, 13.1557798),
            (52.3727798, 13.1491003),
            (52.3737488, 13.1154604),
            (52.3875198, 13.0872202),
            (52.4029388, 13.0706196),
            (52.4105797, 13.0755529),
        ];

        let expected = "BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e";
        assert_eq!(
            &Polyline::Data2d {
                coordinates,
                precision2d: Precision::Digits5
            }
            .encode()
            .unwrap(),
            expected
        );
    }

    #[test]
    fn test_encode_3d_example_1() {
        let coordinates = vec![
            (50.1022829, 8.6982122, 10.0),
            (50.1020076, 8.6956695, 20.0),
            (50.1006313, 8.6914960, 30.0),
            (50.0987800, 8.6875156, 40.0),
        ];

        let expected = "BVoz5xJ67i1BU1B7PUzIhaUxL7YU";
        assert_eq!(
            &Polyline::Data3d {
                coordinates,
                precision2d: Precision::Digits5,
                precision3d: Precision::Digits0,
                type3d: Type3d::Level
            }
            .encode()
            .unwrap(),
            expected
        );
    }

    #[test]
    fn test_var_decode_i64() -> Result<(), Error> {
        let mut bytes = "h_wqiB".bytes();
        let res = var_decode_i64(&mut bytes)?;
        assert_eq!(res, -17998321);
        let res = var_decode_i64(&mut bytes);
        assert!(res.is_err());

        let mut bytes = "hhhhhhhhhhhhhhhhhhh".bytes();
        let res = var_decode_i64(&mut bytes);
        assert!(res.is_err());
        Ok(())
    }

    #[test]
    fn test_decode_2d_example_1() -> Result<(), Error> {
        let polyline = Polyline::decode("BFoz5xJ67i1B1B7PzIhaxL7Y")?;
        let expected = "{(5); [\
                        (50.102280, 8.698210), \
                        (50.102010, 8.695670), \
                        (50.100630, 8.691500), \
                        (50.098780, 8.687520), \
                        ]}";
        let result = format!("{:.6}", polyline);
        assert_eq!(expected, result);
        Ok(())
    }

    #[test]
    fn test_decode_2d_example_2() -> Result<(), Error> {
        let polyline =
            Polyline::decode("BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e")?;
        let expected = "{(5); [\
                        (52.519940, 13.386630), \
                        (52.510090, 13.281690), \
                        (52.435180, 13.193520), \
                        (52.410730, 13.196450), \
                        (52.388710, 13.155780), \
                        (52.372780, 13.149100), \
                        (52.373750, 13.115460), \
                        (52.387520, 13.087220), \
                        (52.402940, 13.070620), \
                        (52.410580, 13.075550), \
                        ]}";

        let result = format!("{:.6}", polyline);
        assert_eq!(expected, result);
        Ok(())
    }

    #[test]
    fn test_decode_3d_example_1() -> Result<(), Error> {
        let polyline = Polyline::decode("BVoz5xJ67i1BU1B7PUzIhaUxL7YU")?;
        let expected = "{(5, 0, 1); [\
                        (50.102280, 8.698210, 10.000000), \
                        (50.102010, 8.695670, 20.000000), \
                        (50.100630, 8.691500, 30.000000), \
                        (50.098780, 8.687520, 40.000000), \
                        ]}";

        let result = format!("{:.6}", polyline);
        assert_eq!(expected, result);
        Ok(())
    }

    #[test]
    #[allow(clippy::zero_prefixed_literal)]
    fn test_encode_decode_2d() -> Result<(), Error> {
        let coordinate_values: Vec<(u64, u64)> = vec![
            (96821474666297905, 78334196549606266),
            (29405294060895017, 70361389340728572),
            (16173544634348013, 17673855782924183),
            (22448654820449524, 13005139703027850),
            (73351231936757857, 78298027377720633),
            (78008331957098324, 04847613123220218),
            (62755680515396509, 49165433608990700),
            (93297154866561429, 52373802822465027),
            (89973844644540399, 75975762025877533),
            (48555821719956867, 31591090068957813),
        ];

        for precision2d in 0..=15 {
            let to_f64 = |value: &(u64, u64)| {
                (
                    value.0 as f64 / 10_u64.pow(15) as f64,
                    value.1 as f64 / 10_u64.pow(15) as f64,
                )
            };

            let to_rounded_f64 = |value: &(u64, u64)| {
                let value = to_f64(value);
                let scale = 10_u64.pow(precision2d) as f64;
                (
                    (value.0 * scale).round() / scale,
                    (value.1 * scale).round() / scale,
                )
            };

            let expected = format!(
                "{:.*}",
                precision2d as usize + 1,
                Polyline::Data2d {
                    coordinates: coordinate_values.iter().map(to_rounded_f64).collect(),
                    precision2d: Precision::from_u32(precision2d).unwrap(),
                }
            );

            let encoded = &Polyline::Data2d {
                coordinates: coordinate_values.iter().map(to_f64).collect(),
                precision2d: Precision::from_u32(precision2d).unwrap(),
            }
            .encode()?;

            let polyline = Polyline::decode(encoded)?;
            let result = format!("{:.*}", precision2d as usize + 1, polyline);
            assert_eq!(expected, result);
        }

        Ok(())
    }

    #[test]
    #[allow(clippy::zero_prefixed_literal)]
    fn test_encode_decode_3d() -> Result<(), Error> {
        let coordinate_values: Vec<(u64, u64, u64)> = vec![
            (96821474666297905, 78334196549606266, 23131023979661380),
            (29405294060895017, 70361389340728572, 81917934930416924),
            (16173544634348013, 17673855782924183, 86188502094968953),
            (22448654820449524, 13005139703027850, 68774670569614983),
            (73351231936757857, 78298027377720633, 52078352171243855),
            (78008331957098324, 04847613123220218, 06550838806837986),
            (62755680515396509, 49165433608990700, 39041897671300539),
            (93297154866561429, 52373802822465027, 67310807938230681),
            (89973844644540399, 75975762025877533, 66789448009436096),
            (48555821719956867, 31591090068957813, 49203621966471323),
        ];

        let precision2d = 5;
        for precision3d in 0..=15 {
            for type3d in &[
                Type3d::Level,
                Type3d::Altitude,
                Type3d::Elevation,
                Type3d::Reserved1,
                Type3d::Reserved2,
                Type3d::Custom1,
                Type3d::Custom2,
            ] {
                let to_f64 = |value: &(u64, u64, u64)| {
                    (
                        value.0 as f64 / 10_u64.pow(15) as f64,
                        value.1 as f64 / 10_u64.pow(15) as f64,
                        value.2 as f64 / 10_u64.pow(15) as f64,
                    )
                };

                let to_rounded_f64 = |value: &(u64, u64, u64)| {
                    let value = to_f64(value);
                    let scale2d = 10_u64.pow(precision2d) as f64;
                    let scale3d = 10_u64.pow(precision3d) as f64;
                    (
                        (value.0 * scale2d).round() / scale2d,
                        (value.1 * scale2d).round() / scale2d,
                        (value.2 * scale3d).round() / scale3d,
                    )
                };

                let expected = format!(
                    "{:.*}",
                    precision2d.max(precision3d) as usize + 1,
                    Polyline::Data3d {
                        coordinates: coordinate_values.iter().map(to_rounded_f64).collect(),
                        precision2d: Precision::from_u32(precision2d).unwrap(),
                        precision3d: Precision::from_u32(precision3d).unwrap(),
                        type3d: *type3d,
                    }
                );

                let encoded = Polyline::Data3d {
                    coordinates: coordinate_values.iter().map(to_f64).collect(),
                    precision2d: Precision::from_u32(precision2d).unwrap(),
                    precision3d: Precision::from_u32(precision3d).unwrap(),
                    type3d: *type3d,
                }
                .encode()?;

                let polyline = Polyline::decode(&encoded)?;
                let result = format!("{:.*}", precision2d.max(precision3d) as usize + 1, polyline);
                assert_eq!(expected, result);
            }
        }

        Ok(())
    }
}
