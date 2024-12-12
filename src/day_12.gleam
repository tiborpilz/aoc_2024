import gleam/list
import gleam/int
import gleam/io
import gleam/dict
import gleam/string
import gleam/result
import grid
import utils

type Region = #(String, List(#(Int, Int)))

/// Get the surrounding (directly adjacent) cells
fn get_surrounding_cells(pos: #(Int, Int)) {
  let #(y, x) = pos

  [
    #(y, x - 1),
    #(y, x + 1),
    #(y - 1, x),
    #(y + 1, x)
  ]
}

/// Get the circumference for the given region.
/// Note that this assumes contiguousness.
/// Each cell adds a value based on the number of neighbors it has
/// that are in the region. 4 neighbors -> 0 circumference, 3 neighbors -> 1, etc.
fn get_circumference(
  grid: grid.Grid(String),
  region: List(#(Int, Int))
) {
  region
  |> list.fold(0, fn (sum, cell) {
    let assert Ok(cell_value) = dict.get(grid, cell)

    let neighbors_in_region = get_surrounding_cells(cell)
    |> list.map(fn (neighbor) { dict.get(grid, neighbor) })
    |> list.filter(fn (candidate) {
      case candidate {
        Ok(neighbor_value) if neighbor_value == cell_value -> True
        _ -> False
      }
    })
    |> list.length

    sum + { 4 - neighbors_in_region }
  })
}

/// Get neighboring cells with the same value
fn get_same_neighbors(grid: grid.Grid(String), cell: #(Int, Int)) {
  let assert Ok(cell_value) = dict.get(grid, cell)

  list.fold(get_surrounding_cells(cell), [], fn (acc, curr) {
    case dict.get(grid, curr) {
      Ok(value) if value == cell_value -> [curr, ..acc]
      _ -> acc
    }
  })
}

fn convert_to_checked_regions(regions: List(List(#(Int, Int)))) {
  list.fold(regions, dict.new(), fn (row_acc, row_curr) {
    list.fold(row_curr, row_acc, fn (col_acc, cell) {
      dict.insert(col_acc, cell, True)
    })
  })
}

fn get_region(
  grid: grid.Grid(String),
  candidate_pos: #(Int, Int),
  current_value: String,
  checked_cells: grid.Grid(Bool)
  // current_region: List(#(Int, Int)),
  // regions: List(List(#(Int, Int))),
  // visited_seeds: List(#(Int, Int))
) -> #(List(#(Int, Int)), grid.Grid(Bool)) {
  let valid_neighbors = get_same_neighbors(grid, candidate_pos)
  |> list.filter(fn (neighbor) {
    case dict.get(checked_cells, neighbor) {
      Ok(True) -> False
      _ -> True
    }
  })

  // io.debug(current_value)
  // io.debug("-------")
  // io.debug(candidate_pos)
  // io.debug(valid_neighbors)
  // io.debug("+++++++")

  // let new_checked_regions = list.fold(valid_neighbors, checked_regions, fn (acc, curr) {
  //   dict.insert(acc, curr, True)
  // })
  // |> dict.insert(candidate_pos, True)

  list.fold(valid_neighbors, #([candidate_pos], dict.insert(checked_cells, candidate_pos, True)), fn (acc, curr) {
    let #(acc_region, acc_checked_cells) = acc
    let new_checked_cells = dict.insert(acc_checked_cells, curr, True)
    let #(region, checked_regions) = get_region(grid, curr, current_value, new_checked_cells)
    #(
      list.unique(list.append(region, acc_region)),
      checked_regions
    )
  })
}

fn has_checked(regions: List(List(#(Int, Int))), candidate: #(Int, Int)) {
  regions
  |> list.any(fn (region) {
    list.any(region, fn (cell) { cell == candidate })
  })
}

pub fn main() {
  let grid = "./data/day_12.txt"
  |> utils.read_lines
  |> list.map(fn (row) { string.split(row, "") })
  |> grid.from_lists

  // let test_key = #(90, 79)
  // let assert Ok(test_value) = dict.get(grid, test_key)

  // grid
  // |> get_region(test_key, test_value, dict.new())
  // |> io.debug

  dict.fold(grid, [], fn (acc, key, value) {
    case has_checked(acc, key) {
      True -> acc
      False -> [get_region(grid, key, value, dict.new()).0, ..acc]
    }
  })
  |> list.map(fn (region) {
    get_circumference(grid, region) * list.length(region)
  })
  |> utils.sum
  |> io.debug
}
