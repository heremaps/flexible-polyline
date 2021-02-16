/*
 * Copyright (C) 2019 HERE Europe B.V.
 * Licensed under MIT, see full license in LICENSE
 * SPDX-License-Identifier: MIT
 * License-Filename: LICENSE
 */
#include <hf/flexpolyline.h>
#include <iostream>
#include <sstream>
#include <tuple>
#include <vector>

using namespace hf::flexpolyline;

void check_encode_decode(const Polyline &poly, const std::string &reference_encoded,
                         const Polyline &reference_decoded) {
  std::string result;
  if (auto error = polyline_encode(poly, result)) {
    std::cerr << "Failed to encode " << to_string(poly) << std::endl;
    std::exit(1);
  }
  if (result != reference_encoded) {
    std::cerr << "Encoded " << to_string(poly) << std::endl
              << "Got " << result << std::endl
              << "Expected " << reference_encoded << std::endl;
    std::exit(1);
  }

  Polyline decoded;
  if (auto error = polyline_decode(reference_encoded, decoded)) {
    std::cerr << "Failed to decode " << reference_encoded << std::endl;
    std::exit(1);
  }

  if (to_string(reference_decoded) != to_string(decoded)) {
    std::cerr << "Decoded " << reference_encoded << std::endl
              << "Got " << to_string(decoded) << std::endl
              << "Expected " << to_string(poly) << std::endl;
    std::exit(1);
  }
}

void test_2d_example_1() {
  std::vector<std::tuple<double, double>> coordinates = {{50.1022829, 8.6982122},
                                                         {50.1020076, 8.6956695},
                                                         {50.1006313, 8.6914960},
                                                         {50.0987800, 8.6875156}};

  std::vector<std::tuple<double, double>> coordinates_result = {
      {50.102280, 8.698210}, {50.102010, 8.695670}, {50.100630, 8.691500}, {50.098780, 8.687520}};

  check_encode_decode(Polyline2d{coordinates, *Precision::from_u32(5)}, "BFoz5xJ67i1B1B7PzIhaxL7Y",
                      Polyline2d{coordinates_result, *Precision::from_u32(5)});
}

void test_2d_example_2() {
  std::vector<std::tuple<double, double>> coordinates = {
      {52.5199356, 13.3866272}, {52.5100899, 13.2816896}, {52.4351807, 13.1935196},
      {52.4107285, 13.1964502}, {52.3887100, 13.1557798}, {52.3727798, 13.1491003},
      {52.3737488, 13.1154604}, {52.3875198, 13.0872202}, {52.4029388, 13.0706196},
      {52.4105797, 13.0755529}};

  std::vector<std::tuple<double, double>> coordinates_result = {
      {52.519940, 13.386630}, {52.510090, 13.281690}, {52.435180, 13.193520},
      {52.410730, 13.196450}, {52.388710, 13.155780}, {52.372780, 13.149100},
      {52.373750, 13.115460}, {52.387520, 13.087220}, {52.402940, 13.070620},
      {52.410580, 13.075550}};

  check_encode_decode(Polyline2d{coordinates, *Precision::from_u32(5)},
                      "BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e",
                      Polyline2d{coordinates_result, *Precision::from_u32(5)});
}

void test_3d_example_1() {
  std::vector<std::tuple<double, double, double>> coordinates = {{50.1022829, 8.6982122, 10.0},
                                                                 {50.1020076, 8.6956695, 20.0},
                                                                 {50.1006313, 8.6914960, 30.0},
                                                                 {50.0987800, 8.6875156, 40.0}};

  std::vector<std::tuple<double, double, double>> coordinates_result = {
      {50.102280, 8.698210, 10.0},
      {50.102010, 8.695670, 20.0},
      {50.100630, 8.691500, 30.0},
      {50.098780, 8.687520, 40.0}};

  check_encode_decode(
      Polyline3d{coordinates, *Precision::from_u32(5), *Precision::from_u32(0), Type3d::LEVEL},
      "BVoz5xJ67i1BU1B7PUzIhaUxL7YU",
      Polyline3d{coordinates_result, *Precision::from_u32(5), *Precision::from_u32(0),
                 Type3d::LEVEL});
}

void test_rounding_2d() {
  std::vector<std::tuple<uint64_t, uint64_t>> coordinate_values = {
      {96821474666297905, 78334196549606266}, {29405294060895017, 70361389340728572},
      {16173544634348013, 17673855782924183}, {22448654820449524, 13005139703027850},
      {73351231936757857, 78298027377720633}, {78008331957098324, 4847613123220218},
      {62755680515396509, 49165433608990700}, {93297154866561429, 52373802822465027},
      {89973844644540399, 75975762025877533}, {48555821719956867, 31591090068957813}};

  for (uint32_t precision2d = 0; precision2d < 16; precision2d++) {
    auto to_f64 = [](const std::tuple<uint64_t, uint64_t> &value) {
      return std::make_tuple(static_cast<double>(std::get<0>(value)) / std::pow(10, 15),
                             static_cast<double>(std::get<1>(value)) / std::pow(10, 15));
    };

    auto to_rounded_f64 = [&](const std::tuple<uint64_t, uint64_t> &input) {
      auto value = to_f64(input);
      auto scale = std::pow(10, precision2d);
      return std::make_tuple(std::round(std::get<0>(value) * scale) / scale,
                             std::round(std::get<1>(value) * scale) / scale);
    };

    Polyline2d expected;
    expected.precision2d = *Precision::from_u32(precision2d);
    for (auto coord : coordinate_values) {
      expected.coordinates.emplace_back(to_rounded_f64(coord));
    }

    Polyline2d actual;
    actual.precision2d = *Precision::from_u32(precision2d);
    for (auto coord : coordinate_values) {
      actual.coordinates.emplace_back(to_f64(coord));
    }

    std::string expected_encoded;
    if (auto error = polyline_encode(expected, expected_encoded)) {
      std::cerr << "Failed to encode " << to_string(expected) << std::endl;
      std::exit(1);
    }

    std::string actual_encoded;
    if (auto error = polyline_encode(actual, actual_encoded)) {
      std::cerr << "Failed to encode " << to_string(actual) << std::endl;
      std::exit(1);
    }

    if (expected_encoded != actual_encoded) {
      std::cerr << "Precision " << precision2d << std::endl
                << "Expected " << expected_encoded << std::endl
                << "Got " << actual_encoded << std::endl;
      exit(1);
    }
  }
}

void test_rounding_3d() {
  std::vector<std::tuple<uint64_t, uint64_t, uint64_t>> coordinate_values = {
      {96821474666297905, 78334196549606266, 23131023979661380},
      {29405294060895017, 70361389340728572, 81917934930416924},
      {16173544634348013, 17673855782924183, 86188502094968953},
      {22448654820449524, 13005139703027850, 68774670569614983},
      {73351231936757857, 78298027377720633, 52078352171243855},
      {78008331957098324, 4847613123220218, 6550838806837986},
      {62755680515396509, 49165433608990700, 39041897671300539},
      {93297154866561429, 52373802822465027, 67310807938230681},
      {89973844644540399, 75975762025877533, 66789448009436096},
      {48555821719956867, 31591090068957813, 49203621966471323}};

  uint32_t precision2d = 5;
  for (uint32_t precision3d = 0; precision3d < 16; precision3d++) {
    for (auto type3d : {
             Type3d::LEVEL,
             Type3d::ALTITUDE,
             Type3d::ELEVATION,
             Type3d::RESERVED1,
             Type3d::RESERVED2,
             Type3d::CUSTOM1,
             Type3d::CUSTOM2,
         }) {
      auto to_f64 = [](const std::tuple<uint64_t, uint64_t, uint64_t> &value) {
        return std::make_tuple(static_cast<double>(std::get<0>(value)) / std::pow(10, 15),
                               static_cast<double>(std::get<1>(value)) / std::pow(10, 15),
                               static_cast<double>(std::get<2>(value)) / std::pow(10, 15));
      };

      auto to_rounded_f64 = [&](const std::tuple<uint64_t, uint64_t, uint64_t> &input) {
        auto value = to_f64(input);
        auto scale2d = std::pow(10, precision2d);
        auto scale3d = std::pow(10, precision3d);
        return std::make_tuple(std::round(std::get<0>(value) * scale2d) / scale2d,
                               std::round(std::get<1>(value) * scale2d) / scale2d,
                               std::round(std::get<2>(value) * scale3d) / scale3d);
      };

      Polyline3d expected;
      expected.precision2d = *Precision::from_u32(precision2d);
      expected.precision3d = *Precision::from_u32(precision3d);
      expected.type3d = type3d;
      for (auto coord : coordinate_values) {
        expected.coordinates.emplace_back(to_rounded_f64(coord));
      }

      Polyline3d actual;
      actual.precision2d = *Precision::from_u32(precision2d);
      actual.precision3d = *Precision::from_u32(precision3d);
      actual.type3d = type3d;
      for (auto coord : coordinate_values) {
        actual.coordinates.emplace_back(to_f64(coord));
      }

      std::string expected_encoded;
      if (auto error = polyline_encode(expected, expected_encoded)) {
        std::cerr << "Failed to encode " << to_string(expected) << std::endl;
        std::exit(1);
      }

      std::string actual_encoded;
      if (auto error = polyline_encode(actual, actual_encoded)) {
        std::cerr << "Failed to encode " << to_string(actual) << std::endl;
        std::exit(1);
      }

      if (expected_encoded != actual_encoded) {
        std::cerr << "Precision " << precision2d << std::endl
                  << "Expected " << expected_encoded << std::endl
                  << "Got " << actual_encoded << std::endl;
        exit(1);
      }
    }
  }
}

int main(int, char const *[]) {
  std::cout << "Running tests" << std::endl;
  test_2d_example_1();
  test_2d_example_2();
  test_3d_example_1();
  test_rounding_2d();
  test_rounding_3d();
  std::cout << "Done" << std::endl;
  return 0;
}
