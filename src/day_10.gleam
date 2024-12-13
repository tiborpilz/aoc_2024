import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import grid
import utils

pub fn get_trailheads(grid: grid.Grid(Int)) -> List(#(Int, Int)) {
  grid
  |> dict.filter(fn(_, value) { value == 0 })
  |> dict.to_list
  |> list.map(fn(entry) { entry.0 })
}

pub fn get_surrounding_entries(
  grid: grid.Grid(Int),
  position: #(Int, Int),
) -> List(#(Int, Int)) {
  let #(original_y, original_x) = position

  let surrounding_positions = [
    #(original_y, original_x - 1),
    #(original_y, original_x + 1),
    #(original_y - 1, original_x),
    #(original_y + 1, original_x),
  ]

  surrounding_positions
  |> list.fold([], fn(entries, pos) {
    let #(y, x) = pos
    case dict.get(grid, #(y, x)) {
      Ok(_) ->
        case y, x {
          y, x if x == original_x && y == original_y -> entries
          _, _ -> [#(y, x), ..entries]
        }
      _ -> entries
    }
  })
}

pub fn get_start_positions(grid: grid.Grid(Int)) -> List(#(Int, Int)) {
  grid
  |> dict.filter(fn(_, value) { value == 0 })
  |> dict.to_list
  |> list.map(fn(pair) { pair.0 })
}

pub fn grid_to_string(grid: grid.Grid(Int)) -> grid.Grid(String) {
  dict.map_values(grid, fn(_, value) { int.to_string(value) })
}

pub fn get_paths(
  grid: grid.Grid(Int),
  position: #(Int, Int),
  current_path: List(#(Int, Int)),
  paths: List(List(#(Int, Int))),
) -> List(List(#(Int, Int))) {
  let assert Ok(current_elevation) = dict.get(grid, position)

  let new_positions =
    grid
    |> get_surrounding_entries(position)
    |> list.filter(fn(surrounding_position) {
      let assert Ok(surrounding_elevation) =
        dict.get(grid, surrounding_position)
      surrounding_elevation == current_elevation + 1
    })

  case current_elevation {
    9 -> [[position, ..current_path], ..paths]
    _ ->
      case list.length(new_positions) {
        0 -> paths
        _ ->
          list.map(new_positions, fn(new_position) {
            get_paths(grid, new_position, [position, ..current_path], paths)
          })
          |> list.flatten
      }
  }
}

pub fn get_unique_endpoints(paths: List(List(#(Int, Int)))) {
  paths
  |> list.map(fn(path) {
    let assert Ok(pos) = list.first(path)
    pos
  })
  |> list.unique
}

pub fn main() {
  let grid =
    "./data/day_10.txt"
    |> utils.read_lines
    |> list.map(fn(row) {
      string.split(row, "")
      |> list.map(fn(entry) {
        let assert Ok(n) = int.parse(entry)
        n
      })
    })
    |> grid.from_lists

  get_start_positions(grid)
  |> list.map(fn(start_position) {
    get_paths(grid, start_position, [], [])
    // |> get_unique_endpoints // uncomment for part 1
    |> list.length
  })
  |> utils.sum
  |> io.debug
}
