import { fizzbuzz } from "./fizzbuzz";

test("fizzbuzz", () => {
  expect(fizzbuzz(3)).toBe("fizz");
  expect(fizzbuzz(5)).toBe("buzz");
  expect(fizzbuzz(15)).toBe("fizzbuzz");
});
