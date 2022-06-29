/*
 * Copyright (C) 2019 HERE Europe B.V.
 * Licensed under MIT, see full license in LICENSE
 * SPDX-License-Identifier: MIT
 * License-Filename: LICENSE
 */
#include <array>
#include <cmath>
#include <optional>
#include <sstream>
#include <string>
#include <tuple>
#include <variant>
#include <vector>

/// # Flexible Polyline encoding
///
/// The flexible polyline encoding is a lossy compressed representation of a list of coordinate
/// pairs or coordinate triples. It achieves that by:
///
/// 1. Reducing the decimal digits of each value.
/// 2. Encoding only the offset from the previous point.
/// 3. Using variable length for each coordinate delta.
/// 4. Using 64 URL-safe characters to display the result.
///
/// The encoding is a variant of [Encoded Polyline Algorithm Format]. The advantage of this encoding
/// over the original are the following:
///
/// * Output string is composed by only URL-safe characters, i.e. may be used without URL encoding
///   as query parameters.
/// * Floating point precision is configurable: This allows to represent coordinates with precision
///   up to microns (5 decimal places allow meter precision only).
/// * It allows to encode a 3rd dimension with a given precision, which may be a level, altitude,
///   elevation or some other custom value.
///
/// ## Specification
///
/// See [Specification].
///
/// [Encoded Polyline Algorithm Format]:
/// https://developers.google.com/maps/documentation/utilities/polylinealgorithm
///
/// [Specification]: https://github.com/heremaps/flexible-polyline#specifications
///
/// ## Example
///
/// ```cpp
/// #include< hf/flexpoly.h>
///
/// // encode
/// std::vector<std::tuple<double, double>> coordinates = {{50.1022829, 8.6982122},
///                                                        {50.1020076, 8.6956695},
///                                                        {50.1006313, 8.6914960},
///                                                        {50.0987800, 8.6875156}};
/// hf::Polyline polyline = hf::Polyline2d{std::move(coordinates), *hf::Precision::from_u32(5)};
///
/// std::string encoded;
/// auto error = hf::polyline_encode(polyline, encoded));
/// assert(!error);
/// assert(encoded == "BFoz5xJ67i1B1B7PzIhaxL7Y");
///
/// // decode
/// hf::Polyline result;
/// auto decode_error = hf::polyline_decode(encoded, result);
/// assert(!decode_error);
/// ```
namespace hf::flexpolyline {

/// Coordinate precision in the polyline
///
/// Represents how many digits are to be encoded after the decimal point, e.g.
/// precision 3 would encode 4.456787 as 4.457.
///
/// Supported values: `[0,16)`
class Precision {
public:
  static std::optional<Precision> from_u32(uint32_t value) {
    if (value > 15) {
      return {};
    }
    return Precision(static_cast<uint8_t>(value));
  }
  uint32_t as_u32() const { return m_value; }

private:
  explicit Precision(uint8_t value) : m_value(value) {}
  uint8_t m_value;
};

/// Informs about the type of the 3rd dimension of a 3D coordinate vector
enum class Type3d {
  /// E.g. floor of a building
  LEVEL = 1,
  /// E.g. altitude (in the air) relative to ground level or mean sea level
  ALTITUDE = 2,
  /// E.g. elevation above mean-sea-level
  ELEVATION = 3,
  /// Reserved for future types
  RESERVED1 = 4,
  /// Reserved for future types
  RESERVED2 = 5,
  /// Reserved for custom types
  CUSTOM1 = 6,
  /// Reserved for custom types
  CUSTOM2 = 7,
};

/// 2-dimensional polyline
struct Polyline2d {
  /// List of 2D coordinates making up this polyline
  std::vector<std::tuple<double, double>> coordinates;
  /// Precision of the coordinates (e.g. used for encoding,
  /// or to report the precision supplied in encoded data)
  Precision precision2d = *Precision::from_u32(7);

  Polyline2d() = default;
  Polyline2d(std::vector<std::tuple<double, double>> coordinates, Precision precision2d)
      : coordinates(std::move(coordinates)), precision2d(precision2d) {}
};

/// 3-dimensional polyline
struct Polyline3d {
  /// List of 3D coordinates making up this polyline
  std::vector<std::tuple<double, double, double>> coordinates;
  /// Precision of the 2D part of the coordinates (e.g. used for encoding,
  /// or to report the precision supplied in encoded data)
  Precision precision2d = *Precision::from_u32(7);
  /// Precision of the 3D part of the coordinates (e.g. used for encoding,
  /// or to report the precision supplied in encoded data)
  Precision precision3d = *Precision::from_u32(3);
  /// Type of the 3D component
  Type3d type3d = Type3d::ELEVATION;

  Polyline3d() = default;
  Polyline3d(std::vector<std::tuple<double, double, double>> coordinates, Precision precision2d,
             Precision precision3d, Type3d type3d)
      : coordinates(std::move(coordinates)), precision2d(precision2d), precision3d(precision3d),
        type3d(type3d) {}
};

/// 2- or 3-dimensional polyline
using Polyline = std::variant<Polyline2d, Polyline3d>;

inline std::string to_string(const Polyline &polyline, std::optional<int> precision = {}) {
  std::ostringstream out;
  out << std::fixed;
  std::visit(
      [&](auto &&arg) {
        using T = std::decay_t<decltype(arg)>;
        if constexpr (std::is_same_v<T, Polyline2d>) {
          out << "{(" << arg.precision2d.as_u32() << "); [";
          out.precision(precision.value_or(arg.precision2d.as_u32()));
          for (auto &coord : arg.coordinates) {
            out << "(" << std::get<0>(coord) << ", " << std::get<1>(coord) << "), ";
          }
          out << "]}";
        } else if constexpr (std::is_same_v<T, Polyline3d>) {
          out << "{(" << arg.precision2d.as_u32() << ", " << arg.precision3d.as_u32() << ", "
              << static_cast<uint32_t>(arg.type3d) << "); [";
          for (auto &coord : arg.coordinates) {
            out.precision(precision.value_or(arg.precision2d.as_u32()));
            out << "(" << std::get<0>(coord) << ", " << std::get<1>(coord);
            out.precision(precision.value_or(arg.precision3d.as_u32()));
            out << ", " << std::get<2>(coord) << "), ";
          }
          out << "]}";
        } else {
          static_assert(sizeof(T) == 0, "non-exhaustive visitor!");
        }
      },
      polyline);
  return out.str();
}

enum class Error {
  /// Data is encoded with unsupported version
  UNSUPPORTED_VERSION,
  /// Precision is not supported by encoding
  INVALID_PRECISION,
  /// Encoding is corrupt
  INVALID_ENCODING,
};

/// Encodes a polyline into a string.
///
/// The precision of the polyline is used to round coordinates, so the transformation is lossy
/// in nature.
inline std::optional<Error> polyline_encode(const Polyline &polyline, std::string &result) {
  auto var_encode_u64 = [](uint64_t value, std::string &result) {
    static const char *ENCODING_TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    // var-length encode the number in chunks of 5 bits starting with the least significant
    // to the most significant
    while (value > 0x1F) {
      uint32_t pos = (value & 0x1F) | 0x20;
      char c = ENCODING_TABLE[pos];
      result.push_back(c);
      value >>= 5;
    }
    char c = ENCODING_TABLE[value];
    result.push_back(c);
  };

  auto var_encode_i64 = [&](int64_t value, std::string &result) {
    // make room on lowest bit
    uint64_t encoded = static_cast<uint64_t>(value) << 1;

    // invert bits if the value is negative
    if (value < 0) {
      encoded = ~encoded;
    }

    var_encode_u64(encoded, result);
  };

  auto encode_header = [&](uint32_t precision2d, uint32_t precision3d, uint32_t type3d,
                           std::string &result) -> std::optional<Error> {
    if (precision2d > 15 || precision3d > 15) {
      return Error::INVALID_PRECISION;
    }
    var_encode_u64(1, result); // Version 1
    uint32_t header = (precision3d << 7) | (type3d) << 4 | precision2d;
    var_encode_u64(header, result);
    return {};
  };

  auto precision_to_scale = [](Precision precision) {
    double scale = std::pow(10, precision.as_u32());
    return [scale](double value) { return static_cast<int64_t>(std::round(value * scale)); };
  };

  return std::visit(
      [&](auto &&arg) -> std::optional<Error> {
        using T = std::decay_t<decltype(arg)>;
        if constexpr (std::is_same_v<T, Polyline2d>) {
          if (auto error = encode_header(arg.precision2d.as_u32(), 0, 0, result)) {
            return *error;
          }
          auto scale2d = precision_to_scale(arg.precision2d);

          auto last_coord = std::make_tuple<int64_t, int64_t>(0, 0);
          for (auto coord : arg.coordinates) {
            auto scaled_coord =
                std::make_tuple(scale2d(std::get<0>(coord)), scale2d(std::get<1>(coord)));
            var_encode_i64(std::get<0>(scaled_coord) - std::get<0>(last_coord), result);
            var_encode_i64(std::get<1>(scaled_coord) - std::get<1>(last_coord), result);
            last_coord = scaled_coord;
          }
          return {};
        } else if constexpr (std::is_same_v<T, Polyline3d>) {
          if (auto error = encode_header(arg.precision2d.as_u32(), arg.precision3d.as_u32(),
                                         static_cast<uint32_t>(arg.type3d), result)) {
            return *error;
          }
          auto scale2d = precision_to_scale(arg.precision2d);
          auto scale3d = precision_to_scale(arg.precision3d);

          auto last_coord = std::make_tuple<int64_t, int64_t, int64_t>(0, 0, 0);
          for (auto coord : arg.coordinates) {
            auto scaled_coord =
                std::make_tuple(scale2d(std::get<0>(coord)), scale2d(std::get<1>(coord)),
                                scale3d(std::get<2>(coord)));
            var_encode_i64(std::get<0>(scaled_coord) - std::get<0>(last_coord), result);
            var_encode_i64(std::get<1>(scaled_coord) - std::get<1>(last_coord), result);
            var_encode_i64(std::get<2>(scaled_coord) - std::get<2>(last_coord), result);
            last_coord = scaled_coord;
          }
          return {};
        } else {
          static_assert(sizeof(T) == 0, "non-exhaustive visitor!");
        }
      },
      polyline);
}

/// Decodes an encoded polyline.
inline std::optional<Error> polyline_decode(std::string_view encoded, Polyline &result) {

  auto var_decode_u64 = [](std::string_view &bytes, uint64_t &result) -> std::optional<Error> {
    static const int8_t DECODING_TABLE[] = {
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, 62, -1, -1, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1, 0,
        1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
        23, 24, 25, -1, -1, -1, -1, 63, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
        39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    };

    result = 0;
    uint8_t shift = 0;

    while (!bytes.empty()) {
      uint8_t byte = bytes.front();
      bytes = std::string_view(bytes.data() + 1, bytes.size() - 1);
      int8_t value = DECODING_TABLE[byte];
      if (value < 0) {
        return Error::INVALID_ENCODING;
      }

      result |= (static_cast<uint64_t>(value) & 0x1F) << shift;

      if ((value & 0x20) == 0) {
        return {};
      }

      shift += 5;

      if (shift >= 64) {
        return Error::INVALID_ENCODING;
      }
    }

    return Error::INVALID_ENCODING;
  };

  auto var_decode_i64 = [&](std::string_view &bytes, int64_t &result) -> std::optional<Error> {
    uint64_t value = 0;
    if (auto error = var_decode_u64(bytes, value)) {
      return *error;
    }
    bool negative = (value & 1) != 0;
    value >>= 1;
    if (negative) {
      value = ~value;
    }
    result = static_cast<int64_t>(value);
    return {};
  };

  auto decode_header = [&](std::string_view &bytes, uint32_t &precision2d, uint32_t &precision3d,
                           uint32_t &type3d) -> std::optional<Error> {
    uint64_t version = 0;
    if (auto error = var_decode_u64(bytes, version)) {
      return *error;
    }

    if (version != 1) {
      return Error::UNSUPPORTED_VERSION;
    }

    uint64_t header = 0;
    if (auto error = var_decode_u64(bytes, header)) {
      return *error;
    }

    if (header >= (static_cast<uint64_t>(1) << 11)) {
      return Error::INVALID_ENCODING;
    }
    precision2d = (header & 15);
    type3d = ((header >> 4) & 7);
    precision3d = ((header >> 7) & 15);
    return {};
  };

  uint32_t precision2d_encoded = 0;
  uint32_t precision3d_encoded = 0;
  uint32_t type3d_encoded = 0;
  if (auto error =
          decode_header(encoded, precision2d_encoded, precision3d_encoded, type3d_encoded)) {
    return *error;
  }

  std::optional<Type3d> type3d = [type3d_encoded] {
    switch (type3d_encoded) {
    case 1:
      return std::optional(Type3d::LEVEL);
    case 2:
      return std::optional(Type3d::ALTITUDE);
    case 3:
      return std::optional(Type3d::ELEVATION);
    case 4:
      return std::optional(Type3d::RESERVED1);
    case 5:
      return std::optional(Type3d::RESERVED2);
    case 6:
      return std::optional(Type3d::CUSTOM1);
    case 7:
      return std::optional(Type3d::CUSTOM2);
    default:
      return std::optional<Type3d>();
    }
  }();

  auto precision2d = Precision::from_u32(precision2d_encoded);
  if (!precision2d) {
    return Error::INVALID_PRECISION;
  }

  auto precision3d = Precision::from_u32(precision3d_encoded);
  if (!precision3d) {
    return Error::INVALID_PRECISION;
  }

  auto precision_to_inverse_scale = [](uint32_t precision) {
    double scale = std::pow(10, precision);
    return [scale](int64_t value) { return static_cast<double>(value) / scale; };
  };

  auto decode3d =
      [&](std::string_view &bytes, uint32_t precision2d, uint32_t precision3d,
          std::vector<std::tuple<double, double, double>> &result) -> std::optional<Error> {
    result.reserve(bytes.size() / 2);
    auto scale2d = precision_to_inverse_scale(precision2d);
    auto scale3d = precision_to_inverse_scale(precision3d);
    auto last_coord = std::make_tuple<int64_t, int64_t, int64_t>(0, 0, 0);
    while (!bytes.empty()) {
      auto delta = std::make_tuple<int64_t, int64_t, int64_t>(0, 0, 0);
      if (auto error = var_decode_i64(bytes, std::get<0>(delta))) {
        return *error;
      }
      if (auto error = var_decode_i64(bytes, std::get<1>(delta))) {
        return *error;
      }
      if (auto error = var_decode_i64(bytes, std::get<2>(delta))) {
        return *error;
      }
      std::get<0>(last_coord) += std::get<0>(delta);
      std::get<1>(last_coord) += std::get<1>(delta);
      std::get<2>(last_coord) += std::get<2>(delta);
      result.emplace_back(scale2d(std::get<0>(last_coord)), scale2d(std::get<1>(last_coord)),
                          scale3d(std::get<2>(last_coord)));
    };
    return {};
  };

  auto decode2d = [&](std::string_view &bytes, uint32_t precision2d,
                      std::vector<std::tuple<double, double>> &result) -> std::optional<Error> {
    result.reserve(bytes.size() / 2);
    auto scale2d = precision_to_inverse_scale(precision2d);
    auto last_coord = std::make_tuple<int64_t, int64_t>(0, 0);
    while (!bytes.empty()) {
      auto delta = std::make_tuple<int64_t, int64_t>(0, 0);
      if (auto error = var_decode_i64(bytes, std::get<0>(delta))) {
        return *error;
      }
      if (auto error = var_decode_i64(bytes, std::get<1>(delta))) {
        return *error;
      }
      std::get<0>(last_coord) += std::get<0>(delta);
      std::get<1>(last_coord) += std::get<1>(delta);
      result.emplace_back(scale2d(std::get<0>(last_coord)), scale2d(std::get<1>(last_coord)));
    }
    return {};
  };

  if (type3d) {
    std::vector<std::tuple<double, double, double>> coordinates;
    if (auto error = decode3d(encoded, precision2d_encoded, precision3d_encoded, coordinates)) {
      return *error;
    }
    result = Polyline3d{std::move(coordinates), *precision2d, *precision3d, *type3d};
  } else {
    std::vector<std::tuple<double, double>> coordinates;
    if (auto error = decode2d(encoded, precision2d_encoded, coordinates)) {
      return *error;
    }
    result = Polyline2d{std::move(coordinates), *precision2d};
  }
  return {};
}
} // namespace hf::flexpolyline
