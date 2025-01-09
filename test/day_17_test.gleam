import day_17
import gleeunit/should

///
/// Tests the `adv` instruction (opcode=0).
/// Divides A by 2^operand with a literal operand.
pub fn adv_test() {
  // Example: A=2024, operand=1 => 2^1=2 => A=2024//2=1012
  let initial_state =
    day_17.Computer(
      a: 2024,
      b: 0,
      c: 0,
      program: [#(0, 1)],
      output: [],
      pointer: 0,
    )
  let next_state = day_17.adv(initial_state)

  should.equal(next_state.a, 1012)
  should.equal(next_state.pointer, 1)
  should.equal(next_state.b, 0)
  should.equal(next_state.c, 0)
  should.equal(next_state.output, [])
}

///
/// Tests the `bxl` instruction (opcode=1).
/// B = B XOR literal operand.
pub fn bxl_test() {
  // Example: B=29, operand=3 => 29 XOR 3 = 30
  let initial_state =
    day_17.Computer(
      a: 0,
      b: 29,
      c: 0,
      program: [#(1, 3)],
      output: [],
      pointer: 0,
    )
  let next_state = day_17.bxl(initial_state)

  should.equal(next_state.b, 30)
  should.equal(next_state.pointer, 1)
  should.equal(next_state.a, 0)
  should.equal(next_state.c, 0)
  should.equal(next_state.output, [])
}

///
/// Tests the `bst` instruction (opcode=2).
/// B = (combo operand) % 8.
pub fn bst_test() {
  // Example: operand=6 => combo=read register C => B=C%8
  // If C=9 => B=1
  let initial_state =
    day_17.Computer(
      a: 0,
      b: 0,
      c: 9,
      program: [#(2, 6)],
      output: [],
      pointer: 0,
    )
  let next_state = day_17.bst(initial_state)

  should.equal(next_state.b, 1)
  should.equal(next_state.pointer, 1)
  should.equal(next_state.a, 0)
  should.equal(next_state.c, 9)
  should.equal(next_state.output, [])
}

///
/// Tests the `jnz` instruction (opcode=3).
/// If A != 0 => pointer = literal operand; otherwise pointer += 1.
pub fn jnz_test() {
  // Example: A=10 => jump to operand=5
  let initial_state =
    day_17.Computer(
      a: 10,
      b: 4,
      c: 0,
      program: [#(3, 5)],
      output: [],
      pointer: 0,
    )
  let next_state = day_17.jnz(initial_state)

  should.equal(next_state.pointer, 4)
  should.equal(next_state.output, [])
}

///
/// Tests the `bxc` instruction (opcode=4).
/// B = B XOR C, operand is ignored.
pub fn bxc_test() {
  // Example: B=2024, C=43690 => 2024 XOR 43690 = 44354
  let initial_state =
    day_17.Computer(
      a: 0,
      b: 2024,
      c: 43_690,
      program: [#(4, 0)],
      output: [],
      pointer: 0,
    )
  let next_state = day_17.bxc(initial_state)

  should.equal(next_state.b, 44_354)
  should.equal(next_state.pointer, 1)
  should.equal(next_state.output, [])
}

///
/// Tests the `out` instruction (opcode=5).
/// Append (combo operand) % 8 to output.
pub fn out_test() {
  // Example: operand=1 => literal => output [1]
  let initial_state =
    day_17.Computer(
      a: 0,
      b: 0,
      c: 0,
      program: [#(5, 1)],
      output: [],
      pointer: 0,
    )
  let next_state = day_17.out(initial_state)

  should.equal(next_state.output, [1])
  should.equal(next_state.pointer, 1)
}

///
/// Tests the `bdv` instruction (opcode=6).
/// Like adv but stores result in B.
pub fn bdv_test() {
  // Example: A=32, operand=1 => 2^1=2 => B=16 => A stays 32
  let initial_state =
    day_17.Computer(
      a: 32,
      b: 0,
      c: 0,
      program: [#(6, 1)],
      output: [],
      pointer: 0,
    )
  let next_state = day_17.bdv(initial_state)

  should.equal(next_state.a, 32)
  should.equal(next_state.b, 16)
  should.equal(next_state.pointer, 1)
  should.equal(next_state.output, [])
}

///
/// Tests the `cdv` instruction (opcode=7).
/// Like adv but stores result in C.
pub fn cdv_test() {
  // Example: A=40, operand=0 => 2^0=1 => C=40 => A=40
  let initial_state =
    day_17.Computer(
      a: 40,
      b: 0,
      c: 5,
      program: [#(7, 0)],
      output: [],
      pointer: 0,
    )
  let next_state = day_17.cdv(initial_state)

  should.equal(next_state.c, 40)
  should.equal(next_state.a, 40)
  should.equal(next_state.pointer, 1)
  should.equal(next_state.output, [])
}
