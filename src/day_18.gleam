import gleam/bool
import gleam/dict
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import grid
import utils

pub type MemorySpace {
  Safe
  Corrupted
  Path
}

pub type Map =
  grid.Grid(MemorySpace)

/// Grid of Safe or Non-Safe spaces with incoming corruption coordinates
pub type MemoryState {
  MemoryState(grid: Map, incoming_corruptions: List(grid.Position))
}

pub type Path =
  List(grid.Position)

pub fn parse_input(input: List(String), size: #(Int, Int)) -> MemoryState {
  let empty_grid = grid.fill(Safe, size)

  let corruptions =
    input
    |> list.map(fn(row) {
      let assert [x_raw, y_raw] = string.split(row, ",")
      let assert Ok(x) = int.parse(x_raw)
      let assert Ok(y) = int.parse(y_raw)

      #(y, x)
    })

  MemoryState(empty_grid, corruptions)
}

pub fn stringify_space(tile: MemorySpace) {
  case tile {
    Safe -> "."
    Corrupted -> "#"
    Path -> "O"
  }
}

pub fn debug_grid(grid: Map) {
  grid
  |> dict.map_values(fn(_, value) { stringify_space(value) })
  |> grid.pretty_print

  grid
}

pub fn get_score(position: grid.Position, scores: grid.Grid(Float)) -> Float {
  case dict.get(scores, position) {
    Ok(value) -> value
    Error(_) -> infinity() |> int.to_float
  }
}

pub fn a_star(start: grid.Position, target: grid.Position, map: Map) {
  let open_set = [start]
  let g_score = dict.new() |> dict.insert(start, 0.0)
  let f_score = dict.new() |> dict.insert(start, get_heuristic(start, target))

  do_a_star(f_score, g_score, dict.new(), target, open_set, map)
}

pub fn replay_path(initial_state: MemoryState, path: Path) {
  list.index_fold(path, initial_state.grid, fn(_acc, curr, index) {
    let new_grid = get_grid_at_time(initial_state, index + 1)

    dict.insert(new_grid, curr, Path) |> debug_grid
  })
}

pub fn insert_path(grid: Map, path: Path) -> Map {
  path
  |> list.fold(grid, fn(acc, curr) { dict.insert(acc, curr, Path) })
}

pub fn get_grid_at_time(memory_state: MemoryState, time: Int) -> Map {
  memory_state.incoming_corruptions
  |> list.take(time)
  |> list.fold(memory_state.grid, fn(acc, curr) {
    dict.insert(acc, curr, Corrupted)
  })
}

pub fn debug_path(path: Path, map: Map) {
  insert_path(map, path)
  |> debug_grid

  path
}

/// Get all surrounding positions (in a cross pattern) of a given position.
pub fn get_surrounding_positions(position: grid.Position) -> List(grid.Position) {
  let #(y, x) = position

  [#(y - 1, x), #(y, x + 1), #(y + 1, x), #(y, x - 1)]
}

pub fn get_possible_steps(map: Map, position: grid.Position) {
  position
  |> get_surrounding_positions
  |> list.filter(fn(position) {
    case dict.get(map, position) {
      Ok(Corrupted) -> False
      Ok(Safe) -> True
      _ -> False
    }
  })
}

pub fn get_heuristic(a: grid.Position, b: grid.Position) {
  int.absolute_value(a.0 - b.0) + int.absolute_value(a.1 - b.1)
  |> int.to_float
}

pub fn get_distance(a: grid.Position, b: grid.Position) {
  { int.power(a.0 - b.0, 2.0) |> result.unwrap(0.0) }
  +. { int.power(a.1 - b.1, 2.0) |> result.unwrap(0.0) }
}

pub fn reconstruct_path(
  came_from: grid.Grid(grid.Position),
  current: grid.Position,
  total_path: Path,
) {
  case dict.get(came_from, current) {
    Ok(value) ->
      reconstruct_path(came_from, value, list.prepend(total_path, current))
    _ -> list.prepend(total_path, current)
  }
}

pub fn infinity() {
  4_294_967_296
}

pub fn is_corrupted(map: Map, position: grid.Position) {
  case dict.get(map, position) {
    Ok(Safe) -> False
    _ -> True
  }
}

pub fn handle_neighbors_of_current(
  neighbors: List(grid.Position),
  f_score: grid.Grid(Float),
  g_score: grid.Grid(Float),
  came_from: grid.Grid(grid.Position),
  current: grid.Position,
  target: grid.Position,
  open_set: List(grid.Position),
  map: Map,
) {
  case neighbors {
    [neighbor, ..rest] -> {
      use <- bool.lazy_guard(is_corrupted(map, neighbor), fn() {
        handle_neighbors_of_current(
          rest,
          g_score,
          f_score,
          came_from,
          current,
          target,
          open_set,
          map,
        )
      })

      let tentative_g_score =
        case dict.get(g_score, current) {
          Ok(value) -> value
          Error(_) -> infinity() |> int.to_float
        }
        +. { get_heuristic(target, current) }

      case
        tentative_g_score
        <. case dict.get(g_score, neighbor) {
          Ok(value) -> value
          Error(_) -> infinity() |> int.to_float
        }
      {
        True -> {
          let came_from = dict.insert(came_from, neighbor, current)
          let g_score = dict.insert(g_score, neighbor, tentative_g_score)
          let f_score =
            dict.insert(
              f_score,
              neighbor,
              tentative_g_score +. get_heuristic(neighbor, target),
            )

          let open_set = case list.contains(open_set, neighbor) {
            False -> [neighbor, ..open_set]
            True -> open_set
          }

          handle_neighbors_of_current(
            rest,
            f_score,
            g_score,
            came_from,
            current,
            target,
            open_set,
            map,
          )
        }

        False ->
          handle_neighbors_of_current(
            rest,
            f_score,
            g_score,
            came_from,
            current,
            target,
            open_set,
            map,
          )
      }
    }
    [] -> do_a_star(f_score, g_score, came_from, target, open_set, map)
  }
}

pub fn sort_by_f_score(
  positions: List(grid.Position),
  f_score: grid.Grid(Float),
) -> List(grid.Position) {
  list.sort(positions, fn(a, b) {
    let a_score = get_score(a, f_score)
    let b_score = get_score(b, f_score)
    float.compare(a_score, b_score)
  })
}

pub fn do_a_star(
  f_score: grid.Grid(Float),
  g_score: grid.Grid(Float),
  came_from: grid.Grid(grid.Position),
  target: grid.Position,
  open_set: List(grid.Position),
  map: Map,
) {
  case list.is_empty(open_set) {
    False -> {
      use current <- result.try(case sort_by_f_score(open_set, f_score) {
        [lowest, ..] -> Ok(lowest)
        _ -> Error(Nil)
      })

      use <- bool.guard(
        current == target,
        Ok(reconstruct_path(came_from, current, [])),
      )

      let open_set = list.filter(open_set, fn(value) { value != current })

      handle_neighbors_of_current(
        get_surrounding_positions(current),
        f_score,
        g_score,
        came_from,
        current,
        target,
        open_set,
        map,
      )
    }
    True -> Error(Nil)
  }
}

pub fn solve_grid(
  memory_state: MemoryState,
  current_position: grid.Position,
  current_path: Path,
  paths: List(Path),
  target_position: grid.Position,
  already_checked: grid.Grid(Bool),
  came_from: grid.Grid(grid.Position),
  current_time: Int,
) -> List(Path) {
  let checked = dict.get(already_checked, current_position)
  let is_target = current_position == target_position

  case checked, is_target {
    Ok(True), _ -> paths
    _, True -> [[current_position, ..current_path] |> list.reverse, ..paths]
    _, _ -> {
      let new_grid = memory_state.grid

      let new_state = MemoryState(..memory_state, grid: new_grid)
      let steps =
        get_possible_steps(new_grid, current_position)
        |> list.sort(fn(a, b) {
          float.compare(
            get_heuristic(a, target_position),
            get_heuristic(b, target_position),
          )
        })

      let new_came_from =
        list.fold(steps, came_from, fn(acc, curr) {
          dict.insert(acc, curr, current_position)
        })

      list.map(steps, fn(step) {
        solve_grid(
          new_state,
          step,
          [current_position, ..current_path],
          paths,
          target_position,
          dict.insert(already_checked, current_position, True),
          new_came_from,
          current_time + 1,
        )
      })
      |> list.sort(fn(a, b) { int.compare(list.length(a), list.length(b)) })
      |> list.flatten()
    }
  }
}

pub fn get_path_length(path: Path) {
  list.length(path) - 1
}

pub fn solve_for_time(state: MemoryState, size: Int, time: Int) {
  let grid_at_time = get_grid_at_time(state, time)

  a_star(#(0, 0), #(size - 1, size - 1), grid_at_time)
}

pub fn part_1_generic(file: String, size: Int, time: Int) {
  let start_state =
    file
    |> utils.read_lines
    |> parse_input(#(size, size))

  let assert Ok(path) = solve_for_time(start_state, size, time)

  path |> get_path_length |> io.debug
}

pub fn part_test() {
  part_1_generic("./data/day_18_test.txt", 7, 12)
}

pub fn part_1() {
  part_1_generic("./data/day_18.txt", 71, 1024)
}

pub fn part_2_generic(file: String, size: Int, offset: Int) {
  let start_state =
    file
    |> utils.read_lines
    |> parse_input(#(size, size))

  let total_bytes = file |> utils.read_lines |> list.length

  let working_times =
    list.range(total_bytes - 1, offset)
    |> list.take_while(fn(time) {
      case solve_for_time(start_state, size, time) {
        Ok(path) -> {
          start_state
          |> get_grid_at_time(time)
          |> debug_path(path, _)
          io.debug(time)
          False
        }
        _ -> {
          start_state
          |> get_grid_at_time(time)
          |> debug_grid

          io.debug(time)
          True
        }
      }
    })

  let assert Ok(lowest_nonworking_time) = list.last(working_times)

  utils.at(start_state.incoming_corruptions, lowest_nonworking_time - 1)
  |> io.debug
}

pub fn part_2_test() {
  part_2_generic("./data/day_18_test.txt", 7, 12)
}

pub fn part_2() {
  part_2_generic("./data/day_18.txt", 71, 1024)
}

pub fn main() {
  let _ = part_2()

  Nil
}
