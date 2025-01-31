import envoy
import gleam/int
import gleam/option.{Some}
import gleam/result
import pog

fn get_db_config() -> pog.Config {
  let db_host =
    "PGHOST"
    |> envoy.get
    |> result.unwrap("localhost")
  let db_user =
    "PGUSER"
    |> envoy.get
    |> result.unwrap("spades")
  let db_pass =
    "PGPASS"
    |> envoy.get
    |> result.unwrap("spades")
  let db_port =
    "PGPORT"
    |> envoy.get
    |> result.then(int.parse)
    |> result.unwrap(5432)
  let db_name =
    "PGDATABASE"
    |> envoy.get
    |> result.unwrap("spades_dev")

  pog.Config(
    ..pog.default_config(),
    database: db_name,
    host: db_host,
    user: db_user,
    password: Some(db_pass),
    port: db_port,
    pool_size: 15,
  )
}

pub fn initialize() -> pog.Connection {
  get_db_config()
  |> pog.connect
}
