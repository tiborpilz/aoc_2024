// Create ordering rule from list of strings "a|b" where a needs to come before b
//
// Since numbers don't have to be in an ordering rule, use the negation, so "a|b"
// results in a rule #(b, a), which, if violated, fails the check.

// To check for a list [a,b,c,d] check the ordering for
// #(a, [b,c,d]), #(b, [c,d]) and #(c, [d])

import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import utils

// Reverse the numbers because we want to check for any that are _not_ satisfying the rule
fn parse_rule(rule: String) {
  let assert [a, b] = string.split(rule, "|")
  let assert Ok(a_parsed) = int.parse(a)
  let assert Ok(b_parsed) = int.parse(b)
  #(b_parsed, a_parsed)
}

fn parse_pages(page: String) {
  page
  |> string.split(",")
  |> list.map(fn (x) {
    let assert Ok(x_parsed) = int.parse(x)
    x_parsed
  })
}

fn satisfies_rule(a: Int, rest: List(Int), rules: List(#(Int, Int))) {
  rest
  |> list.any(fn (b) { list.contains(rules, #(a, b)) })
  |> bool.negate
}

fn check_page(page: List(Int), rules: List(#(Int, Int))) {
  case page {
    [] -> True
    [_] -> True
    [a, ..rest] -> satisfies_rule(a, rest, rules) && check_page(rest, rules)
  }
}

fn get_valid_pages(data: List(String)) {
  let rules = data
  |> list.take_while(fn (row) {
      row != ""
    })
  |> list.map(parse_rule)

  // pages start after rules
  let pages_index = list.length(rules)
  let #(_, pages_raw) = list.split(data, pages_index + 1)
  let pages = pages_raw
  |> list.map(parse_pages)

  pages
  |> list.filter(fn (page) {
    check_page(page, rules)
  })
}

pub fn sum_middle_values(pages: List(List(Int))) {
  pages
  |> list.map(fn (page) {
      let assert Ok(middle_index) = page
      |> list.length
      |> int.floor_divide(2)

      let assert Ok(middle_entry) = page
      |> list.take(middle_index + 1)
      |> list.last()

      middle_entry
    })
  |> utils.sum
}

pub fn part_1() {
  let data = utils.read_lines("./data/day_5.txt")

  data
  |> get_valid_pages
  |> sum_middle_values
  |> io.debug
}

pub fn main() {
  part_1()
}
