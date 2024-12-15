import gleam/string
import gleam/list
import gleam/io
import utils
import grid

pub type Direction {
  Up
  Right
  Down
  Left
}

pub type MapTile {
  Wall
  Empty
  Robot
}

fn to_string(tile: MapTile) -> String {
  case tile {
    Wall -> "#"
    Empty -> "."
    Robot -> "@"
  }
}

fn parse_tile(input: String) -> MapTile {
  case input {
    "#" -> Wall
    "." -> Empty
    "@" -> Robot
    _ -> panic as "Unrecognized Tile"
  }
}

fn parse_direction(input: String) -> Direction {
  case input {
    "^" -> Up
    ">" -> Right
    "v" -> Down
    "<" -> Left
    _ -> panic as "Unrecognized Direction"
  }
}

fn parse_input (input: List(String)) {
  let assert [raw_map, raw_directions] = utils.split_by_empty_row(input)

  io.debug(raw_directions)

  let map_grid = raw_map
  |> list.map(fn (row) {
    row
    |> string.split("")
    |> list.map(fn (tile) { parse_tile(tile) })
  })
  |> grid.from_lists

  io.debug(map_grid)

  // Directions can span multiple lines so we accumulate them
  // let directions = raw_directions
  // |> list.fold([], fn (acc, row) {

  // })
}

pub fn main () {
  "./data/day_15_test.txt"
  |> utils.read_lines
  |> parse_input
}
