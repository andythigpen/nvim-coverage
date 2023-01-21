cmake_minimum_required(VERSION 3.5)
find_package(Catch2 2 REQUIRED)
include(CTest)
add_executable(exampleTests exampleTests.cpp)
target_link_libraries(exampleTests PRIVATE Catch2::Catch2 example )
add_test(exampleTests exampleTests)

