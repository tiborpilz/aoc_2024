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
    ["^", ">", "v", "<"]
    |> list.find(fn (guard) {
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
  case row {
    [] -> []

    ["v"] -> ["x"]
    ["^"] -> ["x"]
    ["<"] -> ["x"]
    [">"] -> ["x"]

    ["v", "#", ..rest] -> list.flatten([["<", "#"], rest])
    ["^", "#", ..rest] -> list.flatten([[">", "#"], rest])
    ["<", "#", ..rest] -> list.flatten([["^", "#"], rest])
    [">", "#", ..rest] -> list.flatten([["v", "#"], rest])

    ["v", _, ..rest] -> list.flatten([["x", "v"], rest])
    ["^", _, ..rest] -> list.flatten([["x", "^"], rest])
    ["<", _, ..rest] -> list.flatten([["x", "<"], rest])
    [">", _, ..rest] -> list.flatten([["x", ">"], rest])

    [x, ..rest] -> list.flatten([[x], update_normalized_row(rest)])
  }
}

pub fn pretty_print(grid: List(List(String))) {
  io.debug("---------------------------------")
  grid
  |> list.map(fn (row) { io.debug(utils.join(row)) })
  io.debug("---------------------------------")
  io.debug("")
  io.debug("")
  io.debug("")

  grid
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
  |> pretty_print
}

pub fn solve_grid(grid: List(List(String))) -> List(List(String)) {
  case get_guard_direction(grid) {
    Error(_) -> grid // no guard
    Ok(guard) -> solve_grid(update_grid(grid, guard))
  }
}

pub fn main() {
  "./data/day_6.txt"
  |> utils.read_lines()
  |> list.map(fn (row) { string.split(row, "") })
  |> solve_grid
  |> pretty_print
  |> list.flatten
  |> list.filter(fn (char) { char == "x" })
  |> list.length
  |> io.debug
}
