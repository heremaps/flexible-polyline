cmake_minimum_required(VERSION 3.5)
project(flexpolyline)

add_library(flexpolyline INTERFACE)
target_include_directories(flexpolyline INTERFACE include)

add_executable(flexpolyline_cli src/cli.cpp)
set_property(TARGET flexpolyline_cli PROPERTY CXX_STANDARD 17)
target_link_libraries(flexpolyline_cli flexpolyline)

if(MSVC)
  target_compile_options(flexpolyline_cli PRIVATE /W4 /WX)
else()
  target_compile_options(flexpolyline_cli PRIVATE -Wall -Wextra -pedantic -Werror)
endif()

enable_testing()
add_executable(test_polyline test/test.cpp)
set_property(TARGET test_polyline PROPERTY CXX_STANDARD 17)
target_link_libraries(test_polyline flexpolyline)
add_test(NAME test_polyline COMMAND test_polyline)

if(MSVC)
  target_compile_options(test_polyline PRIVATE /W4 /WX)
else()
  target_compile_options(test_polyline PRIVATE -Wall -Wextra -pedantic -Werror)
endif()