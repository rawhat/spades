import gleam/bit_array
import gleam/crypto.{Sha256}
import gleam/dynamic/decode.{type Decoder}
import gleam/list
import gleam/result
import pog.{type Connection}
import spades/date.{type Date}

pub type User {
  User(id: Int, username: String, inserted_at: Date)
}

fn decoder() -> Decoder(User) {
  use id <- decode.field(0, decode.int)
  use username <- decode.field(1, decode.string)
  use inserted_at <- decode.field(2, date.row_decoder())
  decode.success(User(id, username, inserted_at))
}

pub fn create(
  db: Connection,
  salt: String,
  username: String,
  password: String,
) -> Result(User, Nil) {
  let encoded =
    password
    |> bit_array.from_string
    |> crypto.sign_message(bit_array.from_string(salt), Sha256)

  use returned <- result.then(
    "insert into users (username, password_hash, created_at) values ($1, $2, now()) returning id, username, created_at"
    |> pog.query
    |> pog.parameter(pog.text(username))
    |> pog.parameter(pog.text(encoded))
    |> pog.returning(decoder())
    |> pog.execute(db)
    |> result.replace_error(Nil),
  )

  let assert [user] = returned.rows

  Ok(user)
}

pub fn list(db: Connection) -> Result(List(User), Nil) {
  "select id, username, created_at from users"
  |> pog.query
  |> pog.returning(decoder())
  |> pog.execute(db)
  |> result.map(fn(returned) { returned.rows })
  |> result.replace_error(Nil)
}

pub fn login(
  db: Connection,
  salt: String,
  username: String,
  password: String,
) -> Result(User, Nil) {
  let hashed =
    password
    |> bit_array.from_string
    |> crypto.sign_message(bit_array.from_string(salt), Sha256)

  "select id, username, created_at from users where username = $1 and password_hash = $2"
  |> pog.query
  |> pog.parameter(pog.text(username))
  |> pog.parameter(pog.text(hashed))
  |> pog.returning(decoder())
  |> pog.execute(db)
  |> result.replace_error(Nil)
  |> result.map(fn(resp) { resp.rows })
  |> result.then(list.first(_))
}
