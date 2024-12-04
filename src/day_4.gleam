// The idea is to split the incoming lines into a 2D array of single characters,
// then we can iterate over sliding windows of 4 characters horizontally, vertically
// and diagonally and check for "XMAS" ans "SAMX" in these windows, adding to the count.

import gleam/result
import gleam/option
import gleam/io
import gleam/string
import gleam/list
import utils

fn join(chars: List(String)) {
  chars
  |> list.fold("", fn (acc, char) { acc <> char })
}

fn check(chars: List(String)) {
  chars
  |> list.window(4)
  |> list.map(join)
  |> list.filter(fn (window) { window == "XMAS" || window == "SAMX" })
  |> list.length
}

/// Gets the entry at a given index
fn at(data: List(a), index: Int) {
  data |> list.take(index + 1) |> list.last
}

/// Gets all 4 line diagonals from a given grid
fn get_diagonals(data: List(List(String))) {
  data
  |> list.window(4)
  |> list.flat_map(fn (chunk) {
    chunk
    |> list.map(fn (row) {
      row
      |> list.window(4)
    })
    |> list.transpose
    |> list.flat_map(fn (chunk) {
      let get_diagonal = fn (i) {
        chunk |> at(i) |> result.unwrap([""]) |> at(i) |> result.unwrap("")
      }
      let get_diagonal_backwards = fn (i) {
        chunk |> at(3 - i) |> result.unwrap([""]) |> at(i) |> result.unwrap("")
      }

      let forwards = list.range(0, 3)
      |> list.map(get_diagonal)

      let backwards = list.range(0, 3)
      |> list.map(get_diagonal_backwards)

      [forwards, backwards]
    })
  })
}

pub fn part_test() {
  let data = "./data/day_4.txt"
  |> utils.read_lines
  |> list.map(fn (line) { line |> string.split("") })

  let horizontal = data
  |> list.map(check)
  |> utils.sum

  let vertical = data
  |> list.transpose
  |> list.map(check)
  |> utils.sum

  let diagonal = get_diagonals(data)
  |> list.map(check)
  |> utils.sum

  horizontal + vertical + diagonal
  |> io.debug
}

pub fn part_1() {
  "./data/day_4.txt"
  |> utils.read_lines
}

pub fn main() {
  part_test()
}
