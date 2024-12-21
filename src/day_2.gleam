//// Part 1 is more or less straightforward. The interesting thing is the pairwise comparison
//// with a given comparator, making `ascending(l)` and `descending(l)` possible without
//// too much code duplication.
////
//// The more elegant approach could've been to infer whether the list is ascending or descending
//// by comparing the first and second elements, and then using that to determine the comparator.
//// This way, we're checking the list twice, but hey, what's a factor of two between friends?
//// Part 2 is a bit more tricky. The techniques are mostly the same as the one used in part 1, save
//// for allowing one constraint violation per row. For that, this solution uses brute force to generate
//// all possible distinct sublists of same ordering and length n-1, checks all of them for monotonicity
//// and safe distances and then passes if any of them pass.
//// The more efficient way to solve this would be to keep count of the number of
//// unsafe distances/monotonicity violations in the list during the entire comparison, and allow one.
//// That would still allow for pairwise comparisons and thus be O(n).

import gleam/int
import gleam/list
import utils

/// Returns true if difference between parameters is within safe range (1 - 3)
pub fn safe_dist(a: Int, b: Int) {
  case int.absolute_value(a - b) {
    i if i >= 1 && i <= 3 -> True
    _ -> False
  }
}

/// Returns true if all successive pairs of elements in list satisfy the comparator
/// and are within a safe distance
pub fn compare_pairwise(l: List(Int), comparator: fn(Int, Int) -> Bool) {
  case l {
    [] -> True
    [_] -> True
    [x, y, ..rest] ->
      comparator(x, y)
      && safe_dist(x, y)
      && compare_pairwise([y, ..rest], comparator)
  }
}

/// Returns true if all successive pairs of elements in list are ascending
pub fn ascending(l: List(Int)) {
  compare_pairwise(l, fn(x, y) { x < y })
}

/// Returns true if all successive pairs of elements in list are descending
pub fn descending(l: List(Int)) {
  compare_pairwise(l, fn(x, y) { x > y })
}

/// Returns true if list is either ascending or descending
pub fn monotonic(l: List(Int)) {
  ascending(l) || descending(l)
}

pub fn part_1() {
  "./data/day_2.txt"
  |> utils.read_lines
  |> list.map(utils.parse_row)
  |> list.filter(monotonic)
  |> list.length
  |> utils.format_int
}

/// Given a list of integers of length n, return n distinct, same-ordered sublists of length n-1
pub fn get_sublists(l: List(Int)) {
  l
  |> list.length
  |> list.range(0)
  |> list.map(fn(i) {
    // Remove ith element from list
    let left =
      l
      |> list.reverse
      |> list.drop(list.length(l) - i)
      |> list.reverse
    let right =
      l
      |> list.drop(i + 1)
    list.flatten([left, right])
  })
  |> list.drop(1)
  // implementation artifact, first sublist is the original list
}

pub fn part_2() {
  "./data/day_2.txt"
  |> utils.read_lines
  |> list.map(utils.parse_row)
  |> list.filter(fn(l) { l |> get_sublists |> list.any(monotonic) })
  |> list.length
  |> utils.format_int
}

pub fn main() {
  part_1()
  |> utils.print_with_part("Part 1")
  part_2()
  |> utils.print_with_part("Part 2")
}
