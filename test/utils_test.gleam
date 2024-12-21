import gleeunit
import gleeunit/should
import utils

pub fn main() {
  gleeunit.main()
}

pub fn split_by_empty_row_test() {
  let input_list = ["a", "", "b", "c", "", "d"]

  let expected = [["a"], ["b", "c"], ["d"]]

  input_list
  |> utils.split_by_empty_row
  |> should.equal(expected)
}
