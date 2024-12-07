import gleam/float
import gleam/io
import gleam/result
import gleam/list
import gleam/int
import gleam/string
import utils


// Having n possible operators in m possible places can be encoded as an n-ary number with m places
fn get_operator_combinations(input: List(Int), num_operators: Int) {
  let list_length = list.length(input) - 1
  let assert Ok(binary_range_float) = int.power(num_operators, int.to_float(list_length))
  let binary_range = float.truncate(binary_range_float) - 1

  list.range(0, binary_range)
  |> list.map(fn (n) {
    int.to_base_string(n, num_operators)
    |> result.unwrap("")
    |> string.pad_start(list_length, "0")
    |> string.split("")
    |> list.map(fn (char) {
      case char {
        "0" -> fn (a: Int, b: Int) { a + b }
        "1" -> fn (a: Int, b: Int) { a * b }
        "2" -> fn (a: Int, b: Int) {
          let a_string = int.to_string(a)
          let b_string = int.to_string(b)

          let assert Ok(result) = int.parse(a_string <> b_string)

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
    |> get_operator_combinations(2)
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
    |> get_operator_combinations(3)
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
