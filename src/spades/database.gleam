import gleam/dynamic
import gleam/erlang/os
import gleam/int
import gleam/option.{Some}
import gleam/pgo
import gleam/result

fn get_db_config() -> pgo.Config {
  let db_host =
    "DB_HOST"
    |> os.get_env
    |> result.unwrap("localhost")
  let db_user =
    "DB_USER"
    |> os.get_env
    |> result.unwrap("spades")
  let db_pass =
    "DB_PASS"
    |> os.get_env
    |> result.unwrap("spades")
  let db_port =
    "DB_PORT"
    |> os.get_env
    |> result.then(int.parse)
    |> result.unwrap(5432)
  let db_name =
    "DB_NAME"
    |> os.get_env
    |> result.unwrap("spades_dev")

  pgo.Config(
    ..pgo.default_config(),
    database: db_name,
    host: db_host,
    user: db_user,
    password: Some(db_pass),
    port: db_port,
    pool_size: 15,
  )
}

pub fn initialize() -> pgo.Connection {
  get_db_config()
  |> pgo.connect
}

// TODO:  errors
pub fn migrate(db: pgo.Connection) -> Result(Nil, Nil) {
  try _ =
    run(
      db,
      "create_users_table",
      "create table if not exists users (
        id serial primary key,
        username text,
        password_hash text,
        created_at timestamp
      )"
    )

  Ok(Nil)
}

// TODO:  logger
import gleam/io
import gleam/string
fn run(db: pgo.Connection, name: String, sql: String) -> Result(Nil, Nil) {
  io.println(string.concat(["Running migration `", name, "`"]))
  pgo.execute(sql, db, [], dynamic.dynamic)
  |> io.debug
  |> result.replace_error(Nil)
  |> result.replace(Nil)
}
