import gleam/base
import gleam/bit_string
import gleam/dynamic
import gleam/erlang/process.{Subject}
import gleam/http/response
import gleam/json
import gleam/map.{Map}
import gleam/order.{Gt}
import gleam/otp/actor
import gleam/result
import gleam/string
import mist/handler.{HandlerResponse, Response}
import spades/date.{Date}

pub type SessionAction {
  Add(id: Int, session: Session)
  Remove(id: Int)
  Validate(caller: Subject(Result(Nil, Nil)), id: Int)
}

pub type Session {
  Session(id: Int, username: String, expires_at: Date)
}

pub type SessionState {
  SessionState(users: Map(Int, Session))
}

pub fn start() -> Result(Subject(SessionAction), actor.StartError) {
  actor.start(
    SessionState(map.new()),
    fn(message, state) {
      case message {
        Add(id, session) ->
          session
          |> map.insert(state.users, id, _)
          |> SessionState
        Remove(id) -> SessionState(users: map.delete(state.users, id))
        Validate(caller, id) -> {
          let resp =
            state.users
            |> map.get(id)
            |> result.replace(Nil)
          process.send(caller, resp)
          state
        }
      }
      |> actor.Continue
    },
  )
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
  |> bit_string.from_string
  |> base.encode64(False)
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
  |> base.decode64
  |> result.then(bit_string.to_string)
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
  res: HandlerResponse,
  session: Session,
) -> HandlerResponse {
  let assert Response(resp) = res
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
  resp
  |> response.prepend_header("Set-Cookie", cookie)
  |> Response
}

pub fn validate(session: Session) -> Result(Nil, Nil) {
  case date.compare(session.expires_at, date.now()) {
    Gt -> Ok(Nil)
    _ -> Error(Nil)
  }
}
