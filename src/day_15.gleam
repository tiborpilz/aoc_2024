import gleam/dict
import gleam/io
import gleam/list
import gleam/string
import grid
import utils

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
  Box
}

pub type Map =
  grid.Grid(MapTile)

fn to_string(tile: MapTile) -> String {
  case tile {
    Wall -> "#"
    Empty -> "."
    Box -> "O"
    Robot -> "@"
  }
}

fn direction_to_string(direction: Direction) -> String {
  case direction {
    Up -> "Up"
    Right -> "Right"
    Down -> "Down"
    Left -> "Left"
  }
}

fn parse_tile(input: String) -> MapTile {
  case input {
    "#" -> Wall
    "." -> Empty
    "@" -> Robot
    "O" -> Box
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

fn get_robot_row(map: Map) -> List(#(#(Int, Int), MapTile)) {
  let assert Ok(row) =
    grid.to_row_list_indexed(map)
    |> list.find(fn(row) {
      list.any(row, fn(cell) {
        let #(_, value) = cell
        value == Robot
      })
    })

  row
}

fn get_robot_col(map: Map) -> List(#(#(Int, Int), MapTile)) {
  let assert Ok(col) =
    grid.to_col_list_indexed(map)
    |> list.find(fn(col) {
      list.any(col, fn(cell) {
        let #(_, value) = cell
        value == Robot
      })
    })

  col
}

fn get_robot_position(map: Map) -> #(Int, Int) {
  let assert Ok(#(pos, _)) =
    map
    |> dict.to_list
    |> list.find(fn(tile) {
      let #(_, value) = tile
      value == Robot
    })
  pos
}

fn get_robot_path(line: List(#(#(Int, Int), MapTile))) {
  case line {
    [] -> panic as "Robot not found in line!"
    [#(_, Robot), ..rest] -> rest
    [_, ..rest] -> get_robot_path(rest)
  }
}

fn is_next_space_empty(path: List(#(#(Int, Int), MapTile))) {
  case path {
    [#(_, Empty), ..] -> True
    _ -> False
  }
}

fn get_boxes_to_move(path: List(#(#(Int, Int), MapTile))) {
  case
    list.any(path, fn(element) {
      let #(_, value) = element
      value == Empty
    })
  {
    False -> []
    True ->
      list.fold_until(path, [], fn(acc, curr) {
        case curr {
          #(_, Box) -> list.Continue(list.append(acc, [curr]))
          #(_, Empty) -> list.Stop(acc)
          #(_, Wall) -> list.Stop([])
          #(_, _) -> list.Stop([])
          // How did you get here :D
        }
      })
    // list.take_while(path, fn (element) {
    //   let #(_, value) = element
    //   value == Box
    // })
  }
}

fn get_new_position(position: #(Int, Int), direction: Direction) -> #(Int, Int) {
  let #(y, x) = position
  case direction {
    Up -> #(y - 1, x)
    Right -> #(y, x + 1)
    Down -> #(y + 1, x)
    Left -> #(y, x - 1)
  }
}

fn move_robot(map: Map, direction: Direction) -> Map {
  let #(y, x) = get_robot_position(map)
  let new_position = get_new_position(#(y, x), direction)

  map
  |> dict.insert(#(y, x), Empty)
  |> dict.insert(new_position, Robot)
}

fn move_boxes(
  map: Map,
  direction: Direction,
  boxes: List(#(#(Int, Int), MapTile)),
) -> Map {
  list.fold(boxes, map, fn(acc, curr) {
    let #(pos, _) = curr
    let new_box_position = get_new_position(pos, direction)

    dict.insert(acc, new_box_position, Box)
  })
}

fn try_direction(map: Map, direction: Direction) {
  let line = case direction {
    Up -> map |> get_robot_col |> list.reverse
    Right -> map |> get_robot_row
    Down -> map |> get_robot_col
    Left -> map |> get_robot_row |> list.reverse
  }

  let path = get_robot_path(line)

  let boxes_to_move = get_boxes_to_move(path)

  case is_next_space_empty(path), boxes_to_move {
    False, [] -> map
    True, [] -> move_robot(map, direction)
    _, _ -> map |> move_robot(direction) |> move_boxes(direction, boxes_to_move)
  }
}

fn update_map(map: Map, directions: List(Direction)) -> Map {
  case directions {
    [] -> map
    [direction, ..rest] -> update_map(try_direction(map, direction), rest)
  }
}

fn parse_input(input: List(String)) -> #(Map, List(Direction)) {
  let assert [raw_map, raw_directions] = utils.split_by_empty_row(input)

  let map_grid =
    raw_map
    |> list.map(fn(row) {
      row
      |> string.split("")
      |> list.map(fn(tile) { parse_tile(tile) })
    })
    |> grid.from_lists

  let directions =
    raw_directions
    |> list.map(fn(row) {
      row
      |> string.split("")
    })
    |> list.reverse
    |> list.flatten
    |> list.map(fn(direction) { parse_direction(direction) })

  #(map_grid, directions)
}

fn debug_map(map: Map) {
  map
  |> grid.to_lists
  |> list.map(fn(row) {
    list.map(row, fn(element) { to_string(element) })
    |> utils.join
    |> io.debug
  })
}

fn get_score(map: Map) {
  dict.filter(map, fn(_, value) { value == Box })
  |> dict.to_list
  |> list.map(fn(tile) {
    let #(#(y, x), _) = tile
    { y * 100 } + { x }
  })
}

pub fn main() {
  let #(map, directions) =
    "./data/day_15.txt"
    |> utils.read_lines
    |> parse_input

  let updated_map = update_map(map, directions)

  debug_map(updated_map)

  updated_map
  |> get_score
  |> utils.sum
  |> io.debug
  // |> grid.to_lists
  // |> list.map(fn (row) {
  //   list.map(row, fn (element) {
  //     to_string(element)
  //   })
  //   |> utils.join
  //   |> io.debug
  // })
}
