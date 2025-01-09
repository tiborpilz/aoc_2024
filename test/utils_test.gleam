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

pub fn int_power_test() {
  utils.int_power(2, 4) |> should.equal(16)
  utils.int_power(2, 3) |> should.equal(8)
  utils.int_power(3, 3) |> should.equal(27)
}
