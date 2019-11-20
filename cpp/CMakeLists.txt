cmake_minimum_required(VERSION 3.5)
project(flexpolyline)

add_library(flexpolyline INTERFACE)
target_include_directories(flexpolyline INTERFACE include)

enable_testing()
add_executable(test_polyline test/test.cpp)
set_property(TARGET test_polyline PROPERTY CXX_STANDARD 11)
target_link_libraries(test_polyline flexpolyline)
add_test(NAME test_polyline COMMAND test_polyline)
