import utils
import gleam/int
import gleam/list
import gleam/io

/// Given a list of integers of length n, return n distinct, same-ordered sublists of length n-1
fn get_sublists(l: List(Int)) {
  l
  |> list.length
  |> list.range(0)
  |> list.map(fn(i) {
    let left = l
    |> list.reverse
    |> list.drop(list.length(l) - i)
    |> list.reverse
    let right = l
    |> list.drop(i + 1)
    list.flatten([left, right])
  })
  |> list.drop(1)
}

/// Returns true if difference between parameters is within safe range (1 - 3)
fn safe_dist(a: Int, b: Int) {
  case int.absolute_value(a - b) {
    i if i >= 1 && i <= 3 -> True
    _ -> False
  }
}

/// Returns true if all successive pairs of elements in list satisfy the comparator
/// and are within a safe distance
fn compare_pairwise(l: List(Int), comparator: fn(Int, Int) -> Bool) {
  case l {
    [] -> True
    [_] -> True
    [x, y, ..rest] -> comparator(x, y) && safe_dist(x, y) && compare_pairwise([y, ..rest], comparator)
  }
}

fn ascending(l: List(Int)) {
  compare_pairwise(l, fn(x, y) { x < y })
}

fn descending(l: List(Int)) {
  compare_pairwise(l, fn(x, y) { x > y })
}

fn monotonic(l: List(Int)) {
  ascending(l) || descending(l)
}

fn any_sublist_monotonic(l: List(Int)) {
  l
  |> get_sublists
  |> list.any(monotonic)
}

// More or less straightforward. The interesting thing is the pairwise comparison
// with a given comparator, making `ascending(l)` and `descending(l)` possible without
// too much code duplication.
// The more elegant approach could've been to infer whether the list is ascending or descending
// by comparing the first and second elements, and then using that to determine the comparator.
// This way, we're checking the list twice, but hey, what's a factor of two between friends?
pub fn part_1() {
  "./data/day_2.txt"
  |> utils.read_lines
  |> list.map(utils.parse_row)
  |> list.filter(monotonic)
  |> list.length
  |> utils.format_int
  |> io.println
}

// This one is a bit more tricky. This uses brute force to generate all possible distinct sublists
// of same order and length n-1, checks all of them for monotonocity and safe distances and then passes
// if any of them pass.
// The more efficient way to solve this would be to keep count of the number of
// unsafe distances/monotonicity violations in the list, and allow one.
// That would still allow for pairwise comparisons and thus be O(n).
pub fn part_2() {
  "./data/day_2.txt"
  |> utils.read_lines
  |> list.map(utils.parse_row)
  |> list.filter(any_sublist_monotonic)
  |> list.length
  |> utils.format_int
  |> io.println

}

pub fn main() {
  part_1()
  part_2()
}
