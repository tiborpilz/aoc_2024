//// The general idea is to split the incoming lines into a 2D array of single characters,
//// then we can iterate over sliding windows of 4 characters horizontally, vertically
//// and diagonally and check for "XMAS" ans "SAMX" in these windows, adding to the count.
////
//// Part 2 is very similar, only we check each element's cross value which we first get as
//// a list of list of strings.
////
//// (This solution would benefit from using the shared `grid` module, but I haven't built that at that time).

import gleam/io
import gleam/list
import gleam/string
import utils

pub fn check(chars: List(String)) {
  chars
  |> list.window(4)
  |> list.map(utils.join)
  |> list.filter(fn(window) { window == "XMAS" || window == "SAMX" })
  |> list.length
}

pub fn count_crosses(crosses: List(List(String))) {
  crosses
  |> list.map(utils.join)
  |> list.filter(fn(cross) {
    cross == "MASSAM"
    || cross == "SAMMAS"
    || cross == "SAMSAM"
    || cross == "MASMAS"
  })
  |> list.length
}

/// Gets the entry of a 1D-List at a given index
pub fn at(data: List(a), index: Int) {
  data |> list.take(index + 1) |> list.last
}

/// Gets the entry at a 2D-List given xy index
pub fn at_xy(data: List(List(a)), y: Int, x: Int) {
  let assert Ok(row) = data |> at(x)
  let assert Ok(entry) = row |> at(y)
  entry
}

/// Get nxn chunks from a bigger mxm grid
pub fn get_chunks(data: List(List(String)), chunk_size: Int) {
  data
  |> list.window(chunk_size)
  |> list.flat_map(fn(chunk) {
    chunk
    |> list.map(fn(row) { row |> list.window(chunk_size) })
    |> list.transpose
  })
}

/// Gets all 4 line diagonals from a given grid
pub fn get_diagonals(data: List(List(String))) {
  data
  |> get_chunks(4)
  |> list.flat_map(fn(chunk) {
    let get_diagonal = fn(i) { chunk |> at_xy(i, i) }
    let get_diagonal_backwards = fn(i) { chunk |> at_xy(3 - i, i) }

    let forwards =
      list.range(0, 3)
      |> list.map(get_diagonal)

    let backwards =
      list.range(0, 3)
      |> list.map(get_diagonal_backwards)

    [forwards, backwards]
  })
}

/// Gets all 3-line Crosses from a given grid
pub fn get_crosses(data: List(List(String))) {
  data
  |> get_chunks(3)
  |> list.map(fn(chunk) {
    [
      at_xy(chunk, 0, 0),
      at_xy(chunk, 1, 1),
      at_xy(chunk, 2, 2),
      at_xy(chunk, 2, 0),
      at_xy(chunk, 1, 1),
      at_xy(chunk, 0, 2),
    ]
  })
}

pub fn get_data() {
  "./data/day_4.txt"
  |> utils.read_lines
  |> list.map(fn(line) { line |> string.split("") })
}

pub fn part_1() {
  let data = get_data()

  let horizontal =
    data
    |> list.map(check)
    |> utils.sum

  let vertical =
    data
    |> list.transpose
    |> list.map(check)
    |> utils.sum

  let diagonal =
    get_diagonals(data)
    |> list.map(check)
    |> utils.sum

  horizontal + vertical + diagonal
}

pub fn part_2() {
  let data = get_data()

  let crosses =
    data
    |> get_crosses

  crosses
  |> count_crosses
  |> io.debug
}

pub fn main() {
  part_2()

  Nil
}
