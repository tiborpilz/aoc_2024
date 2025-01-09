import gleam/io
import gleam/list
import gleam/result
import gleam/string
import utils

pub type Color {
  White
  Blue
  Black
  Red
  Green
}

pub fn startswith(base_list: List(a), compare_list: List(a)) {
  list.length(compare_list) <= list.length(base_list)
  && list.zip(base_list, compare_list)
  |> list.all(fn(pair) {
    let #(a, b) = pair
    a == b
  })
}

pub fn parse_color(char: String) -> Result(Color, Nil) {
  case char {
    "w" -> Ok(White)
    "u" -> Ok(Blue)
    "b" -> Ok(Black)
    "r" -> Ok(Red)
    "g" -> Ok(Green)
    _ -> Error(Nil)
  }
}

pub fn parse_combination(raw_combination: String) -> Result(List(Color), Nil) {
  raw_combination
  |> string.split("")
  |> list.map(fn(x) { parse_color(x) })
  |> result.all
}

pub fn parse_input(lines: List(String)) {
  // We expect the input to be well-formed
  // let #(raw_towels, rest) = lines
  // |> list.split_while(fn (line) { line != "" })

  let assert [raw_towels, "", ..raw_designs] = lines

  let assert Ok(towels) =
    raw_towels
    |> string.split(", ")
    |> list.map(fn(x) { parse_combination(x) })
    |> result.all

  let assert Ok(designs) =
    raw_designs
    |> list.map(fn(x) { parse_combination(x) })
    |> result.all

  #(towels, designs)
}

// This _should_ work but it runs for way too long
pub fn get_design_combinations(
  towels: List(List(Color)),
  design: List(Color),
  current_combination: List(List(Color)),
) -> List(List(List(Color))) {
  case design {
    [] -> [current_combination]
    design -> {
      let possible_towels =
        towels
        |> list.filter(fn(towel) { startswith(design, towel) })

      case possible_towels {
        [] -> [[[]]]
        _ ->
          possible_towels
          |> list.map(fn(towel) {
            let new_design = list.drop(design, list.length(towel))
            get_design_combinations(
              towels,
              new_design,
              list.append(current_combination, [towel]),
            )
          })
          |> list.flatten
      }
    }
  }
}

pub fn check_design(towels: List(List(Color)), design: List(Color)) {
  case design {
    [] -> True
    design -> {
      towels
      |> list.any(fn(towel) {
        let new_design = list.drop(design, list.length(towel))
        startswith(design, towel) && check_design(towels, new_design)
      })
    }
  }
}

pub fn main() {
  let #(towels, designs) =
    "./data/day_19.txt"
    |> utils.read_lines
    |> parse_input

  // Part 1

  // list.filter(designs, fn (design) {
  //   check_design(towels, design)
  // })
  // |> list.length
  // |> io.debug

  // Part 2
  list.map(designs, fn(design) {
    io.debug("start")
    get_design_combinations(towels, design, [])
  })
  |> list.map(fn(combinations) {
    combinations
    |> list.filter(fn(combination) { combination != [[]] })
    |> list.length
  })
  |> utils.sum
  |> io.debug

  Nil
}
