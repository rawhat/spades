import gleam/list
import gleam/option
import gleam/pair
import gleam/result

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

pub fn drop_while(items: List(a), func: fn(a) -> Bool) -> List(a) {
  let res =
    items
    |> list.head
    |> result.map(fn(item) { func(item) == True })
    |> result.unwrap(False)
  case tuple(res, list.tail(items)) {
    tuple(True, Ok(rest)) -> drop_while(rest, func)
    tuple(False, _) -> items
  }
}

pub external fn random_float() -> Float =
  "rand" "uniform"

pub external fn keysort(
  index: Int,
  items: List(tuple(Float, a)),
) -> List(tuple(Float, a)) =
  "lists" "keysort"

pub fn shuffle(items: List(a)) -> List(a) {
  let randomized =
    items
    |> list.fold(
      list.new(),
      fn(item, acc) { [tuple(random_float(), item), ..acc] },
    )
  keysort(1, randomized)
  |> list.map(fn(t) { pair.second(t) })
}
