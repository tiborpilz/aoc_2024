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

import gleam/string
import gleam/io
import gleam/function
import gleam/list
import utils

// The guard is either "v", "^", "<", or ">"
pub fn has_guard(grid: List(List(String))) -> Bool {
  ["^", ">", "v", "<"]
  |> list.any(fn (guard) {
    grid
    |> list.flatten()
    |> list.contains(guard)
  })
}

pub fn get_guard_direction(grid: List(List(String))) -> Result(String, Nil) {
  grid |> list.flatten |> list.find(fn (char) {
    char == "^" || char == ">" || char == "v" || char == "<"
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
    [head, ..tail] -> case head == element {
      True -> Ok(0)
      False -> case get_element_index(tail, element) {
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

    ["v", "j", .._] -> True
    ["^", "k", .._] -> True
    ["<", "h", .._] -> True
    [">", "l", .._] -> True

    [_, ..rest] -> will_loop(rest)
  }
}

pub fn pretty_print(grid: List(List(String))) {
  io.debug("---------------------------------")
  grid
  |> list.map(fn (row) { io.debug(utils.join(row)) })
  io.debug("---------------------------------")

  grid
}

pub fn get_guard_column(grid: List(List(String)), guard_row: List(String)) {
  let guard_index = guard_row
  |> list.take_while(fn (char) {
    list.contains(["^", "v", "<", ">"], char)
  })
  |> list.length

  grid
  |> list.map(fn (row) {
    let assert Ok(element) = utils.at(row, guard_index)

    element
  })
}

pub fn get_guard_list(grid: List(List(String)), guard: String) {
  let assert Ok(guard_row) = grid
  |> list.find(fn (row) {
    row_contains_guard(row)
  })

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
  list.any(row, fn (char) { list.contains(["^", "v", ">", "<"], char) })
}

pub fn update_grid(grid: List(List(String)), guard: String) -> List(List(String)) {
  // When the guard is not pointing in a horizontal direction, we need to transpose the grid first (and then transpose it back at the end)
  // (Since transposing a matrix twice is idemptotent, we can just use the same process function as its own inverse)
  let normalize_grid = case is_vertical_guard(guard) {
    True -> list.transpose
    False -> function.identity
  }

  // When the guard is pointing "forwards" (right or down), it's easier to just reverse the row before checking for the guard to prevent oob
  let normalize_row = case is_forward_guard(guard) {
    True -> function.identity
    False -> list.reverse
  }

  grid
  |> normalize_grid
  |> list.map(fn (row) {
      row |> normalize_row |> update_normalized_row |> normalize_row
    })
  |> normalize_grid
}

pub fn check_grid_for_loop(grid: List(List(String)), guard: String) -> Bool {
  let normalize_grid = case is_vertical_guard(guard) {
    True -> list.transpose
    False -> function.identity
  }

  // When the guard is pointing "forwards" (right or down), it's easier to just reverse the row before checking for the guard to prevent oob
  let normalize_row = case is_forward_guard(guard) {
    True -> function.identity
    False -> list.reverse
  }

  grid
  |> normalize_grid
  |> list.any(fn (row) { row |> normalize_row |> will_loop })
}

pub fn solve_grid(grid: List(List(String))) -> List(List(String)) {
  case get_guard_direction(grid) {
    Error(_) -> grid // no guard
    Ok(guard) -> solve_grid(update_grid(grid, guard))
  }
}

pub fn solve_grid_loops(grid: List(List(String))) -> Result(List(List(String)), Nil) {
  case get_guard_direction(grid) {
    Error(_) -> Error(Nil)
    Ok(guard) -> case check_grid_for_loop(grid, guard) {
      True -> Ok(grid)
      False -> solve_grid_loops(update_grid(grid, guard))
    }
  }
}

// For a given grid, return a list of grids, each with a single "." replaced by a "#"
pub fn get_grid_permutations(grid: List(List(String))) -> List(List(List(String))) {
  let assert [first_row, .._] = grid
  let row_length = list.length(first_row)

  let flat_grid = list.flatten(grid)

  list.range(0, list.length(flat_grid))
  |> list.map(fn (i) {
    list.index_map(flat_grid, fn(char, j) {
      case j {
        x if x == i -> case char {
          "." -> "#"
          x -> x
        }
        _ -> char
      }
    })
    |> list.sized_chunk(row_length)
  })
}

pub fn part_1() {
  "./data/day_6.txt"
  |> utils.read_lines()
  |> list.map(fn (row) { string.split(row, "") })
  |> solve_grid
  |> pretty_print
  |> list.flatten
  |> list.filter(fn (char) { char == "h" || char == "j" || char == "k" || char == "l" })
  |> list.length
  |> io.debug
}

pub fn part_2() {
  "./data/day_6.txt"
  |> utils.read_lines()
  |> list.map(fn (row) { string.split(row, "") })
  |> get_grid_permutations
  |> list.filter(fn (grid) {
    io.debug(list.length(_))

    case solve_grid_loops(grid) {
      Ok(_) -> True
      Error(_) -> False
    }
    |> io.debug
  })
  |> list.length
  |> io.debug
}

pub fn benchmark() {
  let data = "./data/day_6.txt"
  |> utils.read_lines()
  |> list.map(fn (row) { string.split(row, "") })

  list.range(0, 1000)
  |> list.map(fn (_) {
    data |> list.flatten |> list.find(fn (char) { char == "^" })
  })
}


pub fn main() {
  part_2()
}
