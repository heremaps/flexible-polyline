/*
 * Copyright (C) 2019 HERE Europe B.V.
 * Licensed under MIT, see full license in LICENSE
 * SPDX-License-Identifier: MIT
 * License-Filename: LICENSE
 */
#include <hf/flexpolyline.h>
#include <sstream>
#include <vector>
#include <tuple>
#include <iostream>

template<typename T, typename S>
void assert_eq(const T& lhs, const S& rhs) {
    if (lhs != rhs) {
        std::stringstream buf;
        buf << lhs << " != " << rhs;
        throw std::runtime_error(buf.str());
    }
}

void assert_true(bool value) {
    if (!value) {
        throw std::runtime_error("Assert failed");
    }
}


void test_convert_value() {
    std::string buf;
    auto conv = encoder::Converter(5);
    conv.encode_value(-179.98321, buf);
    assert_eq(buf, "h_wqiB");
}

void test_get_third_dimension() {
    assert_true(hf::get_third_dimension("BFoz5xJ67i1BU") == hf::ThirdDim::ABSENT);
    assert_true(hf::get_third_dimension("BVoz5xJ67i1BU") == hf::ThirdDim::LEVEL);
    assert_true(hf::get_third_dimension("BlBoz5xJ67i1BU") == hf::ThirdDim::ALTITUDE);
    assert_true(hf::get_third_dimension("B1Boz5xJ67i1BU") == hf::ThirdDim::ELEVATION);
}


void test_encode1() {
    std::vector<std::pair<double, double>> input{{
        {50.1022829, 8.6982122},
        {50.1020076, 8.6956695},
        {50.1006313, 8.6914960},
        {50.0987800, 8.6875156},
    }};

    const char* expected = "BFoz5xJ67i1B1B7PzIhaxL7Y";
    assert_eq(hf::polyline_encode(input), expected);
}

void test_encode2() {
    std::vector<std::pair<double, double>> input{{
        {52.5199356, 13.3866272},
        {52.5100899, 13.2816896},
        {52.4351807, 13.1935196},
        {52.4107285, 13.1964502},
        {52.38871, 13.1557798},
        {52.3727798, 13.1491003},
        {52.3737488, 13.1154604},
        {52.3875198, 13.0872202},
        {52.4029388, 13.0706196},
        {52.4105797, 13.0755529},
    }};

    const char* expected = "BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e";
    assert_eq(hf::polyline_encode(input), expected);
}

void test_encode3() {
    std::vector<std::tuple<double, double, double>> input{{
        {50.1022829, 8.6982122, 10},
        {50.1020076, 8.6956695, 20},
        {50.1006313, 8.6914960, 30},
        {50.0987800, 8.6875156, 40},
    }};

    const char* expected = "BlBoz5xJ67i1BU1B7PUzIhaUxL7YU";
    assert_eq(hf::polyline_encode(input, 5, hf::ThirdDim::ALTITUDE), expected);
}

void test_decode1() {
    std::vector<std::pair<double, double>> polyline;
    auto res = hf::polyline_decode("BFoz5xJ67i1B1B7PzIhaxL7Y", [&polyline](double lat, double lng, double z) {
        polyline.push_back({lat, lng});
    });
    assert_true(res);
    std::vector<std::pair<double, double>> expected{{
        {50.10228, 8.69821},
        {50.10201, 8.69567},
        {50.10063, 8.69150},
        {50.09878, 8.68752},
    }};

    assert_eq(polyline.size(), expected.size());
    for (size_t i = 0; i < polyline.size(); ++i) {
        double delta_lat = std::abs(polyline[i].first - expected[i].first);
        double delta_lng = std::abs(polyline[i].second - expected[i].second);
        assert_true(delta_lat <= 0.000001);
        assert_true(delta_lng <= 0.000001);
    }
}

void test_decode2() {
    std::vector<std::pair<double, double>> polyline;
    auto res = hf::polyline_decode("BF05xgKuy2xCx9B7vUl0OhnR54EqSzpEl-HxjD3pBiGnyGi2CvwFsgD3nD4vB6e", [&polyline](double lat, double lng, double z) {
        polyline.push_back({lat, lng});
    });
    assert_true(res);
    std::vector<std::pair<double, double>> expected{{
        {52.51994, 13.38663},
        {52.51009, 13.28169},
        {52.43518, 13.19352},
        {52.41073, 13.19645},
        {52.38871, 13.15578},
        {52.37278, 13.14910},
        {52.37375, 13.11546},
        {52.38752, 13.08722},
        {52.40294, 13.07062},
        {52.41058, 13.07555},
    }};

    assert_eq(polyline.size(), expected.size());
    for (size_t i = 0; i < polyline.size(); ++i) {
        double delta_lat = std::abs(polyline[i].first - expected[i].first);
        double delta_lng = std::abs(polyline[i].second - expected[i].second);
        assert_true(delta_lat <= 0.000001);
        assert_true(delta_lng <= 0.000001);
    }
}

void test_decode3() {
    std::vector<std::tuple<double, double, double>> polyline;
    auto res = hf::polyline_decode("BlBoz5xJ67i1BU1B7PUzIhaUxL7YU", [&polyline](double lat, double lng, double z) {
        polyline.push_back({lat, lng, z});
    });
    assert_true(res);
    std::vector<std::tuple<double, double, double>> expected{{
        {50.10228, 8.69821, 10},
        {50.10201, 8.69567, 20},
        {50.10063, 8.69150, 30},
        {50.09878, 8.68752, 40},
    }};

    assert_eq(polyline.size(), expected.size());
    for (size_t i = 0; i < polyline.size(); ++i) {
        double delta_lat = std::abs(std::get<0>(polyline[i]) - std::get<0>(expected[i]));
        double delta_lng = std::abs(std::get<1>(polyline[i]) - std::get<1>(expected[i]));
        double delta_z = std::abs(std::get<2>(polyline[i]) - std::get<2>(expected[i]));
        assert_true(delta_lat <= 0.000001);
        assert_true(delta_lng <= 0.000001);
        assert_true(delta_z <= 0.000001);
    }
}

int main(int argc, char const *argv[])
{
    test_convert_value();
    test_encode1();
    test_encode2();
    test_encode3();
    test_decode1();
    test_decode2();
    test_decode3();
    test_get_third_dimension();
    return 0;
}
