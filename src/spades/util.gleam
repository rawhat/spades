import gleam/list
import gleam/pair

pub fn partition(items: List(a), func: fn(a) -> Bool) -> tuple(List(a), List(a)) {
  items
  |> list.fold(
    tuple(list.new(), list.new()),
    fn(item, acc) {
      case func(item) {
        True ->
          acc
          |> pair.first
          |> list.append([item])
          |> fn(new) { tuple(new, pair.second(acc)) }
        _ ->
          acc
          |> pair.second
          |> list.append([item])
          |> fn(new) { tuple(pair.first(acc), new) }
      }
    },
  )
}
