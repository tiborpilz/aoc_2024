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

fn satisfies_all_rules(a: Int, rest: List(Int), rules: List(#(Int, Int))) {
  rest
  |> list.any(fn (b) { list.contains(rules, #(a, b)) })
  |> bool.negate
}

fn check_page(page: List(Int), rules: List(#(Int, Int))) {
  case page {
    [] -> True
    [_] -> True
    [a, ..rest] -> satisfies_all_rules(a, rest, rules) && check_page(rest, rules)
  }
}

fn parse_data(data: List(String)) {
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

  #(pages, rules)
}

fn get_valid_pages(data: List(String)) {
  let #(pages, rules) = parse_data(data)

  pages |> list.filter(fn (page) { check_page(page, rules) })
}

fn get_invalid_pages(data: List(String)) {
  let #(pages, rules) = parse_data(data)

  pages |> list.filter(fn (page) {
    check_page(page, rules) |> bool.negate
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

// Hacky, assumes that a and b are in the list only once
fn swap(input: List(Int), a: Int, b: Int) {
  case list.contains(input, a) && list.contains(input, b) {
    False -> input
    True -> input
      |> list.map(fn (x) {
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
// We _could_ build some sort of solver to check which swaps we need to do
// to get a valid page (which definitely is NP-hard)
// orrrrrrr
// we just randomize the rules every time, lol
pub fn sort_until_valid(page: List(Int), rules: List(#(Int, Int))) {
  case check_page(page, rules) {
    True -> page
    False -> rules
      |> list.shuffle
      |> list.filter(fn (rule) {
        check_page(page, [rule]) |> bool.negate
      })
      |> list.fold(page, fn (page, rule) {
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
  |> list.filter(fn (page) {
    check_page(page, rules) |> bool.negate
  })
  |> list.map(fn (page) {
    sort_until_valid(page, rules)
  })
  |> sum_middle_values
  |> io.debug
}

pub fn main() {
  part_2()
  |> io.debug
}
