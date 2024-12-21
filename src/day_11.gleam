import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import utils

pub fn get_num_digits(input: Int) -> Int {
  let assert Ok(digits) = int.digits(input, 10)
  list.length(digits)
}

/// Given a number 1234, return two numbers 12, 34. Assumes the number
/// has an even amount of digits.
pub fn split_digits(input: Int) -> List(Int) {
  let assert Ok(digits) = int.digits(input, 10)
  let assert Ok(half_index) = int.floor_divide(list.length(digits), 2)

  let #(first_half_digits, second_half_digits) = list.split(digits, half_index)

  let assert Ok(first_half) = int.undigits(first_half_digits, 10)
  let assert Ok(second_half) = int.undigits(second_half_digits, 10)

  [first_half, second_half]
}

pub fn update_and_return(
  dict: dict.Dict(k, v),
  key: k,
  value: v,
) -> #(v, dict.Dict(k, v)) {
  #(value, dict.insert(dict, key, value))
}

pub fn mutate_element(input: Int) -> List(Int) {
  case input, get_num_digits(input) {
    0, _ -> [1]
    n, num_digits if num_digits % 2 == 0 -> split_digits(n)
    n, _ -> [n * 2024]
  }
}

pub fn process_element(
  input: Int,
  times: Int,
  memoized: dict.Dict(#(Int, Int), List(Int)),
) -> #(List(Int), dict.Dict(#(Int, Int), List(Int))) {
  case dict.get(memoized, #(input, times)), times {
    _, 0 -> update_and_return(memoized, #(input, times), [input])
    Ok(result), _ -> #(result, memoized)
    _, _ ->
      input
      |> mutate_element
      |> list.fold(#([], memoized), fn(acc, curr) {
        let #(elements, memoized) = acc
        let #(new_elements, new_memoized) =
          process_element(curr, times - 1, memoized)
        // #(list.append(new_elements, elements), new_memoized)
        #(
          list.append(new_elements, elements),
          dict.insert(new_memoized, #(input, times), new_elements),
        )
        // #(list.append(processed_element, acc), dict.insert(#(input, times), process_element))
      })
  }
}

pub fn mutate_list(
  input: List(Int),
  times: Int,
  memoized: dict.Dict(#(Int, Int), List(Int)),
) -> List(Int) {
  let #(mutated_list, _) =
    input
    |> list.fold(#([], memoized), fn(acc, curr) {
      let #(acc_list, acc_memoized) = acc
      let #(new_elements, new_memoized) =
        process_element(curr, times, acc_memoized)

      #(list.append(new_elements, acc_list), new_memoized)
    })

  mutated_list
}

pub fn add_to_with_default(
  input: dict.Dict(Int, Int),
  key: Int,
  value: Int,
) -> dict.Dict(Int, Int) {
  let current_value = case dict.get(input, key) {
    Ok(value) -> value
    _ -> 0
  }
  dict.insert(input, key, current_value + value)
}

pub fn process_line_out_of_order(
  input: dict.Dict(Int, Int),
  count: Int,
) -> dict.Dict(Int, Int) {
  case count {
    0 -> input
    _ ->
      process_line_out_of_order(
        dict.fold(input, dict.new(), fn(acc, key, value) {
          mutate_element(key)
          |> list.fold(acc, fn(acc, curr) {
            add_to_with_default(acc, curr, value)
          })
        }),
        count - 1,
      )
  }
}

pub fn list_to_dict(input: List(Int)) -> dict.Dict(Int, Int) {
  input
  |> list.fold(dict.new(), fn(acc, curr) { add_to_with_default(acc, curr, 1) })
}

pub fn count_entries(input: dict.Dict(Int, Int)) -> Int {
  dict.fold(input, 0, fn(acc, _, value) { acc + value })
}

pub fn main() {
  "./data/day_11.txt"
  |> utils.read_lines
  |> list.first
  |> result.unwrap("")
  |> string.split(" ")
  |> list.map(fn(el) {
    let assert Ok(n) = int.parse(el)
    n
  })
  |> list_to_dict
  |> io.debug
  |> process_line_out_of_order(75)
  |> count_entries
  |> io.debug

  Nil
}
