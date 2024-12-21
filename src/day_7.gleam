//// The central idea of this is to represent each possible combination of n operators with
//// an n-ary number.
////
//// So for part 1, which only uses two operators, we can use a binary number:
////
//// `1011` would represent the combination of `a + b * c + d + e`
////
//// Part 2 uses three operators, so we can use a ternary number:
////
//// `102` would represent the combination of `a + b * c <concat> d`
////
//// This way, we can range over all possible combinations of operators and apply them to the input.
////
//// Enumerating all possibilities isn't the most efficient way, but the `get_operator_combination`
//// function is rather elegant.

import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import utils

/// Encode n possible operators in m possible places
pub fn get_operator_combinations(input: List(Int), num_operators: Int) {
  let list_length = list.length(input) - 1
  let assert Ok(binary_range_float) =
    int.power(num_operators, int.to_float(list_length))
  let binary_range = float.truncate(binary_range_float) - 1

  list.range(0, binary_range)
  |> list.map(fn(n) {
    int.to_base_string(n, num_operators)
    |> result.unwrap("")
    |> string.pad_start(list_length, "0")
    |> string.split("")
    |> list.map(fn(char) {
      case char {
        "0" -> fn(a: Int, b: Int) { a + b }
        "1" -> fn(a: Int, b: Int) { a * b }
        "2" -> fn(a: Int, b: Int) {
          let a_string = int.to_string(a)
          let b_string = int.to_string(b)

          let assert Ok(result) = int.parse(a_string <> b_string)

          result
        }
        _ -> fn(_a: Int, _b: Int) { 0 }
      }
    })
  })
}

pub fn parse_row(row: String) {
  let assert [result_raw, rest] = string.split(row, ":")

  let assert Ok(result) = int.parse(result_raw)
  let numbers =
    rest
    |> string.trim_start
    |> string.split(" ")
    |> list.map(fn(char) {
      let assert Ok(number) = int.parse(char)

      number
    })

  #(result, numbers)
}

pub fn part_1() {
  "./data/day_7.txt"
  |> utils.read_lines()
  |> list.map(parse_row)
  |> list.filter(fn(parsed_row) {
    let #(expected_result, numbers) = parsed_row

    numbers
    |> get_operator_combinations(2)
    |> list.any(fn(combination) {
      let result =
        numbers
        |> list.zip(list.prepend(combination, fn(_, b) { b }))
        |> list.fold(0, fn(result, pair_with_operator) {
          let #(n, operator) = pair_with_operator
          operator(result, n)
        })

      result == expected_result
    })
  })
  |> list.map(fn(row) {
    let #(result, _) = row
    result
  })
  |> utils.sum
  |> io.debug
}

pub fn part_2() {
  "./data/day_7.txt"
  |> utils.read_lines()
  |> list.map(parse_row)
  |> list.filter(fn(parsed_row) {
    let #(expected_result, numbers) = parsed_row

    numbers
    |> get_operator_combinations(3)
    |> list.any(fn(combination) {
      let result =
        numbers
        |> list.zip(list.prepend(combination, fn(_, b) { b }))
        |> list.fold(0, fn(result, pair_with_operator) {
          let #(n, operator) = pair_with_operator
          operator(result, n)
        })

      result == expected_result
    })
  })
  |> list.map(fn(row) {
    let #(result, _) = row
    result
  })
  |> utils.sum
  |> io.debug
}

pub fn main() {
  part_2()

  Nil
}
