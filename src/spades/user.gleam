import gleam/bit_string
import gleam/dynamic.{Decoder}
import gleam/erlang/atom.{Atom}
import gleam/list
import gleam/pgo.{Connection}
import gleam/result
import gleam/io

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
  let encoded = hash_password(password, salt)

  try returned =
    "insert into users (username, password_hash, created_at) values ($1, $2, now()) returning *"
    |> pgo.execute(db, [pgo.text(username), pgo.text(encoded)], decoder())
    |> result.replace_error(Nil)

  assert [user] = returned.rows

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
  let hashed = hash_password(password, salt)
  io.debug(#("selecting", username, hashed))

  try response =
    "select id, username, password_hash, created_at from users where username = $1 and password_hash = $2"
    |> pgo.execute(db, [pgo.text(username), pgo.text(hashed)], decoder())
    |> result.replace_error(Nil)

  response.rows
  |> list.at(0)
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

type DoPbkdf2Hmac =
  fn(Atom, BitString, BitString, Int) -> BitString

external fn do_pbkdf2_hmac(
  type_: Atom,
  sub_type: Atom,
  key: BitString,
  data: BitString,
  length: Int,
) -> BitString =
  "crypto" "macN"

fn pbkdf2_hmac(
  type_: Atom,
  key: BitString,
  data: BitString,
  length: Int,
) -> BitString {
  let hmac = atom.create_from_string("hmac")
  do_pbkdf2_hmac(hmac, type_, key, data, length)
}

pub external fn pbkdf2(
  pass: BitString,
  salt: BitString,
  count: Int,
  length: Int,
  func: DoPbkdf2Hmac,
  type_: Atom,
  mac_length: Int,
) -> BitString =
  "pubkey_pbe" "pbdkdf2"

fn hash_password(password: String, salt: String) -> String {
  let pw = bit_string.from_string(password)
  let salt = bit_string.from_string(salt)
  let sha = atom.create_from_string("sha")
  assert Ok(hashed) =
    pbkdf2(pw, salt, 4096, 20, pbkdf2_hmac, sha, 20)
    |> base64_encode
    |> bit_string.to_string
  hashed
}

external fn base64_encode(bs: BitString) -> BitString =
  "base64" "encode"

external fn base64_decode(bs: BitString) -> BitString =
  "base64" "decode"
