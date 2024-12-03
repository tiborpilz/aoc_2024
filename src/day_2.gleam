import utils
import gleam/int
import gleam/list
import gleam/io

fn safe_dist(a: Int, b: Int) {
  case int.absolute_value(a - b) {
    i if i >= 1 && i <= 3 -> True
    _ -> False
  }
}

fn ascending(l: List(Int)) {
  case l {
    [] -> True
    [_] -> True
    [x, y, ..rest] -> x < y && safe_dist(x, y) && ascending([y, ..rest])
  }
}

fn descending(l: List(Int)) {
  case l {
    [] -> True
    [_] -> True
    [x, y, ..rest] -> x > y && safe_dist(x, y) && descending([y, ..rest])
  }
}

fn strictly_monotone(l: List(Int)) {
  ascending(l) || descending(l)
}

pub fn main() {
  let filepath = "./data/day_2.txt"
  filepath
  |> utils.read_lines
  |> list.map(utils.parse_row)
  |> list.filter(strictly_monotone)
  |> list.length
  |> utils.format_int
  |> io.println
}
