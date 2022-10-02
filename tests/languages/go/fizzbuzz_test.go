package main

import "testing"

func TestFizzbuzz(t *testing.T) {
	got := fizzbuzz(3)
	if got != "fizz" {
		t.Errorf("fizzbuzz(3) = %s; want \"fizz\"", got)
	}
	got = fizzbuzz(5)
	if got != "buzz" {
		t.Errorf("fizzbuzz(5) = %s; want \"buzz\"", got)
	}
	got = fizzbuzz(15)
	if got != "fizzbuzz" {
		t.Errorf("fizzbuzz(15) = %s; want \"fizzbuzz\"", got)
	}
}
