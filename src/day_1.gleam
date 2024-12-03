import utils
import gleam/int
import gleam/io
import gleam/list

pub fn load_rows() {
    "./data/day_1.txt"
    |> utils.read_lines
    |> list.filter(fn(line) { line != "" })
    |> list.map(utils.parse_row)
    |> list.transpose
}

/// Returns the pairwise distances between the two lists, after sorting them.
pub fn get_distances(left: List(Int), right: List(Int)) {
  list.zip(list.sort(left, int.compare), list.sort(right, int.compare))
  |> list.map(fn (tuple) {
      let #(a, b) = tuple
      int.absolute_value(a - b)
    })
}

/// Returns the pairwise similarities between the two lists. Sorting doesn't matter
/// Here, as similarities are calculated based on the number of occurrences of the given number
pub fn get_similarities(left: List(Int), right: List(Int)) {
  left
  |> list.map(fn (n) {
      right
      |> list.filter(fn (m) { n == m })
      |> list.length
      |> int.multiply(n)
     })
  |> list.filter(fn (n) { n > 0 })
}

pub fn main() {
  let assert [left, right] = load_rows()

  let distances = get_distances(left, right)
  let similarities = get_similarities(left, right)

  let sum_distance = utils.format_sum(distances, "(Part 1) - Distance: ")
  let sum_similarity = utils.format_sum(similarities, "(Part 2) - Similarity: ")

  io.println(sum_distance)
  io.println(sum_similarity)
}
