<template>
  <main>
    <h1>Home</h1>
    <div>{{ count }}</div>
    <button @click="() => increment()">Increment</button> 
    <button @click="() => run_day_1()">Run Day 1</button> 
    <button @click="() => run_day_2()">Run Day 2</button> 
  </main>
</template>

<script lang="gleam">
import day_1
import gleam/option.{Some}
import vleam/vue.{type Component, type Computed, Prop, define_component, setup, with_1_prop}

// THIS FUNCTION MUST EXIST
pub fn default_export() -> Component {
  define_component([], [], False)
  |> with_1_prop(Prop("initialCount", Some(0)))
  // Props are handed as Computed to stay reactive
  |> setup(fn(props: #(Computed(Int)), _, _) {
    let initial_count = props.0

    let count = initial_count |> vue.computed_value |> vue.ref

    let increment = fn() -> Int {
      let current_count = count |> vue.ref_value

      count |> vue.ref_set(current_count + 1)

      current_count
    }

    let run_day_1 = fn() -> Nil {
      let result = day_1.part_1_inline()
      vue.ref_set(count, result)

      Nil
    }

    let run_day_2 = fn() -> Nil {
      vue.ref_set(count, day_1.part_2_inline())

      Nil
    }

    // returning an Error will cause `setup` to throw it (don't do that)
    Ok(#(
      #("count", count),
      #("increment", increment),
      #("run_day_1", run_day_1),
      #("run_day_2", run_day_2)
    ))
  })
}
</script>
