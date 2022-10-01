from typing import Union

import pytest
from .fizzbuzz import fizzbuzz


@pytest.mark.parametrize(
    ["num", "expected"],
    [
        [3, "fizz"],
        [5, "buzz"],
        [15, "fizzbuzz"],
    ],
)
def test_fizzbuzz(num: int, expected: Union[str, int]):
    assert fizzbuzz(num) == expected
