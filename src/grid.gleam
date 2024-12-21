//// The grid module provides a two-dimensional data structure.
//// It is implemented as a dictionary with the keys being the
//// a tuple of i,j indices of the elements.

import gleam/dict
import gleam/io
import gleam/list
import gleam/result
import utils

/// A position is given as a tuple of coordinates: (y, x)
pub type Position =
  #(Int, Int)

/// A grid is a dictionary with the keys being the a tuple of y,x coordinates of the elements.
pub type Grid(a) =
  dict.Dict(Position, a)

/// A single element value together with its position.
pub type Element(a) =
  #(Position, a)

///
/// Takes a m⨯n list of lists and returns a Grid - which is a dictionary with the keys being the
/// a tuple of i,j indices of the elements.

pub fn from_lists(lists: List(List(a))) -> dict.Dict(Position, a) {
  lists
  |> list.index_fold(dict.new(), fn(acc_row, curr_row, index_row) {
    // go over all rows
    curr_row
    |> list.index_fold(acc_row, fn(acc_col, curr_col, index_col) {
      acc_col |> dict.insert(#(index_row, index_col), curr_col)
    })
  })
}

///
/// Updates a given entry (specified by a tuple of indices) only if it already
/// exists.
pub fn update_if_exists(grid: Grid(a), indices: Position, value: a) {
  case dict.has_key(grid, indices) {
    False -> grid
    True -> grid |> dict.insert(indices, value)
  }
}

///
/// Get value specified by indices
///
pub fn get(grid: Grid(a), indices: Position) -> Result(a, Nil) {
  dict.get(grid, indices)
}

///
/// Gets the height and width of a given Grid as a tuple #(height, width)
pub fn size(grid: Grid(a)) -> Position {
  grid
  |> dict.fold(#(0, 0), fn(acc, indices, _) {
    let #(height, width) = acc
    let #(row_index, col_index) = indices
    #(
      case row_index + 1 > height {
        True -> row_index + 1
        False -> height
      },
      case col_index + 1 > width {
        True -> col_index + 1
        False -> width
      },
    )
  })
}

///
/// Transforms a given position to string (for debug purposes)
pub fn position_to_string(position: Position) -> String {
  let #(y, x) = position
  "y: " <> utils.to_string(y) <> ", x: " <> utils.to_string(x)
}

///
/// Gets the row of a given index as a list
pub fn get_row(grid: Grid(a), index: Int) -> Result(List(a), Nil) {
  let #(_, width) = size(grid)

  list.range(0, width - 1)
  |> list.map(fn(col_index) { dict.get(grid, #(index, col_index)) })
  |> result.all
}

///
/// Gets the column of a given index as a list
pub fn get_column(grid: Grid(a), index: Int) -> Result(List(a), Nil) {
  let #(height, _) = size(grid)

  list.range(0, height - 1)
  |> list.map(fn(row_index) { dict.get(grid, #(row_index, index)) })
  |> result.all
}

///
/// Transforms a grid to a list of lists (row-wise)
pub fn to_lists(grid: Grid(a)) -> List(List(a)) {
  let #(height, _) = size(grid)

  list.range(0, height - 1)
  |> list.map(fn(row_index) {
    let assert Ok(row) = get_row(grid, row_index)
    row
  })
}

///
/// Transforms a grid to a list of lists of tuples of indices and values (row-wise)
pub fn to_row_list_indexed(grid: Grid(a)) -> List(List(#(Position, a))) {
  let #(height, width) = size(grid)

  list.range(0, height - 1)
  |> list.map(fn(row_index) {
    list.range(0, width - 1)
    |> list.map(fn(col_index) {
      let assert Ok(element) = dict.get(grid, #(row_index, col_index))
      #(#(row_index, col_index), element)
    })
  })
}

///
/// Transforms a grid to a list of list of tuples of indices and values (column-wise)
pub fn to_col_list_indexed(grid: Grid(a)) -> List(List(#(Position, a))) {
  let #(height, width) = size(grid)

  list.range(0, width - 1)
  |> list.map(fn(col_index) {
    list.range(0, height - 1)
    |> list.map(fn(row_index) {
      let assert Ok(element) = dict.get(grid, #(row_index, col_index))
      #(#(row_index, col_index), element)
    })
  })
}

///
/// Gets the column of a given index as a list of tuples of indices value
pub fn get_indexed_column(
  grid: Grid(a),
  index: Int,
) -> Result(List(#(Position, a)), Nil) {
  let #(height, _) = size(grid)

  list.range(0, height - 1)
  |> list.map(fn(row_index) {
    use value <- result.try(dict.get(grid, #(row_index, index)))
    Ok(#(#(row_index, index), value))
  })
  |> result.all
}

// ///
// /// Gets a list of all rows as a list of tuples of indices and values
// pub fn get_indexed_rows(grid: Grid(a)) -> List(List(#(Position, a))) {
//   grid
//   |> to_lists
// }

///
/// Gets the row of a given index as a list of tuples of indices and values
pub fn get_indexed_row(
  grid: Grid(a),
  index: Int,
) -> Result(List(#(Position, a)), Nil) {
  let #(_, width) = size(grid)

  list.range(0, width - 1)
  |> list.map(fn(col_index) {
    use value <- result.try(dict.get(grid, #(index, col_index)))
    Ok(#(#(index, col_index), value))
  })
  |> result.all
}

///
/// Given a Grid of Strings, pretty prints it
pub fn pretty_print(grid: Grid(String)) {
  io.debug("---------------------------------")
  grid
  |> to_lists
  |> list.map(fn(row) { io.debug(utils.join(row)) })
  io.debug("---------------------------------")

  grid
}
