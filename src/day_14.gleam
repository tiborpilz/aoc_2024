import gleam/result
import gleam/dict
import grid
import gleam/list
import gleam/io
import utils
import gleam/int
import gleam/regexp
import gleam/option

pub type Vec2 {
  Vec2(x: Int, y: Int)
}

pub type Robot {
  Robot(pos: Vec2, vel: Vec2)
}

pub type Space {
  Space(width: Int, height: Int)
}

pub fn parse_robot(line: String) -> Robot {
  let assert Ok(robot_regex) = regexp.from_string("p=([0-9]+),([0-9]+) v=(-?[0-9]+),(-?[0-9]+)")

  let assert [match] = regexp.scan(robot_regex, line)
  let assert regexp.Match(_, [
    option.Some(px_raw),
    option.Some(py_raw),
    option.Some(vx_raw),
    option.Some(vy_raw)]
  ) = match

  let assert Ok(px) = int.parse(px_raw)
  let assert Ok(py) = int.parse(py_raw)
  let assert Ok(vx) = int.parse(vx_raw)
  let assert Ok(vy) = int.parse(vy_raw)

  Robot(pos: Vec2(x: px, y: py), vel: Vec2(x: vx, y: vy))
}

pub fn move_robot(robot: Robot, seconds: Int, space: Space) -> Robot {
  let Space(width, height) = space

  let assert Ok(new_x) = int.modulo(robot.pos.x + { robot.vel.x * seconds }, width)
  let assert Ok(new_y) = int.modulo(robot.pos.y + { robot.vel.y * seconds }, height)

  Robot(..robot, pos: Vec2(x: new_x, y: new_y))
}

pub fn get_quadrant_counts(robots: List(Robot), space: Space) {
  list.fold(robots, #(0, 0, 0, 0), fn (acc, curr) {
    let #(q1, q2, q3, q4) = acc
    let mid_x = space.width / 2
    let mid_y = space.height / 2

    case curr.pos.x, curr.pos.y {
      x, y if x == mid_x || y == mid_y -> #(q1, q2, q3, q4)
      x, y if x < mid_x && y < mid_y -> #(q1 + 1, q2, q3, q4)
      x, y if x < mid_x && y > mid_y -> #(q1, q2 + 1, q3, q4)
      x, y if x > mid_x && y < mid_y -> #(q1, q2, q3 + 1, q4)
      x, y if x > mid_x && y > mid_y -> #(q1, q2, q3, q4 + 1)
      _, _ -> #(q1, q2, q3, q4)
    }
  })
}

pub fn get_quadrants(robots: List(Robot), space: Space) {
  let mid_height = { space.height } / 2
  let mid_width = { space.width } / 2

  let is_in_upper_half = fn (robot: Robot) {
    robot.pos.y < mid_height
  }

  let is_in_lower_half = fn (robot: Robot) {
    robot.pos.y > mid_height
  }

  let is_in_left_half = fn (robot: Robot) {
    robot.pos.x < mid_width
  }

  let is_in_right_half = fn (robot: Robot) {
    robot.pos.x > mid_width
  }

  let quadrant_nw = robots
  |> list.filter(fn (robot) { is_in_upper_half(robot) && is_in_left_half(robot) })

  let quadrant_ne = robots
  |> list.filter(fn (robot) { is_in_upper_half(robot) && is_in_right_half(robot) })

  let quadrant_sw = robots
  |> list.filter(fn (robot) { is_in_lower_half(robot) && is_in_left_half(robot) })

  let quadrant_se = robots
  |> list.filter(fn (robot) { is_in_lower_half(robot) && is_in_right_half(robot) })

  [quadrant_nw, quadrant_ne, quadrant_sw, quadrant_se]
}

pub fn print_robots(robots: List(Robot), space: Space, seconds: Int) {
  let grid = "."
  |> list.repeat(space.width)
  |> list.repeat(space.height)
  |> grid.from_lists


  io.debug("Seconds: " <> int.to_string(seconds))

  list.fold(robots, grid, fn (acc, curr) {
    let Robot(pos: Vec2(x,y), vel: _) = curr
    let num_robots_here = case dict.get(acc, #(y, x)) {
      Ok(val) -> result.unwrap(int.parse(val), 0)
      _ -> 0
    }

    dict.insert(acc, #(y, x), int.to_string(num_robots_here + 1))
  })
  |> grid.to_lists
  |> list.map(fn(row) { io.debug(utils.join(row)) })

  robots
}

pub fn print_quadrants(quadrants: List(List(Robot)), space: Space, seconds: Int) {
  list.map(quadrants, fn (quadrant) {
    io.debug("---")
    print_robots(quadrant, space, seconds)
  })
}

pub fn highest_row_count(robots: List(Robot)) {
  robots
  |> list.group(fn (robot) {
    robot.pos.y
  })
  |> dict.fold(0, fn (acc, _, value) {
    let length = list.length(value)
    case length > acc {
      True -> length
      False -> acc
    }
  })
}

pub fn main() {
  io.debug(103 / 2)
  // let space = Space(width: 11, height: 7)
  let space = Space(width: 101, height: 103)

  let robots = "./data/day_14.txt"
  |> utils.read_lines
  |> list.map(parse_robot)


  list.range(0, 15000)
  |> list.map(fn (seconds) {
    let moved_robots = robots
    |> list.map(fn (robot) {
      move_robot(robot, seconds, space)
    })

    let highest_row_count = highest_row_count(moved_robots)
    case highest_row_count > 30 {
      True -> print_robots(moved_robots, space, seconds)
      False -> moved_robots
    }
  })
  // |> print_robots(space)
  // |> get_quadrants(space)
  // |> print_quadrants(space)
  // |> list.fold(1, fn (acc, curr) {
  //   acc * list.length(curr)
  // })
  // |> io.debug
}
