import gleam/dynamic/decode.{type Decoder}
import pog

pub type Date {
  Date(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int)
}

@external(erlang, "calendar", "universal_time")
fn do_now_date() -> #(#(Int, Int, Int), #(Int, Int, Int))

pub fn now_date() -> Date {
  let #(#(year, month, day), #(hour, minute, second)) = do_now_date()
  Date(year, month, day, hour, minute, second)
}

const epoch = Date(1970, 1, 1, 0, 0, 0)

pub fn row_decoder() -> Decoder(Date) {
  use date <- decode.field(0, pog.date_decoder())
  use time <- decode.field(1, pog.time_decoder())
  decode.success(Date(
    date.year,
    date.month,
    date.day,
    time.hours,
    time.minutes,
    time.seconds,
  ))
}

pub type Unit {
  Second
}

@external(erlang, "erlang", "system_time")
fn do_now(unit: Unit) -> Int

pub fn now() -> Int {
  do_now(Second)
}

pub fn json_decoder() -> Decoder(Date) {
  decode.list(decode.int)
  |> decode.then(fn(values) {
    case values {
      [year, month, day, hour, minute, second] -> {
        decode.success(Date(year, month, day, hour, minute, second))
      }
      _ -> decode.failure(epoch, "Invalid")
    }
  })
}

const hours_per_day = 24

const minutes_per_hour = 60

const seconds_per_minute = 60

pub fn add_days(date: Int, days: Int) -> Int {
  let total_seconds =
    days * hours_per_day * minutes_per_hour * seconds_per_minute
  date + total_seconds
}
