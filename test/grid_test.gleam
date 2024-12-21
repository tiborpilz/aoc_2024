import gleam/dict
import gleeunit
import gleeunit/should
import grid

pub fn main() {
  gleeunit.main()
}

pub fn from_lists_test() {
  let lists = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  let expected =
    dict.from_list([
      #(#(0, 0), 1),
      #(#(0, 1), 2),
      #(#(0, 2), 3),
      #(#(1, 0), 4),
      #(#(1, 1), 5),
      #(#(1, 2), 6),
      #(#(2, 0), 7),
      #(#(2, 1), 8),
      #(#(2, 2), 9),
    ])

  lists
  |> grid.from_lists
  |> should.equal(expected)
}

pub fn to_row_list_indexed_test() {
  let example_grid = grid.from_lists([[1, 2, 3], [4, 5, 6], [7, 8, 9]])

  let expected = [
    [#(#(0, 0), 1), #(#(0, 1), 2), #(#(0, 2), 3)],
    [#(#(1, 0), 4), #(#(1, 1), 5), #(#(1, 2), 6)],
    [#(#(2, 0), 7), #(#(2, 1), 8), #(#(2, 2), 9)],
  ]

  example_grid
  |> grid.to_row_list_indexed
  |> should.equal(expected)
}

pub fn to_col_list_indexed_test() {
  let example_grid = grid.from_lists([[1, 2, 3], [4, 5, 6], [7, 8, 9]])

  let expected = [
    [#(#(0, 0), 1), #(#(1, 0), 4), #(#(2, 0), 7)],
    [#(#(0, 1), 2), #(#(1, 1), 5), #(#(2, 1), 8)],
    [#(#(0, 2), 3), #(#(1, 2), 6), #(#(2, 2), 9)],
  ]

  example_grid
  |> grid.to_col_list_indexed
  |> should.equal(expected)
}
