import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/time/calendar.{
  type Date, type Month, type TimeOfDay, Date, TimeOfDay,
}
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}
import pog

pub type DateTime {
  DateTime(date: Date, time: TimeOfDay)
}

pub fn convert_month(value: Int) -> Month {
  case value {
    1 -> calendar.January
    2 -> calendar.February
    3 -> calendar.March
    4 -> calendar.April
    5 -> calendar.May
    6 -> calendar.June
    7 -> calendar.July
    8 -> calendar.August
    9 -> calendar.September
    10 -> calendar.October
    11 -> calendar.November
    12 -> calendar.December
    _ -> panic as { "month outside of range: " <> int.to_string(value) }
  }
}

pub fn row_decoder() -> Decoder(DateTime) {
  use date <- decode.field(0, pog.date_decoder())
  use time <- decode.field(1, pog.time_decoder())
  decode.success(DateTime(
    Date(date.year, convert_month(date.month), date.day),
    TimeOfDay(time.hours, time.minutes, time.seconds, 0),
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

const hours_per_day = 24

const minutes_per_hour = 60

const seconds_per_minute = 60

pub fn add_days(date: Timestamp, days: Int) -> Timestamp {
  let total_seconds =
    days * hours_per_day * minutes_per_hour * seconds_per_minute
  timestamp.add(date, duration.seconds(total_seconds))
}
