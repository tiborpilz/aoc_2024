import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam/float
import simplifile

pub fn read(filepath: String) {
  filepath
  |> simplifile.read
  |> result.unwrap("")
}

pub fn read_lines(filepath: String) {
  filepath
  |> read
  |> string.trim_end
  |> string.split("\n")
}

/// Reads a file line by line and splits the rows into individual characters
pub fn read_chars(filepath: String) -> List(List(String)) {
  filepath
  |> read_lines
  |> list.map(fn(row) { string.split(row, "") })
}

pub fn parse_entry(entry: String) -> Int {
  entry
  |> string.trim
  |> int.base_parse(10)
  |> result.unwrap(0)
}

pub fn parse_row(line: String) {
  line
  |> string.split(" ")
  |> list.filter(fn(entry) { entry != "" })
  |> list.map(fn(entry) { string.trim(entry) })
  |> list.map(parse_entry)
}

pub fn format_int(n: Int) {
  n |> int.to_base_string(10) |> result.unwrap("")
}

pub fn sum(l: List(Int)) {
  list.fold(l, 0, fn(acc, n) { acc + n })
}

pub fn add_prefix(s: String, prefix: String) {
  prefix <> s
}

pub fn print_with_part(result: String, part: String) {
  io.println("(" <> part <> "): " <> result)
}

pub fn format_sum(l: List(Int), prefix: String) {
  l |> sum |> to_string |> fn(s) { prefix <> s }
}

pub fn to_string(n: Int) {
  n |> int.to_base_string(10) |> result.unwrap("")
}

pub fn join(chars: List(String)) {
  chars
  |> list.fold("", fn(acc, char) { acc <> char })
}

pub fn join_by(chars: List(String), by: String) {
  chars
  |> list.index_fold("", fn(acc, char, index) {
    case index {
      0 -> acc <> char
      _ -> acc <> by <> char
    }
  })
}

/// Gets the entry of a 1D-List at a given index
pub fn at(data: List(a), index: Int) {
  data |> list.take(index + 1) |> list.last
}

/// Given a list of strings, return a list of lists of strings,
/// seperated by empty rows
pub fn split_by_empty_row(input: List(String)) -> List(List(String)) {
  input
  |> list.fold([[]], fn(acc, line) {
    let assert [curr, ..rest] = acc

    case line {
      "" -> [[], ..[list.reverse(curr), ..rest]]
      _ -> [[line, ..curr], ..rest]
    }
  })
  |> list.reverse
}

/// Raises one integer to another integer. (The stdlib only has `power(int, float)`)
pub fn int_power(base: Int, exponent: Int) -> Int {
  let float_exponent = int.to_float(exponent)
  let assert Ok(float_result) = int.power(base, float_exponent)
  float.truncate(float_result)
}

pub fn main() {
  ["a", "", "b", "", "c"]
}
