import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
import gleam/erlang/charlist.{Charlist}
import gleam/http.{Get, Post}
import gleam/http/cookie
import gleam/http/request.{Request}
import gleam/http/response
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/map
import gleam/otp/process.{Sender}
import gleam/pair
import gleam/pgo
import gleam/result
import gleam/string
import mist/file
import mist/http.{BitBuilderBody, Body, FileBody, HandlerResponse, Response}
import mist/websocket
import spades/encoder
import spades/game_manager.{Join, Leave, ManagerAction, NewGame}
import spades/games
import spades/socket/lobby.{LobbyAction}
import spades/session.{Session, SessionAction, Validate}
import spades/user

pub type AppError {
  NotFound
}

pub type AppRequest {
  AppRequest(
    db: pgo.Connection,
    game_manager: Sender(ManagerAction),
    req: Request(Body),
    static_root: String,
    salt: String,
    lobby_manager: Sender(LobbyAction),
    session_manager: Sender(SessionAction),
    session: Result(Session, Nil),
  )
}

pub type AppResult =
  Result(HandlerResponse, AppError)

pub fn result_to_response(resp: AppResult) -> HandlerResponse {
  case resp {
    Ok(resp) -> resp
    Error(NotFound) -> empty_response(404)
  }
}

pub type Middleware(in1, out1, in2, out2) =
  fn(fn(in1) -> out1) -> fn(in2) -> out2

pub fn app_middleware(
  next: fn(AppRequest) -> AppResult,
  manager: Sender(ManagerAction),
  db: pgo.Connection,
  static_root: String,
  salt: String,
  session_manager: Sender(SessionAction),
  lobby_manager: Sender(LobbyAction),
) {
  fn(req) {
    let app_request =
      AppRequest(
        db,
        manager,
        req,
        static_root,
        salt,
        lobby_manager,
        session_manager,
        session: Error(Nil),
      )
    next(app_request)
  }
}

pub fn session_middleware(
  next: fn(AppRequest) -> AppResult,
) -> fn(AppRequest) -> AppResult {
  fn(req) {
    case get_cookie_from_request(req) {
      Ok(session) ->
        AppRequest(..req, session: Ok(session))
        |> next
        |> result.map(fn(resp) {
          case resp {
            http.Response(_resp) -> session.add_cookie_header(resp, session)
            resp -> resp
          }
        })
      Error(Nil) -> next(req)
    }
  }
}

pub fn router(app_req: AppRequest) -> AppResult {
  io.debug(#(
    "got a req",
    app_req.req.method,
    request.path_segments(app_req.req),
  ))
  case app_req.req.method, request.path_segments(app_req.req) {
    Get, ["static", ..path] -> serve_static_file(path, app_req.static_root)
    Get, ["api", "game"] ->
      app_req.game_manager
      |> games.list
      |> result.map(encoder.games_list)
      |> result.map(json_response(200, _))
      |> result.unwrap(empty_response(400))
    Post, ["api", "game"] -> {
      let decoder = dynamic.map(dynamic.string, dynamic.string)
      {
        try body = get_json_body(app_req, decoder)
        try game_name = map.get(body, "name")
        try session = app_req.session
        try new_game =
          process.try_call(
            app_req.game_manager,
            fn(caller) { NewGame(caller, session, game_name) },
            500,
          )
          |> result.replace_error(Nil)
        let game =
          new_game
          |> game_manager.return_to_entry
          |> game_manager.game_entry_to_json
        Ok(json_response(200, game))
      }
      |> result.replace_error(empty_response(400))
      |> result.unwrap_both
    }
    Post, ["api", "user"] -> {
      let decoder =
        dynamic.map(dynamic.string, dynamic.map(dynamic.string, dynamic.string))
      assert Ok(request_map) = get_json_body(app_req, decoder)
      // TODO:  probably make this a custom type?
      assert Ok(user_req) = map.get(request_map, "user")
      assert Ok(username) = map.get(user_req, "username")
      assert Ok(password) = map.get(user_req, "password")
      user.create(app_req.db, app_req.salt, username, password)
      |> result.map(fn(public_user) {
        let resp =
          json.object([
            #("id", json.int(public_user.id)),
            #("username", json.string(public_user.username)),
          ])
          |> json.to_string
        json_response(200, resp)
      })
      |> result.replace_error(empty_response(403))
      |> result.unwrap_both
    }
    Get, ["api", "session"] ->
      app_req
      |> get_cookie_from_request
      |> result.map(fn(session) { json_response(200, session.to_json(session)) })
      |> result.replace_error(empty_response(403))
      |> result.unwrap_both
    Post, ["api", "session"] -> {
      assert Ok(req) = http.read_body(app_req.req)
      assert Ok(body_string) = bit_string.to_string(req.body)
      assert Ok(request_map) =
        json.decode(
          body_string,
          dynamic.map(
            dynamic.string,
            dynamic.map(dynamic.string, dynamic.string),
          ),
        )
      // TODO:  probably make this a custom type?
      assert Ok(user_req) = map.get(request_map, "session")
      assert Ok(username) = map.get(user_req, "username")
      assert Ok(password) = map.get(user_req, "password")
      user.login(app_req.db, app_req.salt, username, password)
      |> result.map(fn(user) {
        let value = session.Session(user.id, user.username, user.password_hash)
        process.send(
          app_req.session_manager,
          session.Add(user.id, user.password_hash),
        )
        json_response(200, session.to_json(value))
      })
      |> result.map_error(fn(_err) { empty_response(403) })
      |> result.unwrap_both
    }
    Get, ["socket", "lobby"] ->
      app_req.session
      |> result.map(fn(session) {
        io.debug(#("got a session", session))
        websocket.with_handler(fn(_msg, _sender) { Ok(Nil) })
        |> websocket.on_init(fn(sender) {
          process.send(app_req.lobby_manager, lobby.Join(session, sender))
          assert Ok(games) = games.list(app_req.game_manager)
          games
          |> game_manager.game_entries_to_json
          |> websocket.TextMessage
          |> websocket.send(sender, _)
          Nil
        })
        |> websocket.on_close(fn(_sender) {
          process.send(app_req.lobby_manager, lobby.Leave(session.id))
          Nil
        })
        |> http.Upgrade
      })
      |> result.replace_error(empty_response(403))
      |> result.unwrap_both
    Get, ["socket", "game", id] ->
      {
        try id = int.parse(id)
        try session = app_req.session
        websocket.with_handler(fn(_msg, _sender) { Ok(Nil) })
        |> websocket.on_init(fn(sender) {
          process.send(app_req.game_manager, Join(id, sender, session))
          Nil
        })
        |> websocket.on_close(fn(_sender) {
          process.send(app_req.game_manager, Leave(id, session))
          Nil
        })
        |> http.Upgrade
        |> Ok
      }
      |> result.replace_error(empty_response(403))
      |> result.unwrap_both
    Get, ["favicon.ico"] ->
      serve_static_file(["favicon.ico"], app_req.static_root)
    Get, [] | Get, _ -> serve_static_file(["index.html"], app_req.static_root)
    _, _ -> empty_response(404)
  }
  |> Ok
}

external fn do_file_extension(name: Charlist) -> Charlist =
  "filename" "extension"

fn file_extension(name: String) -> String {
  let erl_name = charlist.from_string(name)
  let ext = do_file_extension(erl_name)
  charlist.to_string(ext)
}

fn content_type_from_extension(path: String) -> String {
  case file_extension(path) {
    ".html" -> "text/html"
    ".css" -> "text/css"
    ".js" -> "application/javascript"
    _ -> "application/octet-stream"
  }
}

fn serve_static_file(path: List(String), root: String) -> HandlerResponse {
  let not_found =
    response.new(404)
    |> response.set_body(BitBuilderBody(bit_builder.new()))
    |> Response

  let full_path =
    path
    |> string.join("/")
    |> string.append("/", _)
    |> string.append(root, _)

  let file_path = bit_string.from_string(full_path)

  case file.open(file_path) {
    Error(_) -> not_found
    Ok(fd) -> {
      let size = file.size(file_path)
      let content_type = content_type_from_extension(full_path)
      response.new(200)
      |> response.set_body(FileBody(fd, content_type, 0, size))
      |> Response
    }
  }
}

fn empty_response(status: Int) -> HandlerResponse {
  status
  |> response.new
  |> response.set_body(BitBuilderBody(bit_builder.new()))
  |> http.Response
}

fn json_response(status: Int, data: String) -> HandlerResponse {
  status
  |> response.new
  |> response.set_body(BitBuilderBody(bit_builder.from_string(data)))
  |> response.prepend_header("content-type", "application/json")
  |> http.Response
}

fn get_cookie_from_request(app_req: AppRequest) -> Result(session.Session, Nil) {
  app_req.req
  |> request.get_header("cookie")
  |> result.map(cookie.parse)
  |> result.then(fn(cookies) {
    list.find(
      cookies,
      fn(p) {
        case p {
          #("session", _session) -> True
          _ -> False
        }
      },
    )
  })
  |> result.map(pair.second)
  |> result.then(session.read_cookie_header)
  |> result.then(fn(value) {
    process.try_call(
      app_req.session_manager,
      fn(caller) { Validate(caller, value.id, value.password) },
      500,
    )
    |> result.replace(value)
    |> result.replace_error(Nil)
  })
}

fn get_json_body(
  app_req: AppRequest,
  decoder: dynamic.Decoder(a),
) -> Result(a, Nil) {
  app_req.req
  |> http.read_body
  |> result.replace_error(Nil)
  |> result.map(fn(req) { req.body })
  |> result.then(bit_string.to_string)
  |> result.then(fn(body) {
    body
    |> json.decode(decoder)
    |> result.replace_error(Nil)
  })
}
