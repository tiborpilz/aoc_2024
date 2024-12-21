import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import grid
import utils

/// Get the adjacent cells
///
/// oAo
/// AXA
/// oAo
///
/// For the cell "X" in the middle, the adjacent cells are the ones that can be
/// reached by moving one step in any vertical or horizontal direction.
/// The 4 cross-shaped cells "A" are the adjacent cells.
pub fn get_adjacent_cells(pos: #(Int, Int)) {
  let #(y, x) = pos

  [#(y - 1, x), #(y, x + 1), #(y + 1, x), #(y, x - 1)]
}

/// Get the surrounding cells (both direct and diagonal)
///
/// oAo
/// AXA
/// oAo
///
/// here, the surrounding cells for "X" in the middle are all 8 cells around it.
/// ["o", "A", "o", "A", "A", "A", "o", "A"]
pub fn get_surrounding_cells(pos: #(Int, Int)) {
  let #(y, x) = pos

  list.range(-1, 1)
  |> list.map(fn(y_offset) {
    list.range(-1, 1)
    |> list.map(fn(x_offset) { #(y + y_offset, x + x_offset) })
  })
  |> list.flatten
  |> list.filter(fn(cell) { cell != #(0, 0) })
}

/// Get adjacent cells with the same value
pub fn get_same_adjacents(grid: grid.Grid(String), cell: #(Int, Int)) {
  let assert Ok(cell_value) = dict.get(grid, cell)

  list.fold(get_adjacent_cells(cell), [], fn(acc, curr) {
    case dict.get(grid, curr) {
      Ok(value) if value == cell_value -> [curr, ..acc]
      _ -> acc
    }
  })
}

/// Get surrounding cells with the same value
pub fn get_same_surrounding(grid: grid.Grid(String), cell: #(Int, Int)) {
  let assert Ok(cell_value) = dict.get(grid, cell)

  list.fold(get_surrounding_cells(cell), [], fn(acc, curr) {
    case dict.get(grid, curr) {
      Ok(value) if value == cell_value -> [curr, ..acc]
      _ -> acc
    }
  })
}

/// Get the circumference for the given region.
/// Note that this assumes contiguousness.
/// Each cell adds a value based on the number of neighbors it has
/// that are in the region. 4 neighbors -> 0 circumference, 3 neighbors -> 1, etc.
pub fn get_circumference(grid: grid.Grid(String), region: List(#(Int, Int))) {
  region
  |> list.fold(0, fn(sum, cell) {
    let assert Ok(cell_value) = dict.get(grid, cell)

    let neighbors_in_region =
      get_surrounding_cells(cell)
      |> list.map(fn(neighbor) { dict.get(grid, neighbor) })
      |> list.filter(fn(candidate) {
        case candidate {
          Ok(neighbor_value) if neighbor_value == cell_value -> True
          _ -> False
        }
      })
      |> list.length

    sum + { 4 - neighbors_in_region }
  })
}

pub fn get_region(
  grid: grid.Grid(String),
  candidate_pos: #(Int, Int),
  current_value: String,
  checked_cells: grid.Grid(Bool),
) -> #(List(#(Int, Int)), grid.Grid(Bool)) {
  let valid_neighbors =
    get_same_adjacents(grid, candidate_pos)
    |> list.filter(fn(neighbor) {
      case dict.get(checked_cells, neighbor) {
        Ok(True) -> False
        _ -> True
      }
    })

  list.fold(
    valid_neighbors,
    #([candidate_pos], dict.insert(checked_cells, candidate_pos, True)),
    fn(acc, curr) {
      let #(acc_region, acc_checked_cells) = acc
      let new_checked_cells = dict.insert(acc_checked_cells, curr, True)
      let #(region, checked_regions) =
        get_region(grid, curr, current_value, new_checked_cells)
      #(list.unique(list.append(region, acc_region)), checked_regions)
    },
  )
}

pub fn find_adjacent_element(cell: #(Int, Int), from: List(#(Int, Int))) {
  io.debug(cell)
  io.debug(from)
  let element =
    list.find(from, fn(candidate_cell) {
      list.contains(get_surrounding_cells(cell), candidate_cell)
    })

  case element {
    Ok(v) -> Ok(#(v, list.filter(from, fn(e) { e != v })))
    Error(Nil) -> Error(Nil)
  }
}

pub fn sort_boundary(
  current_boundary: List(#(Int, Int)),
  rest_boundary: List(#(Int, Int)),
) {
  case current_boundary, rest_boundary {
    [], [] -> []
    [curr], [last] -> [last, curr]
    [curr, ..], rest ->
      case find_adjacent_element(curr, rest) {
        Ok(#(head, rest)) -> sort_boundary([head, ..current_boundary], rest)
        _ -> current_boundary
      }
    [], [head, ..rest] -> sort_boundary([head], rest)
  }
}

pub fn is_border_cell(grid: grid.Grid(String), cell: #(Int, Int)) {
  list.length(get_same_surrounding(grid, cell)) < 8
}

pub fn find_first_border_cell(
  grid: grid.Grid(String),
  region: List(#(Int, Int)),
) {
  let assert Ok(cell) =
    list.find(region, fn(cell) { is_border_cell(grid, cell) })
  cell
}

pub fn find_next_border_cell(grid: grid.Grid(String), cell: #(Int, Int)) {
  let assert Ok(cell) =
    get_same_adjacents(grid, cell)
    |> list.find(fn(cell) { is_border_cell(grid, cell) })
  cell
}

pub fn accumulate_border(
  grid: grid.Grid(String),
  current: #(Int, Int),
  border: List(#(Int, Int)),
  initial_cell: #(Int, Int),
) {
  case current == initial_cell {
    True -> border
    False ->
      accumulate_border(
        grid,
        find_next_border_cell(grid, current),
        [current, ..border],
        initial_cell,
      )
  }
}

pub fn has_checked(regions: List(List(#(Int, Int))), candidate: #(Int, Int)) {
  regions
  |> list.any(fn(region) { list.any(region, fn(cell) { cell == candidate }) })
}

pub fn main() {
  let grid =
    "./data/day_12_test.txt"
    |> utils.read_lines
    |> list.map(fn(row) { string.split(row, "") })
    |> grid.from_lists

  let test_key = #(0, 0)
  let assert Ok(test_value) = dict.get(grid, test_key)

  let #(region, _) =
    grid
    |> get_region(test_key, test_value, dict.new())
    |> io.debug

  let _regions =
    dict.fold(grid, [], fn(acc, key, value) {
      case has_checked(acc, key) {
        True -> acc
        False -> [get_region(grid, key, value, dict.new()).0, ..acc]
      }
    })

  let initial_border_cell = find_first_border_cell(grid, region)

  let border =
    accumulate_border(
      grid,
      find_next_border_cell(grid, initial_border_cell),
      [],
      initial_border_cell,
    )

  let #(new_grid, _) =
    list.fold(border, #(grid, 0), fn(acc, curr) {
      let counter = acc.1 + 1
      #(dict.insert(acc.0, curr, int.to_string(counter)), counter)
    })

  new_grid
  |> grid.to_lists
  |> list.map(fn(row) { io.debug(row) })

  Nil
}
