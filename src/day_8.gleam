import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string
import grid
import utils

pub fn main() {
  let input_grid =
    "./data/day_8.txt"
    |> utils.read_lines
    |> list.map(fn(row) { string.split(row, "") })
    |> grid.from_lists

  let frequencies =
    input_grid
    |> dict.fold(set.new(), fn(acc, _, value) {
      case value != "." {
        True -> set.insert(acc, value)
        False -> acc
      }
    })
    |> set.to_list

  let antennas =
    frequencies
    |> list.map(fn(freq) {
      dict.filter(input_grid, fn(_, value) { value == freq })
      |> dict.to_list
    })

  let #(height, width) = grid.size(input_grid)

  // Tuples of coordinates with directions,
  // e.g. #(#(1,1), [#(0,1), #(1,0)] describes #(1,1), #(2,1) and #(1,2)

  let directions =
    antennas
    |> list.map(fn(locations) {
      list.combination_pairs(locations)
      |> list.map(fn(antenna_pair) {
        let #(a_antenna, b_antenna) = antenna_pair
        let #(a_coords, _) = a_antenna
        let #(b_coords, _) = b_antenna
        let #(a_y, a_x) = a_coords
        let #(b_y, b_x) = b_coords
        #(a_coords, #(b_y - a_y, b_x - a_x))
      })
    })

  let empty_antinode_grid =
    "." |> list.repeat(width) |> list.repeat(height) |> grid.from_lists

  let antenna_grid =
    antennas
    |> list.flatten
    |> list.fold(empty_antinode_grid, fn(acc_grid, antenna) {
      let #(coords, value) = antenna
      dict.insert(acc_grid, coords, value)
    })

  list.fold(directions, antenna_grid, fn(acc_grid, curr_direction) {
    curr_direction
    |> list.fold(acc_grid, fn(acc_direction, curr) {
      let #(#(start_y, start_x), #(step_y, step_x)) = curr

      // We get the max allowed factor heuristically (ignoring the offset of the antenna)
      // since we automatically discard updates that are out of bounds
      let assert Ok(max_factor_x) = int.floor_divide(width, step_x)
      let assert Ok(max_factor_y) = int.floor_divide(height, step_y)

      let factor = case max_factor_x > max_factor_y {
        True -> max_factor_x
        False -> max_factor_y
      }

      // part 1
      // let factors = [-1, 2]

      // part 2
      let factors = list.range(-1 * factor, factor)

      let update_coords =
        factors
        |> list.map(fn(factor) {
          #(start_y + { factor * step_y }, start_x + { factor * step_x })
        })

      update_coords
      |> list.fold(acc_direction, fn(acc_coords, coords) {
        grid.update_if_exists(acc_coords, coords, "#")
      })
    })
  })
  |> grid.to_lists
  |> list.map(fn(row) {
    row |> utils.join |> io.debug
    row
  })
  |> list.flatten
  |> list.filter(fn(el) { el == "#" })
  |> list.length
  |> io.debug
}
