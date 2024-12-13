import utils.{format_sum, read_lines}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

fn parse_entry(entry: String) {
  entry
  |> string.trim
  |> int.base_parse(10)
  |> result.unwrap(0)
}

fn parse_row(line: String) {
  line
  |> string.split("  ")
  |> list.map(parse_entry)
}

pub fn get_data() {
  let filepath = "./data/day_1.txt"
  let assert [left, right] =
    filepath
    |> read_lines
    |> list.filter(fn(line) { line != "" })
    |> list.map(parse_row)
    |> list.transpose

  #(left, right)
}

pub fn part_1() {
  let #(left, right) = get_data()
  let distances = list.zip(list.sort(left, int.compare), list.sort(right, int.compare))
    |> list.map(fn (tuple) {
        let #(a, b) = tuple
        int.absolute_value(a - b)
      })

  io.println(format_sum(distances, "Distance: "))
}

pub fn part_2() {
  let #(left, right) = get_data()
  let similarity = left
    |> list.map(fn (n) {
        right
        |> list.filter(fn (m) { n == m })
        |> list.length
        |> int.multiply(n)
       })
    |> list.filter(fn (n) { n > 0 })

  io.println(format_sum(similarity, "Similarity: "))
}

pub fn main() {
  part_1()
  part_2()
}
