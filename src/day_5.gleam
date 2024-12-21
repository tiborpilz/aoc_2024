//// Create ordering rule from list of strings "a|b" where a needs to come before b
////
//// Since numbers don't have to be in an ordering rule, use the negation, so "a|b"
//// results in a rule #(b, a), which, if violated, fails the check.
//// To check for a list [a,b,c,d] check the ordering for
//// #(a, [b,c,d]), #(b, [c,d]) and #(c, [d])

import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import utils

/// Given a rule line, parse a rule in format of "a|b" to a tuple of #(b, a).
/// This is because we use the rule to check for validations, meaning we need to reverse the order.
pub fn parse_rule(rule: String) -> #(Int, Int) {
  let assert [a, b] = string.split(rule, "|")
  let assert Ok(a_parsed) = int.parse(a)
  let assert Ok(b_parsed) = int.parse(b)
  #(b_parsed, a_parsed)
}

/// Given a page, parse the page to a list of integers.
pub fn parse_pages(page: String) -> List(Int) {
  page
  |> string.split(",")
  |> list.map(fn(x) {
    let assert Ok(x_parsed) = int.parse(x)
    x_parsed
  })
}

/// Given the initial data (already as lines) parse the data to a tuple of a list of
/// pages and a list of rules.
pub fn parse_data(data: List(String)) {
  let rules =
    data
    |> list.take_while(fn(row) { row != "" })
    |> list.map(parse_rule)

  // pages start after rules
  let pages_index = list.length(rules)
  let #(_, pages_raw) = list.split(data, pages_index + 1)
  let pages =
    pages_raw
    |> list.map(parse_pages)

  #(pages, rules)
}

/// Does the provided list of integers satisfy all rules pairwise?
pub fn rest_satisfies_all_rules(a: Int, rest: List(Int), rules: List(#(Int, Int))) {
  rest
  |> list.any(fn(b) { list.contains(rules, #(a, b)) })
  |> bool.negate
}

/// Empty and 1 element lists are always valid
/// For the others, check if the first element satisfies all rules with the rest of the list (pairwise)
/// and then check the rest of the list
pub fn check_page(page: List(Int), rules: List(#(Int, Int))) {
  case page {
    [] -> True
    [_] -> True
    [a, ..rest] ->
      rest_satisfies_all_rules(a, rest, rules) && check_page(rest, rules)
  }
}

/// Given a list of pages and rules, return the pages that satisfy all rules
pub fn get_valid_pages(data: List(String)) {
  let #(pages, rules) = parse_data(data)

  pages |> list.filter(fn(page) { check_page(page, rules) })
}

pub fn sum_middle_values(pages: List(List(Int))) {
  pages
  |> list.map(fn(page) {
    let assert Ok(middle_index) =
      page
      |> list.length
      |> int.floor_divide(2)

    let assert Ok(middle_entry) =
      page
      |> list.take(middle_index + 1)
      |> list.last()

    middle_entry
  })
  |> utils.sum
}

// Assumes that a and b are in the list only once
pub fn swap(input: List(Int), a: Int, b: Int) {
  case list.contains(input, a) && list.contains(input, b) {
    False -> input
    True ->
      input
      |> list.map(fn(x) {
        case x {
          n if n == a -> b
          n if n == b -> a
          _ -> x
        }
      })
  }
}

pub fn part_1() {
  let data = utils.read_lines("./data/day_5.txt")

  data
  |> get_valid_pages
  |> sum_middle_values
  |> io.debug
}

// Basically, keep swapping until the page is valid
// Since this is a naive approach we run the risk of entering loops where this function
// keeps swapping forever.
// We _could_ build some sort of solver to check which order we need to do the swaps
// in to get a valid page (which is NP-hard, and, more importantly, effort)
// orrrrrrr
// we just randomize the rules every time, lol
pub fn sort_until_valid(page: List(Int), rules: List(#(Int, Int))) {
  case check_page(page, rules) {
    True -> page
    False ->
      rules
      |> list.shuffle
      |> list.filter(fn(rule) { check_page(page, [rule]) |> bool.negate })
      |> list.fold(page, fn(page, rule) {
        let #(a, b) = rule
        swap(page, a, b)
      })
      |> sort_until_valid(rules)
  }
}

pub fn part_2() {
  let data = utils.read_lines("./data/day_5.txt")

  let #(pages, rules) = parse_data(data)

  pages
  |> list.filter(fn(page) { check_page(page, rules) |> bool.negate })
  |> list.map(fn(page) { sort_until_valid(page, rules) })
  |> sum_middle_values
  |> io.debug
}

pub fn main() {
  part_2()
  |> io.debug

  Nil
}
