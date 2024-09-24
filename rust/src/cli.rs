use std::io::BufRead;
use std::str::FromStr;

fn remove_decoration<'a>(x: &'a str, prefix: &str, suffix: &str) -> &'a str {
    if !x.starts_with(prefix) || !x.ends_with(suffix) {
        panic!("{}{} missing", prefix, suffix);
    }
    &x[prefix.len()..x.len() - suffix.len()]
}

fn from_str(data: &str) -> flexpolyline::Polyline {
    let parse_precision = |x: Option<&str>| {
        let prec_u32 = u32::from_str(x.expect("Precision missing"))
            .unwrap_or_else(|e| panic!("Precision not parsable: {}", e));
        flexpolyline::Precision::from_u32(prec_u32)
            .unwrap_or_else(|| panic!("Precision outside of supported range: {}", prec_u32))
    };
    let parse_3d_type = |x: Option<&str>| {
        let value_u32 = u32::from_str(x.expect("Type3d missing"))
            .unwrap_or_else(|e| panic!("Type3d not parsable: {}", e));
        match value_u32 {
            1 => flexpolyline::Type3d::Level,
            2 => flexpolyline::Type3d::Altitude,
            3 => flexpolyline::Type3d::Elevation,
            4 => flexpolyline::Type3d::Reserved1,
            5 => flexpolyline::Type3d::Reserved2,
            6 => flexpolyline::Type3d::Custom1,
            7 => flexpolyline::Type3d::Custom2,
            _ => panic!("Unexpected 3d type: {}", value_u32),
        }
    };

    let data = remove_decoration(data, "{", "}");
    let mut split = data.split("; ");
    let header = remove_decoration(split.next().expect("header not found"), "(", ")");
    let mut components = header.split(", ");
    let precision2d = parse_precision(components.next());
    let result = match components.next() {
        None => {
            let data = remove_decoration(split.next().expect("data not found"), "[(", "), ]");
            let coordinates = data
                .split("), (")
                .filter_map(|x| {
                    if x.is_empty() {
                        None
                    } else {
                        let mut coord = x.split(", ");
                        let lat = f64::from_str(coord.next().expect("Missing latitude"))
                            .unwrap_or_else(|e| panic!("latitude not parseable: {}", e));
                        let lon = f64::from_str(coord.next().expect("Missing longitude"))
                            .unwrap_or_else(|e| panic!("longitude not parseable: {}", e));
                        if let Some(trail) = coord.next() {
                            panic!("Too many components in 2d coordinate: {}", trail);
                        }
                        Some((lat, lon))
                    }
                })
                .collect();
            flexpolyline::Polyline::Data2d {
                precision2d,
                coordinates,
            }
        }
        Some(precision) => {
            let precision3d = parse_precision(Some(precision));
            let type3d = parse_3d_type(components.next());
            if let Some(trail) = components.next() {
                panic!("Too many components in header: {}", trail);
            }

            let data = remove_decoration(split.next().expect("data not found"), "[(", "), ]");
            let coordinates = data
                .split("), (")
                .filter_map(|x| {
                    if x.is_empty() {
                        None
                    } else {
                        let mut coord = x.split(", ");
                        let lat = f64::from_str(coord.next().expect("Missing latitude"))
                            .unwrap_or_else(|e| panic!("latitude not parseable: {}", e));
                        let lon = f64::from_str(coord.next().expect("Missing longitude"))
                            .unwrap_or_else(|e| panic!("longitude not parseable: {}", e));
                        let z = f64::from_str(coord.next().expect("Missing 3d component"))
                            .unwrap_or_else(|e| panic!("3d component not parseable: {}", e));
                        if let Some(trail) = coord.next() {
                            panic!("Too many components in 3d coordinate: {}", trail);
                        }
                        Some((lat, lon, z))
                    }
                })
                .collect();
            flexpolyline::Polyline::Data3d {
                precision2d,
                precision3d,
                type3d,
                coordinates,
            }
        }
    };

    if let Some(trail) = components.next() {
        panic!("Too many components in data: {}", trail);
    }

    result
}

fn main() {
    // Manually parse command line arguments to avoid adding any addditional dependencies
    let args: Vec<String> = std::env::args().collect();
    let original_precision_arg = "--original-precision".to_string();
    if (args.len() != 2 && args.len() != 3)
        || (args[1] != "encode" && args[1] != "decode")
        || (args.len() == 3 && args[2] != original_precision_arg)
    {
        eprintln!("Usage: flexpolyline encode|decode [{original_precision_arg}]");
        eprintln!("       input: stdin");
        eprintln!("       output: stdout");
        eprintln!("  Options:");
        eprintln!("       {original_precision_arg}: Print decoded polyline with encoded precision");
        std::process::exit(1);
    }

    let stdin = std::io::stdin();

    if args[1] == "encode" {
        for line in stdin.lock().lines() {
            let input = line.unwrap();
            let polyline = from_str(&input);
            println!(
                "{}",
                polyline
                    .encode()
                    .unwrap_or_else(|e| panic!("Failed to encode {}: {}", input, e))
            );
        }
    } else {
        for line in stdin.lock().lines() {
            let input = line.unwrap();
            let polyline = flexpolyline::Polyline::decode(&input)
                .unwrap_or_else(|e| panic!("Failed to decode {}: {}", input, e));
            if args.get(2) == Some(&original_precision_arg) {
                println!("{polyline}");
            } else {
                println!("{polyline:.15}");
            }
        }
    }
}
