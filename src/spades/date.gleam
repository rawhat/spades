import gleam/dynamic
import gleam/int
import gleam/json.{type Json}
import gleam/list.{Continue, Stop}
import gleam/order.{type Order, Eq}
import gleam/result

pub type Date {
  Date(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int)
}

pub fn decoder() -> dynamic.Decoder(Date) {
  fn(dyn) {
    dyn
    |> dynamic.list(dynamic.int)
    |> result.then(fn(elements) {
      case elements {
        [year, month, day, hour, minute, second] ->
          Ok(Date(year, month, day, hour, minute, second))
        _ -> Error([dynamic.DecodeError("Date", "List(Int)", [])])
      }
    })
  }
}

pub fn from_string(date_string: String) -> Result(Date, Nil) {
  decoder()
  |> json.decode(date_string, _)
  |> result.replace_error(Nil)
}

pub fn add_days(date: Date, days: Int) -> Date {
  Date(..date, day: date.day + days)
}

type UniversalTime =
  #(#(Int, Int, Int), #(Int, Int, Int))

@external(erlang, "calendar", "universal_time")
fn universal_time() -> UniversalTime

pub fn now() -> Date {
  let #(#(year, month, day), #(hour, min, sec)) = universal_time()
  Date(year, month, day, hour, min, sec)
}

pub fn to_json(date: Date) -> Json {
  let Date(year, month, day, hour, min, sec) = date
  [year, month, day, hour, min, sec]
  |> json.array(json.int)
}

pub fn compare(left: Date, right: Date) -> Order {
  [
    #(left.year, right.year),
    #(left.month, right.month),
    #(left.day, right.day),
    #(left.hour, right.hour),
    #(left.minute, right.minute),
    #(left.second, right.second),
  ]
  |> list.fold_until(Eq, fn(_prev, next) {
    let #(left, right) = next
    case int.compare(left, right) {
      Eq -> Continue(Eq)
      ord -> Stop(ord)
    }
  })
}
