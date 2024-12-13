////
//// [Advent of Code day 13](https://adventofcode.com/2024/day/13)
////
//// ## Parsing
//// First, we need to split the lines into blocks
//// describing each claw machine.
//// We can do this by splitting the input by the empty line.
//// Next, we need to parse each block. This is easily done by
//// 1. assuming that each block has three lines
//// 2. some regex.
////
//// ## Checking for solvability
//// To decide whether a claw machine can be solved, we need to find out
//// whether the vector of the prize can be formed by
//// any linear combination of the vectors described by button A and B
//// (And whether the sum of the linear factors is less than 100).
////
//// ## Finding the optimal path
//// Finally, to find the optimal path (linear combination), we can take
//// the list of all possible combinations and sort it by assigning scores
//// to each linear combination:
//// - Three times the linear factor of A + the linear factor of B
//// The linear combination with the lowest score is our optimal path.
////
//// $\exp$

import gleam/int
import utils
import gleam/regexp
import gleam/result
import gleam/list
import gleam/io
import gleam/option

/// X,Y Position
pub type Position {
  Position(x: Int, y: Int)
}

/// A claw machine consist of three tuples of integers:
/// - The x and y movement of button A
/// - The x and y movement of button B
/// - The x and y coordinates of the prize
pub type ClawMachine {
  ClawMachine(a: Position, b: Position, prize: Position)
}

/// Parse two strings into a positon
fn strings_to_position(raw_x: String, raw_y: String) -> Result(Position, Nil) {
  use x <- result.try(int.parse(raw_x))
  use y <- result.try(int.parse(raw_y))

  Ok(Position(x, y))
}

/// Parse a line containing button information
fn parse_button_line(line: String) -> Result(Position, Nil) {
  let assert Ok(button_regex) = regexp.from_string("Button (A|B): X\\+([0-9]+), Y\\+([0-9]+)")

  case regexp.scan(button_regex, line) {
    [match] -> case match.submatches {
      [_, option.Some(raw_x), option.Some(raw_y)] -> strings_to_position(raw_x, raw_y)
      _ -> Error(Nil)
    }
    _ -> Error(Nil)
  }
}

// Parse a line containing Prize information
fn parse_prize_line(line: String) -> Result(Position, Nil) {
  let assert Ok(prize_regex) = regexp.from_string("Prize: X=([0-9]+), Y=([0-9]+)")

  case regexp.scan(prize_regex, line) {
    [match] -> case match.submatches {
      [option.Some(raw_x), option.Some(raw_y)] -> strings_to_position(raw_x, raw_y)
      _ -> Error(Nil)
    }
    _ -> Error(Nil)
  }
}

/// Parse a block containing three lines ('Button A:', 'Button B:' & Prize:)
fn parse_block(block: List(String)) -> Result(ClawMachine, Nil) {
  case block {
    [line_a, line_b, line_prize] -> case parse_button_line(line_a), parse_button_line(line_b), parse_prize_line(line_prize) {
      Ok(a), Ok(b), Ok(prize) -> Ok(ClawMachine(a, b, prize))
      _, _, _ -> Error(Nil)
    }
    _ -> Error(Nil)
  }
}

/// Parse lines of text into a list of ClawMachines
fn parse_input(lines: List(String), result: List(Result(ClawMachine, Nil))) -> List(Result(ClawMachine, Nil)) {
  case lines {
    [a, b, prize, "", ..rest] -> parse_input(rest, [parse_block([a, b, prize]), ..result])
    [a, b, prize] -> [parse_block([a, b, prize]), ..result]
    _ -> result
  }
}

/// Given a claw machine, return all button combinations that lead to the prize.
/// Returns an empty list if no combinations win.
fn get_possible_combinations(machine: ClawMachine) -> List(#(Int, Int)) {
  let assert Ok(a_max_count_x) = int.floor_divide(machine.prize.x, machine.a.x)
  let assert Ok(a_max_count_y) = int.floor_divide(machine.prize.y, machine.a.y)

  let assert Ok(b_max_count_x) = int.floor_divide(machine.prize.x, machine.b.x)
  let assert Ok(b_max_count_y) = int.floor_divide(machine.prize.y, machine.b.y)


  let max_count_a = int.min(a_max_count_x, a_max_count_y)
  let max_count_b = int.min(b_max_count_x, b_max_count_y)

  list.range(0, max_count_a)
  |> list.map(fn (a) {
    list.range(0, max_count_b)
    |> list.map(fn (b) { #(a, b) })
  })
  |> list.flatten
  |> list.filter(fn (factors) {
    let #(factor_a, factor_b) = factors

    let pos = Position(
      x: { factor_a * machine.a.x } + { factor_b * machine.b.x },
      y: { factor_a * machine.a.y } + { factor_b * machine.b.y }
    )
    pos == machine.prize
  })
}

/// Score a combination of a and b button presses
fn score_combination(combination: #(Int, Int)) {
  let #(a, b) = combination
  { a * 3 } + b
}

/// Sort a list of combinations by scoring them according to the value of button A and B (3 & 1)
fn sort_combinations(combinations: List(#(Int, Int))) {
  list.sort(combinations, fn (first, second) {
    int.compare(score_combination(first), score_combination(second))
  })
}

pub fn main() {
  "./data/day_13.txt"
  |> utils.read_lines
  |> parse_input([])
  |> list.map(fn (machine_result) {
    let assert Ok(machine) = machine_result

    let combinations = get_possible_combinations(machine)
    |> sort_combinations

    case combinations {
      [first, .._] -> score_combination(first)
      _ -> 0
    }
  })
  |> utils.sum
  |> io.debug
}
