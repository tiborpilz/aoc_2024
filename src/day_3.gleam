import gleam/option.{Some}
import gleam/regex.{from_string,scan,replace,Match}
import gleam/string
import gleam/int
import gleam/io
import gleam/list
import utils

/// Remove everything between a `don't()` and a `do()`, spanning multiple lines
pub fn remove_dont_blocks(s: String) {
  let assert Ok(dont_blocks) = from_string("don't\\(\\)(.+?)(do\\(\\)|$)")
  let assert Ok(newline) = from_string("\n")

  s
  |> replace(newline, _, "")
  |> replace(dont_blocks, _, "")
}

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

pub fn main() {
  "./data/day_3.txt"
  |> utils.read
  |> remove_dont_blocks // use for part 2
  |> get_mult_sum
  |> utils.format_int
  |> io.println
}
