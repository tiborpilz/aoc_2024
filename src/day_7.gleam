import gleam/float
import gleam/io
import gleam/result
import gleam/list
import gleam/int
import gleam/string
import utils

type Operation {
  Add
  Mult
  Unknown
}

fn add (a: Int, b: Int) {
  a + b
}

// Having two possible operators in two possible places
// can be encoded as a 2-bit binary number.

fn get_operator_combinations_binary(input: List(Int)) {
  let list_length = list.length(input) - 1
  let assert Ok(binary_range_float) = int.power(2, int.to_float(list_length))
  let binary_range = float.truncate(binary_range_float) - 1

  list.range(0, binary_range)
  |> list.map(fn (n) {
    int.to_base_string(n, 2)
    |> result.unwrap("")
    |> string.pad_start(list_length, "0")
    |> string.split("")
    |> list.map(fn (char) {
      case char {
        "0" -> fn (a: Int, b: Int) { a + b }
        "1" -> fn (a: Int, b: Int) { a * b }
        _ -> fn (_a: Int, _b: Int) { 0 }
      }
    })
  })
}

// for part two, we can do the same trick though with ternary numbers
fn get_operator_combinations_ternary(input: List(Int)) {
  let list_length = list.length(input) - 1
  let assert Ok(binary_range_float) = int.power(3, int.to_float(list_length))
  let binary_range = float.truncate(binary_range_float) - 1

  list.range(0, binary_range)
  |> list.map(fn (n) {
    int.to_base_string(n, 3)
    |> result.unwrap("")
    |> string.pad_start(list_length, "0")
    |> string.split("")
    |> list.map(fn (char) {
      case char {
        "0" -> fn (a: Int, b: Int) { a + b }
        "1" -> fn (a: Int, b: Int) { a * b }
        "2" -> fn (a: Int, b: Int) {
          let assert Ok(a_digits) = int.digits(a, 10)
          let assert Ok(b_digits) = int.digits(b, 10)

          let assert Ok(result) = int.undigits(list.append(a_digits, b_digits), 10)

          result
        }
        _ -> fn (_a: Int, _b: Int) { 0 }
      }
    })
  })
}

fn parse_row(row: String) {
  let assert [result_raw, rest] = string.split(row, ":")

  let assert Ok(result) = int.parse(result_raw)
  let numbers = rest
  |> string.trim_start
  |> string.split(" ")
  |> list.map(fn (char) {
    let assert Ok(number) = int.parse(char)

    number
  })

  #(result, numbers)
}

pub fn part_1() {
  "./data/day_7.txt"
  |> utils.read_lines()
  |> list.map(parse_row)
  |> list.filter(fn (parsed_row) {
    let #(expected_result, numbers) = parsed_row

    numbers
    |> get_operator_combinations_binary
    |> list.any(fn (combination) {
      let result = numbers
      |> list.zip(list.prepend(combination, fn (_, b) { b }))
      |> list.fold(0, fn (result, pair_with_operator) {
        let #(n, operator) = pair_with_operator
        operator(result, n)
      })

      result == expected_result
    })
  })
  |> list.map(fn (row) {
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
  |> list.filter(fn (parsed_row) {
    let #(expected_result, numbers) = parsed_row

    numbers
    |> get_operator_combinations_ternary
    |> list.any(fn (combination) {
      let result = numbers
      |> list.zip(list.prepend(combination, fn (_, b) { b }))
      |> list.fold(0, fn (result, pair_with_operator) {
        let #(n, operator) = pair_with_operator
        operator(result, n)
      })

      result == expected_result
    })
  })
  |> list.map(fn (row) {
    let #(result, _) = row
    result
  })
  |> utils.sum
  |> io.debug
}

pub fn main() {
  part_2()
}
