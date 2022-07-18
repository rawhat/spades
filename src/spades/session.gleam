import gleam/bit_string
import gleam/dynamic
import gleam/erlang/charlist.{Charlist}
import gleam/http/response
import gleam/json
import gleam/map.{Map}
import gleam/otp/actor
import gleam/otp/process.{Sender}
import gleam/result
import gleam/string
import mist/http.{HandlerResponse, Response}
import spades/user.{base64_decode, base64_encode}

pub type SessionAction {
  Add(id: Int, pass: String)
  Remove(id: Int)
  Validate(caller: Sender(Result(Nil, Nil)), id: Int, pass: String)
}

pub type SessionState {
  SessionState(users: Map(Int, String))
}

pub fn start() -> Result(Sender(SessionAction), actor.StartError) {
  actor.start(
    SessionState(map.new()),
    fn(message, state) {
      case message {
        Add(id, pass) -> SessionState(users: map.insert(state.users, id, pass))
        Remove(id) -> SessionState(users: map.delete(state.users, id))
        Validate(caller, id, pass) -> {
          let resp =
            state.users
            |> map.get(id)
            |> result.then(fn(hashed) {
              case hashed == pass {
                True -> Ok(Nil)
                False -> Error(Nil)
              }
            })
          process.send(caller, resp)
          state
        }
      }
      |> actor.Continue
    },
  )
}

pub type Session {
  Session(id: Int, username: String, password: String)
}

fn to_string(session: Session) -> String {
  assert Ok(str) =
    json.object([
      #("id", json.int(session.id)),
      #("username", json.string(session.username)),
      #("password", json.string(session.password)),
    ])
    |> json.to_string
    |> bit_string.from_string
    |> base64_encode
    |> bit_string.to_string

  str
}

pub fn to_json(session: Session) -> String {
  json.object([
    #(
      "session",
      json.object([
        #("id", json.int(session.id)),
        #("username", json.string(session.username)),
        #("password", json.string(session.password)),
      ]),
    ),
  ])
  |> json.to_string
}

fn parse(str: String) -> Result(Session, Nil) {
  str
  |> bit_string.from_string
  |> base64_decode
  |> bit_string.to_string
  |> result.then(fn(str) {
    str
    |> json.decode(dynamic.decode3(
      Session,
      dynamic.field("id", dynamic.int),
      dynamic.field("username", dynamic.string),
      dynamic.field("password", dynamic.string),
    ))
    |> result.replace_error(Nil)
  })
}

pub fn add_cookie_header(
  res: HandlerResponse,
  session: Session,
) -> HandlerResponse {
  assert Response(resp) = res
  let cookie =
    string.concat([
      "session=",
      to_string(session),
      "; Path=/",
      "; Expires=",
      one_week_from_now(),
      "; HttpOnly; SameSite=Strict",
    ])
  resp
  |> response.prepend_header("Set-Cookie", cookie)
  |> Response
}

pub fn read_cookie_header(cookie: String) -> Result(Session, Nil) {
  parse(cookie)
}

pub fn one_week_from_now() -> String {
  let #(#(year, month, day), #(hour, min, sec)) = universal_time()

  #(#(year, month, day + 7), #(hour, min, sec))
  |> iso8601_format
}

type UniversalTime =
  #(#(Int, Int, Int), #(Int, Int, Int))

external fn universal_time() -> UniversalTime =
  "calendar" "universal_time"

external fn iolib_format(String, List(a)) -> Charlist =
  "io_lib" "format"

fn iso8601_format(ut: UniversalTime) -> String {
  let #(#(year, month, day), #(hour, min, sec)) = ut
  iolib_format(
    "~.4.0w-~.2.0w-~.2.0wT~.2.0w:~.2.0w:~.2.0wZ",
    [year, month, day, hour, min, sec],
  )
  |> charlist.to_string
}
