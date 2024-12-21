//// For part 1, matching all regexes like `mul(1,4)`, capturing the numbers and then
//// summing the products is enough.
////
//// For part 2, we can non-greedily match everything between `don't()` and `do()` (or line end)
//// and replace that with an empty string, as we don't want to consider those blocks.
//// This leaves us with the same problem as part 1, which means we can reuse the same function.


import gleam/int
import gleam/list
import gleam/option
import gleam/regexp
import utils

pub fn load_rows() {
  "./data/day_3.txt"
  |> utils.read
}

/// Parse a string and return the sum of the products defined by `mul(a, b)` expressions
pub fn get_mult_sum(s: String) {
  let assert Ok(mul_statements) =
    regexp.from_string("mul\\(([0-9]+),([0-9]+)\\)")

  s
  |> regexp.scan(mul_statements, _)
  |> list.map(fn(match) {
    let assert regexp.Match(_, [option.Some(a), option.Some(b)]) = match
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

/// Remove everything between a `don't()` and a `do()`, spanning multiple lines
pub fn remove_dont_blocks(input_string: String) {
  let assert Ok(dont_blocks) =
    regexp.from_string("don't\\(\\)(.+?)(do\\(\\)|$)")
  let assert Ok(newline) = regexp.from_string("\n")

  input_string
  |> regexp.replace(newline, _, "")
  |> regexp.replace(dont_blocks, _, "")
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
