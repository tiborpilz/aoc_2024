//// Solutions for Advent of Code 2024

import argv
import gleam/int
import gleam/list
import glint

import day_1
import day_10
import day_11
import day_12
import day_13
import day_14
import day_15
import day_16
import day_17
import day_18
import day_2
import day_3
import day_4
import day_5
import day_6
import day_7
import day_8
import day_9

pub fn day_cmd(day: Int) -> glint.Command(Nil) {
  use <- glint.command_help("Executes day" <> int.to_string(day))
  use _, _, _ <- glint.command()

  case day {
    1 -> day_1.main()
    2 -> day_2.main()
    3 -> day_3.main()
    4 -> day_4.main()
    5 -> day_5.main()
    6 -> day_6.main()
    7 -> day_7.main()
    8 -> day_8.main()
    9 -> day_9.main()
    10 -> day_10.main()
    11 -> day_11.main()
    12 -> day_12.main()
    13 -> day_13.main()
    14 -> day_14.main()
    15 -> day_15.main()
    16 -> day_16.main()
    17 -> day_17.main()
    18 -> day_18.main()
    _ -> panic as "Day not implemented!"
  }
}

pub fn main() {
  let gleam_app =
    glint.new()
    |> glint.with_name("Advent of Code 2024")
    |> glint.pretty_help(glint.default_pretty_help())

  list.range(1, 18)
  |> list.fold(gleam_app, fn(acc, curr) {
    acc |> glint.add(at: ["day_" <> int.to_string(curr)], do: day_cmd(curr))
  })
  |> glint.run(argv.load().arguments)
}
