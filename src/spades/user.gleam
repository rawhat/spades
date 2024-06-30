import decode
import gleam/bit_array
import gleam/crypto.{Sha256}
import gleam/list
import gleam/pgo.{type Connection}
import gleam/result
import spades/date.{type Date}

pub type User {
  User(id: Int, username: String, password_hash: String, inserted_at: Date)
}

pub type PublicUser {
  PublicUser(id: Int, username: String, inserted_at: Date)
}

pub fn create(
  db: Connection,
  salt: String,
  username: String,
  password: String,
) -> Result(PublicUser, Nil) {
  let encoded =
    password
    |> bit_array.from_string
    |> crypto.sign_message(bit_array.from_string(salt), Sha256)

  use returned <- result.then(
    "insert into users (username, password_hash, created_at) values ($1, $2, now()) returning *"
    |> pgo.execute(db, [pgo.text(username), pgo.text(encoded)], decode.from(
      decoder(),
      _,
    ))
    |> result.replace_error(Nil),
  )

  let assert [user] = returned.rows

  user
  |> to_public
  |> Ok
}

pub fn list(db: Connection) -> Result(List(PublicUser), Nil) {
  "select id, username, password_hash, created_at from users"
  |> pgo.execute(db, [], decode.from(decoder(), _))
  |> result.map(fn(returned) { returned.rows })
  |> result.map(fn(rows) { list.map(rows, to_public) })
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

  "select id, username, password_hash, created_at from users where username = $1 and password_hash = $2"
  |> pgo.execute(db, [pgo.text(username), pgo.text(hashed)], decode.from(
    decoder(),
    _,
  ))
  |> result.replace_error(Nil)
  |> result.map(fn(resp) { resp.rows })
  |> result.then(list.first(_))
}

pub fn decoder() -> decode.Decoder(User) {
  decode.into({
    use id <- decode.parameter
    use username <- decode.parameter
    use password_hash <- decode.parameter
    use inserted_at <- decode.parameter
    User(id, username, password_hash, inserted_at)
  })
  |> decode.field(0, decode.int)
  |> decode.field(1, decode.string)
  |> decode.field(2, decode.string)
  |> decode.field(3, date.decoder())
}

fn to_public(user: User) -> PublicUser {
  PublicUser(
    id: user.id,
    username: user.username,
    inserted_at: user.inserted_at,
  )
}
