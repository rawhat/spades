import gleam/dynamic/decode
import gleam/result
import gleam/string
import logging
import pog
import spades/database

pub fn main() -> Result(Nil, Nil) {
  let db = database.initialize()

  run(
    db,
    "create_users_table",
    "create table if not exists users (
        id serial primary key,
        username text unique not null,
        password_hash text not null,
        created_at timestamp not null
      )",
  )
}

fn run(db: pog.Connection, name: String, sql: String) -> Result(Nil, Nil) {
  logging.log(logging.Info, string.concat(["Running migration `", name, "`"]))
  sql
  |> pog.query
  |> pog.returning(decode.dynamic)
  |> pog.execute(db)
  |> result.replace_error(Nil)
  |> result.replace(Nil)
}
