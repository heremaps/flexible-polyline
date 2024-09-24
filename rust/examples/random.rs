//! Example which generates random polylines covering all possible cases.

use rand::prelude::*;

fn main() {
    let mut rng = rand::thread_rng();
    let range_lat = 180 * 10_i64.pow(15);
    let range_lon = 90 * 10_i64.pow(15);
    let range_z = 1000 * 10_i64.pow(14);
    for &divisor in [
        1,
        10_i64.pow(4),
        10_i64.pow(8),
        10_i64.pow(12),
        10_i64.pow(17),
        10_i64.pow(18),
    ]
    .iter()
    {
        for num_coords in 1..5 {
            for prec2d in 0..=15 {
                for &type3d in [
                    flexpolyline::Type3d::Level,
                    flexpolyline::Type3d::Altitude,
                    flexpolyline::Type3d::Elevation,
                    flexpolyline::Type3d::Reserved1,
                    flexpolyline::Type3d::Reserved2,
                    flexpolyline::Type3d::Custom1,
                    flexpolyline::Type3d::Custom2,
                ]
                .iter()
                {
                    let polyline = flexpolyline::Polyline::Data3d {
                        precision2d: flexpolyline::Precision::from_u32(prec2d).unwrap(),
                        precision3d: flexpolyline::Precision::from_u32(15 - prec2d).unwrap(),
                        type3d,
                        coordinates: (0..num_coords)
                            .map(|_| {
                                (
                                    (rng.gen_range(-range_lat..=range_lat) / divisor) as f64
                                        / 10_i64.pow(15) as f64,
                                    (rng.gen_range(-range_lon..=range_lon) / divisor) as f64
                                        / 10_i64.pow(15) as f64,
                                    (rng.gen_range(-range_z..=range_z) / divisor) as f64
                                        / 10_i64.pow(14) as f64,
                                )
                            })
                            .collect(),
                    };
                    println!("{:.15}", polyline);
                }

                let polyline = flexpolyline::Polyline::Data2d {
                    precision2d: flexpolyline::Precision::from_u32(prec2d).unwrap(),
                    coordinates: (0..num_coords)
                        .map(|_| {
                            (
                                (rng.gen_range(-range_lat..=range_lat) / divisor) as f64
                                    / 10_i64.pow(15) as f64,
                                (rng.gen_range(-range_lon..=range_lon) / divisor) as f64
                                    / 10_i64.pow(15) as f64,
                            )
                        })
                        .collect(),
                };
                println!("{:.15}", polyline);
            }
        }
    }
}
