import decode.{type Decoder}
import gleam/float
import gleam/int
import gleam/json.{type Json}
import gleam/list.{Continue, Stop}
import gleam/order.{type Order, Eq}
import gleam/result

pub type Date {
  Date(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int)
}

pub fn row_decoder() -> Decoder(Date) {
  let ymd_decoder =
    decode.into({
      use year <- decode.parameter
      use month <- decode.parameter
      use day <- decode.parameter
      #(year, month, day)
    })
    |> decode.field(0, decode.int)
    |> decode.field(1, decode.int)
    |> decode.field(2, decode.int)

  let hms_decoder =
    decode.into({
      use hour <- decode.parameter
      use minute <- decode.parameter
      use second <- decode.parameter
      #(hour, minute, second)
    })
    |> decode.field(0, decode.int)
    |> decode.field(1, decode.int)
    |> decode.field(2, decode.float)

  decode.into({
    use #(year, month, day) <- decode.parameter
    use #(hour, minute, second) <- decode.parameter
    Date(year, month, day, hour, minute, float.round(second))
  })
  |> decode.field(0, ymd_decoder)
  |> decode.field(1, hms_decoder)
}

pub fn json_decoder() -> Decoder(Date) {
  decode.into({
    use year <- decode.parameter
    use month <- decode.parameter
    use day <- decode.parameter
    use hour <- decode.parameter
    use minute <- decode.parameter
    use second <- decode.parameter
    Date(year, month, day, hour, minute, second)
  })
  |> decode.field(0, decode.int)
  |> decode.field(1, decode.int)
  |> decode.field(2, decode.int)
  |> decode.field(3, decode.int)
  |> decode.field(4, decode.int)
  |> decode.field(5, decode.int)
}

pub fn from_string(date_string: String) -> Result(Date, Nil) {
  decode.from(json_decoder(), _)
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
