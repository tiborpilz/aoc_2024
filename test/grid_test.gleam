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
