import gleam/list
import gleam/int
import gleam/result
import gleam/string
import simplifile

pub fn read_lines(filepath: String) {
  filepath
  |> simplifile.read
  |> result.unwrap("")
  |> string.trim_end
  |> string.split("\n")
}

pub fn sum(l: List(Int)) {
  list.fold(l, 0, fn(acc, n) { acc + n })
}

pub fn format_sum(l: List(Int), prefix: String) {
  l |> sum |> to_string |> fn (s) { prefix <> s }
}

pub fn to_string(n: Int) {
  n |> int.to_base_string(10) |> result.unwrap("")
}
