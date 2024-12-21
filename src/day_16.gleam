import gleam/set
import gleam/option
import gleam/int
import gleam/list
import utils
import grid
import gleam/dict
import gleam/io

pub type Tile {
  Empty
  Wall
  Start
  End
}

pub type Direction {
  North
  East
  South
  West
  None
}

pub type Path = List(grid.Position)

pub type Map = grid.Grid(Tile)

pub fn parse_tile(char: String) {
  case char {
    "." -> Empty
    "#" -> Wall
    "S" -> Start
    "E" -> End
    _ -> panic as "Unknown Tile!"
  }
}

pub fn tile_to_string(tile: Tile) {
  case tile {
    Empty -> "."
    Wall -> "#"
    Start -> "S"
    End -> "E"
  }
}

pub fn parse_map(input: List(List(String))) -> Map {
  input
  |> list.map(fn (row) {
    list.map(row, fn (char) { parse_tile(char) })
  })
  |> grid.from_lists
}

pub fn stringify_map(map: Map) -> grid.Grid(String) {
  map
  |> dict.map_values(fn (_, tile) {
    tile_to_string(tile)
  })
}

/// Find the first coordinates corresponding to a specific tile
/// (only  really  useful for start and end, as they appear exactly once)
pub fn get_tile_position(map: Map, tile: Tile) -> grid.Position {
  let assert Ok(#(position, _)) = map
  |> dict.to_list
  |> list.find(fn (pair) {
    let #(_, value) = pair
    case value {
      t if t == tile -> True
      _ -> False
    }
  })

  position
}

/// Get start position of a given map.
pub fn get_start_position(map: Map) {
  get_tile_position(map, Start)
}

/// Get end position of a given map.
pub fn get_end_position(map: Map) {
  get_tile_position(map, End)
}

/// Get all surrounding positions (in a cross pattern) of a given position.
pub fn get_surrounding_positions(position: grid.Position) -> List(#(grid.Position, Direction)) {
  let #(y, x) = position

  [
    #(#(y - 1, x), North),
    #(#(y, x + 1), East),
    #(#(y + 1, x), South),
    #(#(y, x - 1), West)
  ]
}

/// Given a position, get all possible next steps, (i.e not a wall, start, or out of bounds)
pub fn get_possible_steps(map: Map, position: grid.Position) {
  position
  |> get_surrounding_positions
  |> list.filter(fn (pair) {
    let #(position, _) = pair
    case dict.get(map, position) {
      Ok(Empty) -> True
      Ok(End) -> True
      Ok(Start) -> True
      _ -> False
    }
  })
}

/// Given a position, check if it is the start
pub fn is_start(map: Map, position: grid.Position) {
  case dict.get(map, position) {
    Ok(Start) -> True
    _ -> False
  }
}

/// If we're not on the same x or y line, assume we have to turn once (i.e. that there are no walls)
pub fn heuristic_score(current_position: grid.Position, target_position: grid.Position) {
  let #(current_x, current_y) = current_position
  let #(target_x, target_y) = target_position

  let turn_cost = case current_x, current_y, target_x, target_y {
    cx, cy, tx, ty if cx == tx || cy == ty -> 0
    _, _, _, _ -> 1000
  }

  // Taxicab + estimated turn cost
  turn_cost + int.absolute_value(current_x - target_x) + int.absolute_value(current_y - target_y)
}

pub fn get_step_cost(current_direction: Direction, next_direction: Direction) -> Int {
  case current_direction, next_direction {
    None, _ -> 1001
    North, North -> 1
    East, East -> 1
    South, South, -> 1
    West, West -> 1
    _, _ -> 1001
  }
}

pub fn debug_result(result_tuple: #(List(#(Int, Path)), grid.Grid(List(#(Int, Path))))) {
  let #(paths, known_paths) = result_tuple
  io.debug("Paths:")
  paths
  |> list.length

  io.debug("Known Paths:")
  known_paths
  |> dict.size

  result_tuple
}

pub fn get_scores_memoized(
  map: Map,
  current_position: grid.Position,
  current_direction: Direction,
  current_path: List(grid.Position),
  current_score: Int,
  scores: List(Int),
  already_checked: grid.Grid(Bool),
  target_position: grid.Position,
  known_scores: grid.Grid(List(Int))
) -> #(List(Int), grid.Grid(List(Int))) {
  io.debug("Current Position: " <> grid.position_to_string(current_position))
  print_path(current_path, map)
  io.debug(dict.size(known_scores))

  case dict.get(known_scores, current_position) {
    Ok(result) -> #(result, known_scores)
    _ -> case dict.get(already_checked, current_position) {
      Ok(True) -> #(scores, known_scores)
      _ -> case current_position == target_position {
        True -> #([current_score |> io.debug, ..scores], known_scores)
        False -> {
          let possible_steps = get_possible_steps(map, current_position)
          |> list.sort(fn (a, b) {
            let #(_, direction_a) = a
            let #(_, direction_b) = b
            let step_cost_a = get_step_cost(current_direction, direction_a)
            let step_cost_b = get_step_cost(current_direction, direction_b)

            let estimated_score_a = step_cost_a
            let estimated_score_b = step_cost_b
            int.compare(estimated_score_a, estimated_score_b)
          }) // A Star babyyy

          list.fold(possible_steps, #(scores, known_scores), fn (acc, curr) {
            let #(position, direction) = curr
            let new_score = get_step_cost(current_direction, direction)
            let #(new_scores_acc, known_scores_acc) = acc

            let #(new_scores, new_known_scores) = get_scores_memoized(
              map,
              position,
              direction,
              [current_position, ..current_path],
              current_score + new_score,
              new_scores_acc,
              dict.insert(already_checked, current_position, True),
              target_position,
              known_scores
            )

            let updated_known_paths = case new_scores
            |> list.sort(fn (a, b) { int.compare(a, b) })
            |> list.first {
              Ok(result) -> dict.insert(new_known_scores, position, [result])
              _ -> new_known_scores
            }

            #(list.append(new_scores, new_scores_acc), updated_known_paths)
          })
        }
      }
    }
  }
}

pub fn get_scores(
  map: Map,
  current_position: grid.Position,
  current_direction: Direction,
  current_path: Path,
  current_score: Int,
  scores: List(Int),
  already_checked: grid.Grid(Bool),
  target_position: grid.Position,
  counter: Int,
) -> List(Int) {
  case counter % 100 {
    0 -> {
      print_path(current_path, map)
      io.print(
        "Current Position: " <> grid.position_to_string(current_position)
          <> "Current path length: " <> current_path |> list.length |> int.to_string
      )
      io.print("\r")
      io.print("\r")
      ""
    }
    _ -> ""
  }

  case dict.get(already_checked, current_position) {
    Ok(True) -> scores
    _ -> case current_position == target_position {
      True -> [current_score |> io.debug, ..scores]
      False -> {
        let possible_steps = get_possible_steps(map, current_position)
        |> list.sort(fn (a, b) {
          let #(pos_a, direction_a) = a
          let #(pos_b, direction_b) = b
          let step_cost_a = get_step_cost(current_direction, direction_a)
          let step_cost_b = get_step_cost(current_direction, direction_b)

          let estimated_score_a = step_cost_a + heuristic_score(pos_a, target_position)
          let estimated_score_b = step_cost_b + heuristic_score(pos_b, target_position)
          int.compare(estimated_score_a, estimated_score_b)
        }) // A Star babyyy

        possible_steps
        |> list.map(fn (pair) {
          let #(position, direction) = pair
          let new_score = get_step_cost(current_direction, direction)
          let new_path = [current_position, ..current_path]

          get_scores(
            map,
            position,
            direction,
            new_path,
            current_score + new_score,
            scores,
            dict.insert(already_checked, current_position, True),
            target_position,
            counter + 1,
          )
        })
        |> list.flatten
      }
    }
  }
}


pub fn get_paths(
  map: Map,
  current_position: grid.Position,
  current_direction: Direction,
  current_path: List(grid.Position),
  current_score: Int,
  paths: List(#(Int, Path)),
  already_checked: grid.Grid(Bool),
  target_position: grid.Position
) -> List(#(Int, Path)) {
  let checked = dict.get(already_checked, current_position)
  let is_target = current_position == target_position

  case checked, is_target {
    Ok(True), _ -> paths
    _, True -> [#(current_score |> io.debug, [current_position, ..current_path]), ..paths]
    _, _ -> {
      let possible_steps = get_possible_steps(map, current_position)
      |> list.sort(fn (a, b) { // A* babyyy
        int.compare(get_step_cost(current_direction, a.1), get_step_cost(current_direction, b.1))
      })

      possible_steps
      |> list.map(fn (pair) {
        let #(position, direction) = pair
        get_paths(
          map,
          position,
          direction,
          [current_position, ..current_path],
          current_score + get_step_cost(current_direction, direction),
          paths,
          dict.insert(already_checked, current_position, True),
          target_position
        )
      })
      |> list.flatten
    }
  }
}

pub fn print_path(path: Path, map: Map) {
  path
  |> list.fold(stringify_map(map), fn (acc, curr) {
    dict.insert(acc, curr, "X")
  })
  |> grid.pretty_print

  path
}

pub fn main() {
  let map = "./data/day_16.txt"
  |> utils.read_chars
  |> parse_map

  let start_position = get_start_position(map)
  let end_position = get_end_position(map)

  let scores = get_paths(
    map,
    start_position,
    None,
    [],
    0,
    [],
    dict.new(),
    end_position,
  )

  let assert Ok(best_score) = scores
  |> list.sort(fn (a, b) {
    let #(score_a, _) = a
    let #(score_b, _) = b
    int.compare(score_a, score_b)
  })
  |> list.first

  io.debug(best_score)
  // print_path(best_path, map)
  // |> list.map(fn (pair) {
  //   let #(score, path) = pair
  //   io.debug("Score: " <> int.to_string(score))
  //   print_path(map, path)
  // })
}
