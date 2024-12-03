import utils
import gleam/int
import gleam/io
import gleam/list

pub fn main() {
  let filepath = "./data/day_1.txt"
  let assert [left, right] =
    filepath
    |> utils.read_lines
    |> list.filter(fn(line) { line != "" })
    |> list.map(utils.parse_row)
    |> list.transpose


  let distances = list.zip(list.sort(left, int.compare), list.sort(right, int.compare))
    |> list.map(fn (tuple) {
        let #(a, b) = tuple
        int.absolute_value(a - b)
      })

  let similarity = left
    |> list.map(fn (n) {
        right
        |> list.filter(fn (m) { n == m })
        |> list.length
        |> int.multiply(n)
       })
    |> list.filter(fn (n) { n > 0 })

  let sum_distance = utils.format_sum(distances, "Distance: ")
  let sum_similarity = utils.format_sum(similarity, "Similarity: ")

  io.println(sum_distance)
  io.println(sum_similarity)
}
