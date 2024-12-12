import gleam/dict
import gleam/io
import gleam/int
import gleam/list
import gleam/string
import utils

/// Integer-addressed block content and a list of keys of gaps (ascending) as well as content keys (descending)
type Blocks = #(
  dict.Dict(Int, Int), // File System Blocks
  List(Int), // Keys of free gaps (ascending)
  List(Int), // Keys of files (descending)
  dict.Dict(Int, #(Int, Int)), // File ID to start block and length
  dict.Dict(Int, Int) // Free gap keys to their size
)

/// Gets blocks from disk map
/// Ints over 0 represent block ids, -1 represents free space
pub fn get_blocks(disk_map: String) -> Blocks {
  disk_map
  |> string.split("")
  |> list.index_fold(#(dict.new(), [], [], dict.new(), dict.new()), fn (acc, curr, index) {
    let #(blocks, gap_keys, content_keys, files, gap_sizes) = acc

    let assert Ok(parsed_block_size) = int.parse(curr)
    let assert Ok(block_id) = int.floor_divide(index, 2)

    let is_gap = index % 2 != 0

    let block_value = case is_gap {
      False -> block_id
      True -> -1
    }

    let key_offset = dict.size(blocks)

    let new_gaps = case is_gap {
      False -> gap_keys
      True -> case parsed_block_size == 0 {
        False -> list.append(gap_keys, list.range(key_offset, { key_offset + parsed_block_size } - 1))
        True -> gap_keys
      }
    }

    let new_content_keys = case is_gap {
      True -> content_keys
      False -> case parsed_block_size == 0 {
        False -> list.append(key_offset |> list.range({ key_offset + parsed_block_size } - 1) |> list.reverse, content_keys)
        True -> gap_keys
      }
    }

    let new_blocks = list.repeat(block_value, parsed_block_size)
    |> list.index_fold(blocks, fn(block_dict, block_value, block_index) {
      let key = key_offset + block_index
      dict.insert(block_dict, key, block_value)
    })

    let new_files = case is_gap {
      True -> files
      False -> dict.insert(files, block_id, #(key_offset, parsed_block_size))
    }

    let new_gap_sizes = case is_gap {
      False -> gap_sizes
      True -> dict.insert(gap_sizes, key_offset, parsed_block_size)
    }

    #(new_blocks, new_gaps, new_content_keys, new_files, new_gap_sizes)
  })
}

pub fn get_smallest_gap_key(blocks: Blocks) -> #(Int, List(Int)) {
  let assert Ok(smallest_key) = list.reduce(blocks.1, int.min)
  let rest = list.filter(blocks.1, fn (n) { n != smallest_key })

  #(smallest_key, rest)
}

pub fn move_last_block_to_smallest_gap(blocks: Blocks) {
  let #(block_content, gap_keys, content_keys, files, gap_sizes) = blocks
  let assert [smallest_gap_key, ..gap_keys_rest] = gap_keys
  let assert [last_content_key, ..content_keys_rest] = content_keys
  let assert Ok(last_content_value) = dict.get(blocks.0, last_content_key)

  let new_block_content = block_content
  |> dict.insert(smallest_gap_key, last_content_value)
  |> dict.insert(last_content_key, -1)

  #(new_block_content, list.append(gap_keys_rest, [last_content_key]), list.append(content_keys_rest, [smallest_gap_key]), files, gap_sizes)
}

// pub fn move_last_file_to_smallest_available_gap(blocks: Blocks) {
//   let #(block_content, gap_keys, content_keys, files, gap_sizes) = blocks
//   let assert [last_content_key, ..content_keys_rest] = content_keys

//   let assert Ok(file) = dict.get(files, last_content_key)

//   let first_gap_that_fits = list.find(gap_keys, fn (key) {
//     case dict.get(gap_sizes, key) {
//       Ok(size) if size > file.0 -> True
//       _ -> False
//     }
//   })

//   let new_block_content = case first_gap_that_fits {
//     Ok(gap) if gap > 0 -> list.range(gap)
//   }
// }

pub fn is_defragmented(blocks: Blocks) -> Bool {
  let assert [smallest_gap_key, .._] = blocks.1
  let assert [last_content_key, .._] = blocks.2

  smallest_gap_key > last_content_key
}

/// Reorder blocks so that the first gap key is larger than all content keys
pub fn defragment(blocks: Blocks) -> Blocks {
  case is_defragmented(blocks) {
    True -> blocks
    False -> defragment(move_last_block_to_smallest_gap(blocks))
  }
}

fn sort_by_key(a: #(Int, a), b: #(Int, a)) {
  int.compare(a.0, b.0)
}

pub fn get_content(blocks: Blocks) -> List(Int) {
  dict.to_list(blocks.0)
  |> list.sort(sort_by_key)
  |> list.map(fn (key_value) { key_value.1 })
}

pub fn get_checksum(blocks: Blocks) -> Int {
  blocks
  |> get_content
  |> list.index_fold(0, fn (acc, curr, index) {
    case curr == -1 {
      True -> acc
      False -> acc + index * curr
    }
  })
}

pub fn part_1() {
  let assert Ok(disk_map) = "./data/day_9_test.txt"
  |> utils.read_lines
  |> list.first

  disk_map
  |> get_blocks
  |> get_content
  |> io.debug

  let defragmented_blocks = disk_map
  |> get_blocks
  |> defragment

  defragmented_blocks
  |> get_content
  |> io.debug

  defragmented_blocks
  |> get_checksum
  |> io.debug
}

pub fn part_2() {
  let assert Ok(disk_map) = "./data/day_9_test.txt"
  |> utils.read_lines
  |> list.first

  disk_map
  |> get_blocks
  |> io.debug

  disk_map
  |> get_blocks
  |> get_content
  |> io.debug

  // let defragmented_blocks = disk_map
  // |> get_blocks
  // |> defragment

  // defragmented_blocks
  // |> get_content
  // |> io.debug

  // defragmented_blocks
  // |> get_checksum
  // |> io.debug

}

pub fn main() {
  part_2()
}
