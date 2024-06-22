import gleam/bit_array
import gleam/crypto.{Sha256}
import gleam/dynamic.{type Decoder}
import gleam/list
import gleam/pgo.{type Connection}
import gleam/result

pub type User {
  User(
    id: Int,
    username: String,
    password_hash: String,
    inserted_at: dynamic.Dynamic,
  )
}

pub type PublicUser {
  PublicUser(id: Int, username: String, inserted_at: dynamic.Dynamic)
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
    |> pgo.execute(db, [pgo.text(username), pgo.text(encoded)], decoder())
    |> result.replace_error(Nil),
  )

  let assert [user] = returned.rows

  user
  |> to_public
  |> Ok
}

pub fn list(db: Connection) -> Result(List(PublicUser), Nil) {
  "select id, username, password_hash, created_at from users"
  |> pgo.execute(db, [], decoder())
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
  |> pgo.execute(db, [pgo.text(username), pgo.text(hashed)], decoder())
  |> result.replace_error(Nil)
  |> result.map(fn(resp) { resp.rows })
  |> result.then(list.first(_))
}

pub fn decoder() -> Decoder(User) {
  dynamic.decode4(
    User,
    dynamic.element(0, dynamic.int),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, dynamic.string),
    // TODO:  date
    dynamic.element(3, dynamic.dynamic),
  )
}

fn to_public(user: User) -> PublicUser {
  PublicUser(
    id: user.id,
    username: user.username,
    inserted_at: user.inserted_at,
  )
}
