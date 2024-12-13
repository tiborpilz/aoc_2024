// Idea; Reuse the 2D window thing from day 4
// treat the whole thing as a 2D cellular automaton
// Scan for 3x3 windows that contain the player character
// ("^", ">", "v", "<").

// Second idea: recursive function:
// If no ">" or similar character is found, return the 2D array.
// Otherwise, find that character, check the direction its pointing, and then update the grid:
// - If it is pointing "outside", so ">" is at the right edge, etc., replace the character with "."
// - If it is pointing at "." or "X", replace the arrow with "X" and the "." with the arrow.
// - If it is pointing at "#", rotate it by 90 degrees
// Then, call the function again with the updated grid.

import gleam/dict
import gleam/io
import gleam/list
import gleam/string
import grid
import utils

// The guard is either "v", "^", "<", or ">"
pub fn has_guard(grid: List(List(String))) -> Bool {
  ["^", ">", "v", "<"]
  |> list.any(fn(guard) {
    grid
    |> list.flatten()
    |> list.contains(guard)
  })
}

pub fn is_vertical_guard(guard: String) -> Bool {
  guard == "^" || guard == "v"
}

pub fn is_forward_guard(guard: String) -> Bool {
  guard == ">" || guard == "v"
}

pub fn get_element_index(row: List(a), element: a) -> Result(Int, Nil) {
  case row {
    [] -> Error(Nil)
    [head, ..tail] ->
      case head == element {
        True -> Ok(0)
        False ->
          case get_element_index(tail, element) {
            Error(Nil) -> Error(Nil)
            Ok(n) -> Ok(n + 1)
          }
      }
  }
}

// Normalized means that if a guard is vertical, the corresponding grid has been transposed
// and if a guard is pointing to the left or up, the row has been reverted.
// This means that we can assume that a guard always moves in the direction of the list.
pub fn update_normalized_row(row: List(String)) -> List(String) {
  // let pairs = row
  // |> list.window(2)
  // |> list.map(fn (pair) {
  //   let assert [l, r] = pair

  //   case l, r {
  //     "v", "#" -> ["<", "#"]
  //     "^", "#" -> [">", "#"]
  //     "<", "#" -> ["^", "#"]
  //     ">", "#" -> ["v", "#"]

  //     "v", _ -> ["j", "v"]
  //     "^", _ -> ["k", "^"]
  //     "<", _ -> ["h", "<"]
  //     ">", _ -> ["l", ">"]

  //     x, "v" -> [x, "j"]
  //     x, "^" -> [x, "k"]
  //     x, "<" -> [x, "h"]
  //     x, ">" -> [x, "l"]

  //     a, b -> [a, b]
  //   }
  // })

  // let assert Ok(last_pair) = list.last(pairs)
  // let assert Ok(last_element) = list.last(last_pair)

  // let first_of_pairs = pairs |> list.map(fn (p) {
  //   let assert Ok(element) = list.first(p)
  //   element
  // })

  // list.append(first_of_pairs, [last_element])
  case row {
    [] -> []

    ["v"] -> ["j"]
    ["^"] -> ["k"]
    ["<"] -> ["h"]
    [">"] -> ["l"]

    ["v", "#", ..rest] -> list.flatten([["<", "#"], rest])
    ["^", "#", ..rest] -> list.flatten([[">", "#"], rest])
    ["<", "#", ..rest] -> list.flatten([["^", "#"], rest])
    [">", "#", ..rest] -> list.flatten([["v", "#"], rest])

    ["v", _, ..rest] -> list.flatten([["j", "v"], rest])
    ["^", _, ..rest] -> list.flatten([["k", "^"], rest])
    ["<", _, ..rest] -> list.flatten([["h", "<"], rest])
    [">", _, ..rest] -> list.flatten([["l", ">"], rest])

    [x, ..rest] -> [x, ..update_normalized_row(rest)]
  }
}

pub fn will_loop(row: List(String)) -> Bool {
  case row {
    [] -> False
    [_] -> False

    ["v", "j", ..] -> True
    ["^", "k", ..] -> True
    ["<", "h", ..] -> True
    [">", "l", ..] -> True

    [_, ..rest] -> will_loop(rest)
  }
}

pub fn pretty_print(grid: grid.Grid(String)) {
  io.debug("---------------------------------")
  grid
  |> grid.to_lists
  |> list.map(fn(row) { io.debug(utils.join(row)) })
  io.debug("---------------------------------")

  grid
}

pub fn get_guard_column(grid: List(List(String)), guard_row: List(String)) {
  let guard_index =
    guard_row
    |> list.take_while(fn(char) { list.contains(["^", "v", "<", ">"], char) })
    |> list.length

  grid
  |> list.map(fn(row) {
    let assert Ok(element) = utils.at(row, guard_index)

    element
  })
}

pub fn get_guard_list(grid: List(List(String)), guard: String) {
  let assert Ok(guard_row) =
    grid
    |> list.find(fn(row) { row_contains_guard(row) })

  let guard_list = case is_vertical_guard(guard) {
    True -> get_guard_column(grid, guard_row)
    False -> guard_row
  }

  case is_forward_guard(guard) {
    True -> guard_list
    False -> list.reverse(guard_list)
  }
}

pub fn row_contains_guard(row: List(String)) -> Bool {
  list.any(row, fn(char) { list.contains(["^", "v", ">", "<"], char) })
}

pub fn check_grid_for_loop(
  grid: grid.Grid(String),
  guard: grid.Element(String),
) -> Bool {
  let assert Ok(target) = get_next_guard_pos(guard)

  case dict.get(grid, target), guard {
    Ok("k"), #(_, "^") -> True
    Ok("l"), #(_, ">") -> True
    Ok("j"), #(_, "v") -> True
    Ok("h"), #(_, "<") -> True
    _, _ -> False
  }
}

// Only generate a permutation if the obstacle's target coord is in the previously solved path
fn should_create_permutation(
  grid: grid.Grid(String),
  coords: #(Int, Int),
) -> Bool {
  case grid.get(grid, coords) {
    Ok(char) -> list.contains(["h", "j", "k", "l"], char)
    _ -> False
  }
}

// For a given grid, return a list of grids, each with a single "." replaced by a "#"
pub fn get_grid_permutations(
  grid: grid.Grid(String),
  original_grid: grid.Grid(String),
) -> List(grid.Grid(String)) {
  let #(height, width) = grid.size(grid)

  list.range(0, height - 1)
  |> list.map(fn(y) {
    list.range(0, width - 1)
    |> list.filter(fn(x) { should_create_permutation(grid, #(y, x)) })
    |> list.map(fn(x) { dict.insert(original_grid, #(y, x), "#") })
  })
  |> list.flatten
}

pub fn find_guard(grid: grid.Grid(String)) -> Result(grid.Element(String), Nil) {
  let candidates =
    grid
    |> dict.filter(fn(_, char) {
      char == "^" || char == ">" || char == "v" || char == "<"
    })
    |> dict.to_list()

  case candidates {
    [] -> Error(Nil)
    [guard] -> Ok(guard)
    _ -> Error(Nil)
    // multiple guards D:
  }
}

pub fn get_next_guard_pos(
  guard: grid.Element(String),
) -> Result(#(Int, Int), Nil) {
  let #(#(y, x), guard_char) = guard
  case guard_char {
    "^" -> Ok(#(y - 1, x))
    ">" -> Ok(#(y, x + 1))
    "v" -> Ok(#(y + 1, x))
    "<" -> Ok(#(y, x - 1))
    _ -> Error(Nil)
  }
}

fn rotate_guard_char(char: String) -> String {
  case char {
    "^" -> ">"
    ">" -> "v"
    "v" -> "<"
    "<" -> "^"
    x -> x
    // shouldn't happen
  }
}

fn rotate_guard(grid: grid.Grid(String), guard: grid.Element(String)) {
  let #(coords, prev_char) = guard
  let next_char = rotate_guard_char(prev_char)

  grid.update_if_exists(grid, coords, next_char)
}

fn get_guard_trail(guard_char: String) -> String {
  case guard_char {
    "^" -> "k"
    ">" -> "l"
    "v" -> "j"
    "<" -> "h"
    x -> x
    // shouldn't happen
  }
}

fn move_guard(
  grid: grid.Grid(String),
  guard: grid.Element(String),
  target: #(Int, Int),
) -> grid.Grid(String) {
  let #(guard_coords, guard_char) = guard
  let trail = get_guard_trail(guard_char)

  grid
  |> grid.update_if_exists(guard_coords, trail)
  |> grid.update_if_exists(target, guard_char)
}

pub fn update_grid(
  grid: grid.Grid(String),
  guard: grid.Element(String),
) -> grid.Grid(String) {
  let assert Ok(target) = get_next_guard_pos(guard)
  let should_rotate = case dict.get(grid, target) {
    Ok("#") -> True
    _ -> False
  }

  case should_rotate {
    True -> rotate_guard(grid, guard)
    False -> move_guard(grid, guard, target)
  }
}

pub fn solve_grid(grid: grid.Grid(String)) -> grid.Grid(String) {
  case find_guard(grid) {
    Error(_) -> grid
    // no guard
    Ok(guard) -> solve_grid(update_grid(grid, guard))
  }
}

pub fn solve_grid_loops(
  grid: grid.Grid(String),
  previously_seen_grids: List(grid.Grid(String)),
) -> Result(grid.Grid(String), Nil) {
  case list.contains(previously_seen_grids, grid) {
    True -> Ok(grid)
    False ->
      case find_guard(grid) {
        Error(_) -> Error(Nil)
        Ok(guard) ->
          solve_grid_loops(update_grid(grid, guard), [
            grid,
            ..previously_seen_grids
          ])
      }
  }
}

pub fn part_2() {
  let original_grid =
    "./data/day_6.txt"
    |> utils.read_lines()
    |> list.map(fn(row) { string.split(row, "") })
    |> grid.from_lists

  original_grid
  |> solve_grid
  |> get_grid_permutations(original_grid)
  |> list.index_map(fn(grid, index) { #(grid, index) })
  |> list.filter(fn(pair) {
    let #(grid, index) = pair
    io.debug(index)
    case solve_grid_loops(grid, []) {
      Ok(_) -> True
      Error(_) -> False
    }
    |> io.debug
  })
  |> list.length
  |> io.debug
}

pub fn part_1() {
  "./data/day_6.txt"
  |> utils.read_lines()
  |> list.map(fn(row) { string.split(row, "") })
  |> grid.from_lists
  |> solve_grid
  |> pretty_print
  |> grid.to_lists
  |> list.flatten
  |> list.filter(fn(char) {
    char == "h" || char == "j" || char == "k" || char == "l"
  })
  |> list.length
  |> io.debug
}

pub fn main() {
  part_2()
}
