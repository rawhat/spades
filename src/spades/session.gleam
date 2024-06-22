import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/erlang/process.{type Subject}
import gleam/http/response.{type Response}
import gleam/json
import gleam/order.{Gt}
import gleam/otp/actor
import gleam/result
import gleam/string
import mist.{type ResponseData}
import spades/date.{type Date}

pub type SessionAction {
  Add(id: Int, session: Session)
  Remove(id: Int)
  Validate(caller: Subject(Result(Nil, Nil)), id: Int)
}

pub type Session {
  Session(id: Int, username: String, expires_at: Date)
}

pub type SessionState {
  SessionState(users: Dict(Int, Session))
}

pub fn start() -> Result(Subject(SessionAction), actor.StartError) {
  actor.start(SessionState(dict.new()), fn(message, state) {
    case message {
      Add(id, session) ->
        session
        |> dict.insert(state.users, id, _)
        |> SessionState
      Remove(id) -> SessionState(users: dict.delete(state.users, id))
      Validate(caller, id) -> {
        let resp =
          state.users
          |> dict.get(id)
          |> result.replace(Nil)
        process.send(caller, resp)
        state
      }
    }
    |> actor.continue
  })
}

pub fn new(id: Int, username: String) -> Session {
  date.now()
  |> date.add_days(7)
  |> Session(id, username, _)
}

fn to_string(session: Session) -> String {
  json.object([
    #("id", json.int(session.id)),
    #("username", json.string(session.username)),
    #("expires_at", date.to_json(session.expires_at)),
  ])
  |> json.to_string
  |> bit_array.from_string
  |> bit_array.base64_encode(False)
}

pub fn to_json(session: Session) -> String {
  json.object([
    #(
      "session",
      json.object([
        #("id", json.int(session.id)),
        #("username", json.string(session.username)),
      ]),
    ),
  ])
  |> json.to_string
}

pub fn parse_cookie_header(str: String) -> Result(Session, Nil) {
  str
  |> bit_array.base64_decode
  |> result.then(bit_array.to_string)
  |> result.then(fn(str) {
    str
    |> json.decode(dynamic.decode3(
      Session,
      dynamic.field("id", dynamic.int),
      dynamic.field("username", dynamic.string),
      dynamic.field("expires_at", date.decoder()),
    ))
    |> result.replace_error(Nil)
  })
}

pub fn add_cookie_header(
  res: Response(ResponseData),
  session: Session,
) -> Response(ResponseData) {
  let expiry =
    session.expires_at
    |> date.to_json()
    |> json.to_string
  let cookie =
    string.concat([
      "session=",
      to_string(session),
      "; Path=/",
      "; Expires=",
      expiry,
      "; HttpOnly; SameSite=Strict",
    ])
  response.prepend_header(res, "Set-Cookie", cookie)
}

pub fn validate(session: Session) -> Result(Nil, Nil) {
  case date.compare(session.expires_at, date.now()) {
    Gt -> Ok(Nil)
    _ -> Error(Nil)
  }
}
