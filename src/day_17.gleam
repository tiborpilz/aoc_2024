import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/yielder
import utils

pub type Registers {
  Registers(a: Int, b: Int, c: Int)
}

pub type Computer {
  Computer(
    a: Int,
    b: Int,
    c: Int,
    program: List(#(Int, Int)),
    output: List(Int),
    pointer: Int,
  )
}

pub fn get_raw_program(computer: Computer) -> List(Int) {
  computer.program
  |> list.map(fn(pair) {
    let #(opcode, operand) = pair
    [opcode, operand]
  })
  |> list.flatten
}

pub fn parse_input(input: List(String)) -> Computer {
  let empty_computer =
    Computer(a: 0, b: 0, c: 0, program: [], output: [], pointer: 0)

  input
  |> list.fold(empty_computer, fn(acc, curr) {
    case curr {
      "Register A: " <> a_raw -> {
        let assert Ok(a) = int.parse(a_raw)
        Computer(..acc, a: a)
      }
      "Register B: " <> b_raw -> {
        let assert Ok(b) = int.parse(b_raw)
        Computer(..acc, b: b)
      }
      "Register C: " <> c_raw -> {
        let assert Ok(c) = int.parse(c_raw)
        Computer(..acc, c: c)
      }
      "" -> acc
      "Program: " <> program_raw -> {
        let program =
          program_raw
          |> string.split(",")
          |> list.map(fn(el) {
            let assert Ok(value) = int.parse(el)
            value
          })
          |> list.sized_chunk(2)
          |> list.map(fn(pair) {
            let assert [opcode, operand] = pair
            #(opcode, operand)
          })

        Computer(..acc, program: program)
      }

      _ -> panic as "Unknown input!"
    }
  })
}

pub fn get_current_instruction(state: Computer) -> #(Int, Int, Int) {
  let assert Ok(current_instruction) = utils.at(state.program, state.pointer)
  let #(opcode, literal_operand) = current_instruction

  let operand = case literal_operand {
    n if n >= 0 && n <= 3 -> n
    // literal value
    4 -> state.a
    5 -> state.b
    6 -> state.c
    7 -> panic as "Reserved Combo Operand!"
    _ -> panic as "Unknown Combo Operand!"
  }

  #(opcode, operand, literal_operand)
}

pub fn debug_diff(new_state: Computer, old_state: Computer) -> Computer {
  // A local closure to display a list of Ints as a string, e.g. "[1, 2, 3]".
  let display_list = fn(xs: List(Int)) -> String {
    let items =
      xs
      |> list.map(int.to_string)
      |> string.join(", ")

    "[" <> items <> "]"
  }

  // Compare each field using a case expression. If they differ, return Some(...).
  // Otherwise return None. We'll filter out the None values below.
  let a_change = case old_state.a == new_state.a {
    True -> None
    False ->
      Some(
        "A: "
        <> int.to_string(old_state.a)
        <> " -> "
        <> int.to_string(new_state.a),
      )
  }

  let b_change = case old_state.b == new_state.b {
    True -> None
    False ->
      Some(
        "B: "
        <> int.to_string(old_state.b)
        <> " -> "
        <> int.to_string(new_state.b),
      )
  }

  let c_change = case old_state.c == new_state.c {
    True -> None
    False ->
      Some(
        "C: "
        <> int.to_string(old_state.c)
        <> " -> "
        <> int.to_string(new_state.c),
      )
  }

  let pointer_change = case old_state.pointer == new_state.pointer {
    True -> None
    False ->
      Some(
        "pointer: "
        <> int.to_string(old_state.pointer)
        <> " -> "
        <> int.to_string(new_state.pointer),
      )
  }

  let output_change = case old_state.output == new_state.output {
    True -> None
    False ->
      Some(
        "output: "
        <> display_list(old_state.output)
        <> " -> "
        <> display_list(new_state.output),
      )
  }

  // Now collect them in a list and filter out any None.
  let changes =
    [a_change, b_change, c_change, pointer_change, output_change]
    |> list.filter(fn(x) { x != None })

  let all_changes = option.all(changes)

  // Return a multi-line string if changes exist, or "No changes" otherwise.
  let formatted_changes = case all_changes {
    None -> "No changes"
    Some([]) -> "No changes"
    Some(changes) -> string.join(changes, ", ")
  }

  io.debug(formatted_changes)

  new_state
}

pub fn debug_instruction(result: Int, next_pointer: Int, target: String) {
  io.debug(
    "Result: "
    <> int.to_string(result)
    <> ", Next Pointer: "
    <> int.to_string(next_pointer)
    <> ", Target: "
    <> target,
  )
}

/// The `adv` instruction (opcode `0`) performs division.
/// 
/// The numerator is the value in the `A` register.
/// 
/// The denominator is found by raising `2` to the power of the instruction's combo operand. (So, an operand of `2` would divide `A` by `4` (`2^2`); an operand of `5` would divide `A` by `2^B`.)
/// 
/// The result of the division operation is truncated to an integer and then written to the A register.
///
pub fn adv(state: Computer) -> Computer {
  let #(_, operand, _) = get_current_instruction(state)
  let result = state.a / utils.int_power(2, operand)

  Computer(..state, a: result, pointer: state.pointer + 1)
}

/// The bxl instruction (opcode 1) calculates the bitwise XOR of register B and the instruction's literal operand, then stores the result in register B.
pub fn bxl(state: Computer) -> Computer {
  let #(_, _, literal_operand) = get_current_instruction(state)
  let result = int.bitwise_exclusive_or(state.b, literal_operand)

  Computer(..state, b: result, pointer: state.pointer + 1)
}

/// The bst instruction (opcode 2) calculates the value of its combo operand modulo 8 (thereby keeping only its lowest 3 bits), then writes that value to the B register.
pub fn bst(state: Computer) -> Computer {
  let #(_, operand, _) = get_current_instruction(state)
  let result = operand % 8

  Computer(..state, b: result, pointer: state.pointer + 1)
}

/// The jnz instruction (opcode 3) does nothing if the A register is 0. However, if the A register is not zero, it jumps by setting the instruction pointer to the value of its literal operand; if this instruction jumps, the instruction pointer is not increased by 2 after this instruction.
pub fn jnz(state: Computer) -> Computer {
  let #(_, operand, _) = get_current_instruction(state)
  case state.a {
    0 -> {
      Computer(..state, pointer: state.pointer + 1)
    }
    _ -> {
      Computer(..state, pointer: operand)
    }
  }
}

/// The bxc instruction (opcode 4) calculates the bitwise XOR of register B and register C, then stores the result in register B. (For legacy reasons, this instruction reads an operand but ignores it.)
pub fn bxc(state: Computer) -> Computer {
  let result = int.bitwise_exclusive_or(state.b, state.c)
  Computer(..state, b: result, pointer: state.pointer + 1)
}

/// The out instruction (opcode 5) calculates the value of its combo operand modulo 8, then outputs that value. (If a program outputs multiple values, they are separated by commas.)
pub fn out(state: Computer) -> Computer {
  let #(_, operand, _) = get_current_instruction(state)
  let result = operand % 8
  Computer(
    ..state,
    output: list.append(state.output, [result]),
    pointer: state.pointer + 1,
  )
}

/// The bdv instruction (opcode 6) works exactly like the adv instruction except that the result is stored in the B register. (The numerator is still read from the A register.)
pub fn bdv(state: Computer) -> Computer {
  let #(_, operand, _) = get_current_instruction(state)
  let denominator = utils.int_power(2, operand)
  let result = state.a / denominator
  Computer(..state, b: result, pointer: state.pointer + 1)
}

/// The cdv instruction (opcode 7) works exactly like the adv instruction except that the result is stored in the C register. (The numerator is still read from the A register.)
pub fn cdv(state: Computer) -> Computer {
  let #(_, operand, _) = get_current_instruction(state)
  let denominator = utils.int_power(2, operand)
  let result = state.a / denominator
  Computer(..state, c: result, pointer: state.pointer + 1)
}

pub fn execute_instruction(state: Computer) -> Computer {
  // debug_state(state)

  // let _ = erlang.get_line("Continue...")

  let #(opcode, _, _) = get_current_instruction(state)

  case opcode {
    0 -> adv(state)
    1 -> bxl(state)
    2 -> bst(state)
    3 -> jnz(state)
    4 -> bxc(state)
    5 -> out(state)
    6 -> bdv(state)
    7 -> cdv(state)
    _ -> panic as "Unknown opcode!"
  }
}

pub fn execute_program(state: Computer) -> Computer {
  case state.pointer, list.length(state.program) {
    pointer, program_length if pointer >= program_length -> state
    _, _ -> state |> execute_instruction |> execute_program
  }
}

/// Returns true if the first list is a prefix of the second list.
pub fn list_matches_up_to(list1: List(Int), list2: List(Int)) -> Bool {
  case list1, list2 {
    [], _ -> True
    _, [] -> False
    [x, ..xs], [y, ..ys] if x == y -> list_matches_up_to(xs, ys)
    _, _ -> False
  }
}

/// Returns true if either list is a prefix of the other list.
pub fn list_matches(list1: List(Int), list2: List(Int)) -> Bool {
  case list1, list2 {
    [], _ -> True
    _, [] -> True
    [x, ..xs], [y, ..ys] if x == y -> list_matches(xs, ys)
    _, _ -> False
  }
}

/// Returns true if the first list is a suffix of the second list.
pub fn list_matches_from_end(list1: List(Int), list2: List(Int)) -> Bool {
  list_matches_up_to(list1 |> list.reverse, list2 |> list.reverse)
}

pub fn evaluate_program(
  state: Computer,
  expected_output: List(Int),
) -> Result(Computer, Computer) {
  let has_reached_end = state.pointer >= list.length(state.program)

  // let next_state = state |> execute_program

  // case next_state.output == expected_output {
  //   True -> Ok(next_state)
  //   False -> Error(next_state)
  // }

  case has_reached_end, list_matches(state.output, expected_output) {
    True, True -> Ok(state)
    // True, True -> case state.output == expected_output {
    //   True -> Ok(state)
    //   False -> Error(state)
    // }
    True, False -> Error(state)
    False, _ ->
      state |> execute_instruction |> evaluate_program(expected_output)
    // False, False -> Error(state)
  }
}

pub fn debug_opcode(opcode: Int) -> String {
  case opcode {
    0 -> "adv"
    1 -> "bxl"
    2 -> "bst"
    3 -> "jnz"
    4 -> "bxc"
    5 -> "out"
    6 -> "bdv"
    7 -> "cdv"
    _ -> panic as "Unknown opcode!"
  }
}

/// Highlight current instruction
pub fn debug_program(state: Computer) -> String {
  state.program
  |> list.index_map(fn(instruction, index) {
    let #(opcode, operand) = instruction
    let opcode_str = debug_opcode(opcode)

    case index == state.pointer {
      True -> "(" <> opcode_str <> " " <> int.to_string(operand) <> ") <-"
      False -> opcode_str <> " " <> int.to_string(operand)
    }
  })
  |> utils.join_by("\n")
}

pub fn debug_state(state: Computer) -> Computer {
  let #(opcode, operand, literal_operand) = get_current_instruction(state)

  io.debug("--------------------")
  io.debug(
    "Opcode: "
    <> debug_opcode(opcode)
    <> " ("
    <> int.to_string(opcode)
    <> ")"
    <> ", Operand: "
    <> int.to_string(operand)
    <> ", Literal Operand: "
    <> int.to_string(literal_operand)
    <> ", A: "
    <> int.to_string(state.a)
    <> ", B: "
    <> int.to_string(state.b)
    <> ", C: "
    <> int.to_string(state.c)
    <> ", Output: "
    <> format_output(state),
  )
  io.println("Program: ")
  io.println(debug_program(state))
  io.debug("--------------------")

  io.print("\n")

  state
}

pub fn format_output(state: Computer) -> String {
  state.output
  |> list.map(fn(n) { int.to_string(n) })
  |> utils.join_by(",")
}

pub fn part_1() {
  let final_state =
    "./data/day_17_debug.txt"
    |> utils.read_lines
    |> parse_input
    |> execute_program

  final_state
  |> debug_state
  |> format_output
  |> io.println
}

pub fn part_1_with_override(a: Int) {
  let initial_state =
    "./data/day_17_debug.txt"
    |> utils.read_lines
    |> parse_input

  let overridden_state = Computer(..initial_state, a: a)

  overridden_state
  |> debug_state
  |> execute_program
  |> format_output
  |> io.println
}

pub fn get_numbers_with_prefix(prefix: Int) {
  yielder.unfold(prefix, fn(n) {
    let next = n + 1

    let max = 10_000_000_000_000_000

    case next > max {
      True -> yielder.Done
      False -> {
        case
          prefix == 0
          || next |> int.to_base8 |> string.starts_with(prefix |> int.to_base8)
        {
          True -> yielder.Next(n, next)
          False -> {
            let num_digits =
              { n |> int.to_base8 |> string.length }
              + 1
              - { prefix |> int.to_base8 |> string.length }
            let start_value = prefix * utils.int_power(8, num_digits)
            // io.debug("New start value: " <> start_value |> int.to_base8)
            yielder.Next(n, start_value)
          }
        }
      }
    }
  })
}

pub fn solve_part_2(
  state: Computer,
  target_output: List(Int),
  base8_prefix: Int,
  use_last_n: Int,
) -> List(Int) {
  // io.debug(use_last_n)
  let current_target_output =
    target_output |> list.reverse |> list.take(use_last_n) |> list.reverse

  io.debug(current_target_output)
  io.debug(base8_prefix |> int.to_base8)

  case use_last_n > list.length(target_output) {
    False -> {
      get_numbers_with_prefix(base8_prefix)
      |> yielder.map(fn(a) {
        let new_state = Computer(..state, a: a)
        let final_state = new_state |> evaluate_program(current_target_output)

        case final_state {
          Ok(_) -> #(True, a)
          _ -> #(False, a)
        }
      })
      |> yielder.filter(fn(pair) {
        let #(result, _) = pair
        result == True
      })
      |> yielder.map(fn(pair) {
        let #(_, value) = pair
        value |> io.debug

        solve_part_2(state, target_output, value, use_last_n + 1)
      })
      |> yielder.to_list
      |> list.flatten
    }
    True -> [base8_prefix]
  }
}

// This emits the correct answer but only as one of the debug outputs
// TODO: Improve output
pub fn part_2() {
  let initial_state =
    "./data/day_17.txt"
    |> utils.read_lines
    |> parse_input

  let initial_program = get_raw_program(initial_state)

  solve_part_2(initial_state, initial_program, 0, 1)
  |> io.debug
}

pub fn yield_until(max: Int) {
  yielder.unfold(0, fn(n) {
    case n < max {
      True -> yielder.Next(n, n + 1)
      False -> yielder.Done
    }
  })
}

pub fn main() {
  // part_1_with_override(0o5600532756025057)
  // part_1()
  // get_numbers_with_prefix(0o5600532756024)
  // |> yielder.take(12)
  // |> yielder.map(fn (n) { n |> int.to_base8 |> io.debug })
  // |> yielder.to_list

  part_2()

  Nil
}
