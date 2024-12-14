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
//// k * ax + l * bx = x
//// k * ay + l * by = y
//// ( ax bx ) times (k) = (x)
//// ( ay by )       (l)   (y)
//// x * by -y * bx = k * ax*by - ay*by)
//// y * ax - x * ay = l * (ax*by - ay*bx)

import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import utils

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

fn add_to_position(position: Position, value: Int) -> Position {
  Position(x: position.x + value, y: position.y + value)
}

/// Parse a line containing button information
fn parse_button(line: String) -> Result(Position, Nil) {
  let assert Ok(button_regex) =
    regexp.from_string("Button (A|B): X\\+([0-9]+), Y\\+([0-9]+)")

  case regexp.scan(button_regex, line) {
    [match] ->
      case match.submatches {
        [_, option.Some(raw_x), option.Some(raw_y)] ->
          strings_to_position(raw_x, raw_y)
        _ -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

/// Parse a line containing Prize information
fn parse_prize(line: String, prize_offset: Int) -> Result(Position, Nil) {
  let assert Ok(prize_regex) =
    regexp.from_string("Prize: X=([0-9]+), Y=([0-9]+)")

  case regexp.scan(prize_regex, line) {
    [match] ->
      case match.submatches {
        [option.Some(raw_x), option.Some(raw_y)] ->
          result.try(strings_to_position(raw_x, raw_y), fn(pos) {
            Ok(add_to_position(pos, prize_offset))
          })
        _ -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

/// Parse a block containing three lines ('Button A:', 'Button B:' & Prize:)
fn parse_block(block: List(String), prize_offset: Int) -> Result(ClawMachine, Nil) {
  case block {
    [line_a, line_b, line_prize] ->
      case parse_button(line_a), parse_button(line_b), parse_prize(line_prize, prize_offset) {
        Ok(a), Ok(b), Ok(prize) -> Ok(ClawMachine(a, b, prize))
        _, _, _ -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

/// Parse lines of text into a list of ClawMachines
fn parse_input(
  lines: List(String),
  result: List(Result(ClawMachine, Nil)),
  prize_offset: Int,
) -> List(Result(ClawMachine, Nil)) {
  case lines {
    [a, b, prize, "", ..rest] ->
      parse_input(rest, [parse_block([a, b, prize], prize_offset), ..result], prize_offset)
    [a, b, prize] -> [parse_block([a, b, prize], prize_offset), ..result]
    _ -> result
  }
}

/// Solve the linear equation given by `a_count * (a.x, a.y) + b_count * (b.x, b.y) = (prize.x, prize.y)`
/// After solving, double check whether the solutions fit or wheter there's a rounding error.
/// Then, return the score of the solution as speficied. (`3 * a_count + b_count`)
pub fn solve_machine(machine: ClawMachine) {
  let ClawMachine(a, b, p) = machine

  let a_count =
    { { b.y * p.x } - { b.x * p.y } } / { { a.x * b.y } - { a.y * b.x } }
  let b_count =
    { { a.y * p.x } - { a.x * p.y } } / { { a.y * b.x } - { a.x * b.y } }

  let x_matches = { a_count * a.x } + { b_count * b.x } == p.x
  let y_matches = { a_count * a.y } + { b_count * b.y } == p.y

  case x_matches && y_matches {
    True -> { 3 * a_count } + b_count
    False -> 0
  }
}

pub fn get_data(prize_offset: Int) {
  "./data/day_13.txt"
  |> utils.read_lines
  |> parse_input([], prize_offset)
  |> list.map(fn(machine_result) {
    let assert Ok(machine) = machine_result
    machine
  })
}

pub fn part_1() {
  get_data(0)
  |> list.map(solve_machine)
  |> utils.sum
}

pub fn part_2() {
  get_data(10000000000000)
  |> list.map(solve_machine)
  |> utils.sum
}

pub fn main() {
  let result_1 = part_1()
  let result_2 = part_2()

  io.println("Part 1: " <> int.to_string(result_1))
  io.println("Part 2: " <> int.to_string(result_2))
}
