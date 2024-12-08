import gleam/int
import gleam/list
import gleam/dict
import gleam/io

pub type Grid(a) = dict.Dict(#(Int, Int), a)

///
/// Takes a m⨯n list of lists and returns a Grid - which is a dictionary with the keys being the
/// a tuple of i,j indices of the elements.
pub fn from_lists(lists: List(List(a))) -> dict.Dict(#(Int, Int), a) {
  lists
  |> list.index_fold(dict.new(), fn (acc_row, curr_row, index_row) { // go over all rows
    curr_row
    |> list.index_fold(acc_row, fn (acc_col, curr_col, index_col) {
      acc_col |> dict.insert(#(index_row, index_col), curr_col)
    })
  })
}

///
/// Updates a given entry (specified by a tuple of indices) only if it already
/// exists.
pub fn update_if_exists(grid: Grid(a), indices: #(Int,Int), value: a) {
  case dict.has_key(grid, indices) {
    False -> grid
    True -> grid |> dict.insert(indices, value)
  }
}

///
/// Gets the height and width of a given Grid as a tuple #(height, width)
pub fn size(grid: Grid(a)) -> #(Int, Int) {
  grid |> dict.fold(#(0,0), fn (acc, indices, _) {
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
      }
    )
  })
}

///
/// Gets the row of a given index as a list
pub fn get_row(grid: Grid(a), index: Int) -> List(a) {
  grid
  |> dict.filter(fn (key, _) {
    let #(row_index, _) = key
    row_index == index
  })
  |> dict.to_list
  |> list.sort(fn (pair_a, pair_b) {
    let #(indices_a, _) = pair_a
    let #(indices_b, _) = pair_b
    let #(_, col_index_a) = indices_a
    let #(_, col_index_b) = indices_b

    int.compare(col_index_a, col_index_b)
  })
  |> list.map(fn (pair) {
    let #(_, value) = pair
    value
  })
}

///
/// Gets the column of a given index as a list
pub fn get_column(grid: Grid(a), index: Int) -> List(a) {
  grid
  |> dict.filter(fn (key, _) {
    let #(_, column_index) = key
    column_index == index
  })
  |> dict.to_list
  |> list.sort(fn (pair_a, pair_b) {
    let #(indices_a, _) = pair_a
    let #(indices_b, _) = pair_b
    let #(row_index_a, _) = indices_a
    let #(row_index_b, _) = indices_b

    int.compare(row_index_a, row_index_b)
  })
  |> list.map(fn (pair) {
    let #(_, value) = pair
    value
  })
}

pub fn debug_column() {
  [
    [1,2,3],
    [4,5,6],
    [7,8,9]
  ] |> from_lists |> size |> io.debug
}

pub fn main() {
  debug_column()
}
