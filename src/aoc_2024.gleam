import glint
import argv
import day_1
import day_2

fn day_1_cmd() -> glint.Command(Nil) {
  use <- glint.command_help("Executes the first day's exercise.")
  use _, _, _ <- glint.command()
  day_1.main()
}

fn day_2_cmd() -> glint.Command(Nil) {
  use <- glint.command_help("Executes the second's day's exercise.")
  use _, _, _ <- glint.command()
  day_2.main()
}

pub fn main() {
  glint.new()
  |> glint.with_name("Advent of Code 2024")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: [], do: day_1_cmd())
  |> glint.add(at: [], do: day_2_cmd())
  |> glint.run(argv.load().arguments)
}
