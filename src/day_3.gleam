import gleam/option.{Some}
import gleam/regex.{from_string,scan,replace,Match}
import gleam/int
import gleam/list
import utils

pub fn load_rows() {
  "./data/day_3.txt"
  |> utils.read
}

// For part 1, matching all regexes like `mul(1,4)`, capturing the numbers and then
// summing the products is enough.

/// Parse a string and return the sum of the products defined by the `mul(a, b)` pattern
pub fn get_mult_sum(s: String) {
  let assert Ok(mul_statements) = from_string("mul\\(([0-9]+),([0-9]+)\\)")

  s
  |> scan(mul_statements, _)
  |> list.map(fn(match) {
    let assert Match(_, [Some(a), Some(b)]) = match
    let assert Ok(a_parsed) = a |> int.base_parse(10)
    let assert Ok(b_parsed) = b |> int.base_parse(10)
    a_parsed * b_parsed
  })
  |> utils.sum
}

pub fn part_1() {
  load_rows()
  |> get_mult_sum
  |> utils.format_int
}

// For part 2, we can non-greedily match everything between `don't()` and `do()` (or line end)
// and replace that with an empty string, as we don't want to consider those blocks.
// This leaves us with the same problem as part 1, which means we can reuse the same function.

/// Remove everything between a `don't()` and a `do()`, spanning multiple lines
pub fn remove_dont_blocks(s: String) {
  let assert Ok(dont_blocks) = from_string("don't\\(\\)(.+?)(do\\(\\)|$)")
  let assert Ok(newline) = from_string("\n")

  s
  |> replace(newline, _, "")
  |> replace(dont_blocks, _, "")
}

pub fn part_2() {
  load_rows()
  |> remove_dont_blocks
  |> get_mult_sum
  |> utils.format_int
}

pub fn main() {
  part_1() |> utils.print_with_part("Part 1")
  part_2() |> utils.print_with_part("Part 2")
}
