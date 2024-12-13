import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
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

pub fn parse_entry(entry: String) {
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

/// Gets the entry of a 1D-List at a given index
pub fn at(data: List(a), index: Int) {
  data |> list.take(index + 1) |> list.last
}
