#define CATCH_CONFIG_MAIN // This tells Catch to provide a main() - only do this
                          // in one cpp file
#include "../src/example.hpp"
#include <catch2/catch.hpp>
#include <cstdint>

TEST_CASE("first method", "[firstMethodTest]") {
  for (auto i = 0; i < 100; i++) {
    REQUIRE(firstMethod(i) == i - 1);
  }
}

TEST_CASE("second method", "[secondMethodTest]") {
  for (auto i = 0; i < 100; i++) {
    // REQUIRE(secondMethod(i) == i + 1);
  }
}
