/*
 * Copyright (C) 2021 HERE Europe B.V.
 * Licensed under MIT, see full license in LICENSE
 * SPDX-License-Identifier: MIT
 * License-Filename: LICENSE
 */

#include <charconv>
#include <iostream>

#include <hf/flexpolyline.h>

std::string_view remove_decoration(std::string_view x, std::string_view prefix,
                                   std::string_view suffix) {
  if (x.size() < suffix.size() + suffix.size() || x.substr(0, prefix.size()) != prefix ||
      x.substr(x.size() - suffix.length(), suffix.length()) != suffix) {
    throw std::runtime_error(std::string(prefix) + suffix.data() + " missing");
  }
  x.remove_prefix(prefix.size());
  x.remove_suffix(suffix.size());
  return x;
}

std::string_view split_next(std::string_view &x, std::string_view sep, bool required) {
  auto pos = x.find(sep);
  auto result = x.substr(0, pos);
  if (pos == std::string::npos) {
    if (required) {
      throw std::runtime_error(std::string("Missing seperator: ") + sep.data());
    }
    x = std::string_view();
  } else {
    x = x.substr(pos + sep.size());
  }
  return result;
}

hf::flexpolyline::Precision parse_precision(std::string_view x) {
  uint32_t prec_u32 = std::atoi(x.data());
  if (auto prec = hf::flexpolyline::Precision::from_u32(prec_u32)) {
    return *prec;
  }
  throw std::runtime_error("Precision outside of supported range: " + std::to_string(prec_u32));
}

hf::flexpolyline::Type3d parse_3d_type(std::string_view x) {
  uint32_t value_u32 = std::atoi(x.data());
  switch (value_u32) {
  case 1:
    return hf::flexpolyline::Type3d::LEVEL;
  case 2:
    return hf::flexpolyline::Type3d::ALTITUDE;
  case 3:
    return hf::flexpolyline::Type3d::ELEVATION;
  case 4:
    return hf::flexpolyline::Type3d::RESERVED1;
  case 5:
    return hf::flexpolyline::Type3d::RESERVED2;
  case 6:
    return hf::flexpolyline::Type3d::CUSTOM1;
  case 7:
    return hf::flexpolyline::Type3d::CUSTOM2;
  default:
    throw std::runtime_error("Unexpected 3d type: " + std::to_string(value_u32));
  }
}

hf::flexpolyline::Polyline from_str(std::string_view input) {

  auto data = remove_decoration(input, "{", "}");
  auto header = remove_decoration(split_next(data, "; ", true), "(", ")");
  auto coords_data = remove_decoration(data, "[(", "), ]");
  auto precision2d = parse_precision(split_next(header, ", ", false));
  if (header.empty()) {
    std::vector<std::tuple<double, double>> coordinates;
    while (!coords_data.empty()) {
      auto lat_str = split_next(coords_data, ", ", true);
      double lat = std::atof(lat_str.data());
      auto lng_str = split_next(coords_data, "), (", false);
      double lng = std::atof(lng_str.data());

      coordinates.emplace_back(lat, lng);
    }
    return hf::flexpolyline::Polyline2d{std::move(coordinates), precision2d};
  } else {
    auto precision3d = parse_precision(split_next(header, ", ", true));
    auto type3d = parse_3d_type(header);
    std::vector<std::tuple<double, double, double>> coordinates;
    while (!coords_data.empty()) {
      auto lat_str = split_next(coords_data, ", ", true);
      double lat = std::atof(lat_str.data());
      auto lng_str = split_next(coords_data, ", ", true);
      double lng = std::atof(lng_str.data());
      auto third_str = split_next(coords_data, "), (", false);
      double third = std::atof(third_str.data());

      coordinates.emplace_back(lat, lng, third);
    }
    return hf::flexpolyline::Polyline3d{std::move(coordinates), precision2d, precision3d, type3d};
  }
}

int main(int argc, const char *argv[]) {
  if (argc != 2 ||
      (std::string_view(argv[1]) != "encode" && std::string_view(argv[1]) != "decode")) {
    std::cerr << "Usage: flexpolyline encode|decode" << std::endl;
    std::cerr << "       input: stdin" << std::endl;
    std::cerr << "       output: stdout" << std::endl;
    return 1;
  }

  try {
    std::string input_line;
    while (std::cin) {
      std::getline(std::cin, input_line);
      if (input_line.empty()) {
        continue;
      }
      if (std::string_view(argv[1]) == "encode") {
        auto polyline = from_str(input_line);
        std::string result;
        if (auto error = hf::flexpolyline::polyline_encode(polyline, result)) {
          std::cerr << "Failed to encode: " << static_cast<uint32_t>(*error) << std::endl;
          return 1;
        }
        std::cout << result << std::endl;
      } else if (std::string_view(argv[1]) == "decode") {
        hf::flexpolyline::Polyline result;
        if (auto error = hf::flexpolyline::polyline_decode(input_line, result)) {
          std::cerr << "Failed to decode: " << static_cast<uint32_t>(*error) << std::endl;
          return 1;
        }
        std::cout << hf::flexpolyline::to_string(result, 15) << std::endl;
      } else {
        std::cerr << "Command not recognized: " << argv[1] << std::endl;
        return 1;
      }
    }
  } catch (std::exception &e) {
    std::cerr << "[ERROR] " << e.what() << std::endl;
    return -1;
  }

  return 0;
}
