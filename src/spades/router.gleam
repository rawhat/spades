import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
import gleam/erlang/charlist.{Charlist}
import gleam/erlang/process.{Subject}
import gleam/http.{Get, Post}
import gleam/http/cookie
import gleam/http/request.{Request}
import gleam/http/response
import gleam/int
import gleam/json
import gleam/list
import gleam/map
import gleam/pair
import gleam/pgo
import gleam/result
import gleam/string
import mist/file
import mist/http.{BitBuilderBody, Body, FileBody} as mhttp
import mist/handler.{HandlerResponse, Response}
import mist/websocket
import spades/encoder
import spades/game_manager.{Join, Leave, ManagerAction, NewGame, Read}
import spades/games
import spades/socket/lobby.{GameUpdate, LobbyAction}
import spades/session.{Session, SessionAction, Validate}
import spades/user

pub type AppError {
  NotFound
}

pub type AppRequest {
  AppRequest(
    db: pgo.Connection,
    game_manager: Subject(ManagerAction),
    req: Request(Body),
    static_root: String,
    salt: String,
    lobby_manager: Subject(LobbyAction),
    session_manager: Subject(SessionAction),
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
  manager: Subject(ManagerAction),
  db: pgo.Connection,
  static_root: String,
  salt: String,
  session_manager: Subject(SessionAction),
  lobby_manager: Subject(LobbyAction),
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
            Response(_resp) -> session.add_cookie_header(resp, session)
            resp -> resp
          }
        })
      Error(Nil) -> next(req)
    }
  }
}

pub fn router(app_req: AppRequest) -> AppResult {
  // io.debug(#(
  //   "got a req",
  //   app_req.session,
  //   app_req.req.method,
  //   request.path_segments(app_req.req),
  // ))
  case app_req.req.method, request.path_segments(app_req.req) {
    Get, ["static", ..path] -> serve_static_file(path, app_req.static_root)
    Get, ["favicon.ico"] ->
      serve_static_file(["favicon.ico"], app_req.static_root)
    Post, ["api", "session"] -> {
      assert Ok(req) = mhttp.read_body(app_req.req)
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
        let value = session.new(user.id, user.username)
        process.send(app_req.session_manager, session.Add(user.id, value))
        json_response(200, session.to_json(value))
        |> session.add_cookie_header(value)
      })
      |> result.replace_error(empty_response(403))
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
        let value = session.new(public_user.id, public_user.username)
        process.send(
          app_req.session_manager,
          session.Add(public_user.id, value),
        )
        let resp =
          json.object([
            #("id", json.int(public_user.id)),
            #("username", json.string(public_user.username)),
          ])
          |> json.to_string
        json_response(200, resp)
        |> session.add_cookie_header(value)
      })
      |> result.replace_error(empty_response(403))
      |> result.unwrap_both
    }
    Get, ["api", "session"] ->
      with_authentication(
        app_req,
        fn() {
          app_req
          |> get_cookie_from_request
          |> result.map(fn(session) {
            json_response(200, session.to_json(session))
          })
          |> result.replace_error(empty_response(403))
          |> result.unwrap_both
        },
      )
    Get, ["api", "game"] ->
      with_authentication(
        app_req,
        fn() {
          app_req.game_manager
          |> games.list
          |> result.map(encoder.games_list)
          |> result.map(json_response(200, _))
          |> result.unwrap(empty_response(400))
        },
      )
    Post, ["api", "game"] ->
      with_authentication(
        app_req,
        fn() {
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
            process.send(app_req.lobby_manager, GameUpdate(new_game.game))
            let game =
              new_game
              |> game_manager.return_to_entry
              |> game_manager.game_entry_to_json
            Ok(json_response(200, game))
          }
          |> result.replace_error(empty_response(400))
          |> result.unwrap_both
        },
      )
    Get, ["api", "game", game_id] ->
      with_authentication(
        app_req,
        fn() {
          assert Ok(session) = app_req.session
          game_id
          |> int.parse
          |> result.then(games.read(app_req.game_manager, _, session.id))
          |> result.map(json.to_string)
          |> result.map(json_response(200, _))
          |> result.replace_error(empty_response(404))
          |> result.unwrap_both
        },
      )
    Get, ["socket", "lobby"] ->
      with_authentication(
        app_req,
        fn() {
          app_req.session
          |> result.map(fn(session) {
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
            |> handler.Upgrade
          })
          |> result.replace_error(empty_response(403))
          |> result.unwrap_both
        },
      )
    Get, ["socket", "game", id] ->
      with_authentication(
        app_req,
        fn() {
          {
            try id = int.parse(id)
            try session = app_req.session
            websocket.with_handler(fn(msg, _sender) {
              game_manager.handler(msg, app_req.game_manager, session)
            })
            |> websocket.on_init(fn(sender) {
              process.send(app_req.game_manager, Join(sender, id, session))
              assert Ok(game) =
                process.try_call(
                  app_req.game_manager,
                  Read(_, id, session.id),
                  60,
                )
              game
              |> json.to_string
              |> websocket.TextMessage
              |> websocket.send(sender, _)
              Nil
            })
            |> websocket.on_close(fn(_sender) {
              process.send(app_req.game_manager, Leave(id, session))
              Nil
            })
            |> handler.Upgrade
            |> Ok
          }
          |> result.replace_error(empty_response(403))
          |> result.unwrap_both
        },
      )
    Get, [] | Get, _ -> serve_static_file(["index.html"], app_req.static_root)
    _, _ -> empty_response(404)
  }
  |> Ok
}

fn with_authentication(
  req: AppRequest,
  handler: fn() -> HandlerResponse,
) -> HandlerResponse {
  req.session
  |> result.then(session.validate)
  |> result.replace_error(empty_response(403))
  |> result.map(fn(_ok) { handler() })
  |> result.unwrap_both
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
    ".svg" -> "image/svg+xml"
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
  |> Response
}

fn json_response(status: Int, data: String) -> HandlerResponse {
  status
  |> response.new
  |> response.set_body(BitBuilderBody(bit_builder.from_string(data)))
  |> response.prepend_header("content-type", "application/json")
  |> Response
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
  |> result.then(session.parse_cookie_header)
  |> result.then(fn(value) {
    process.try_call(
      app_req.session_manager,
      fn(caller) { Validate(caller, value.id) },
      500,
    )
    |> result.replace_error(Nil)
    |> result.flatten
    |> result.replace(value)
  })
}

fn get_json_body(
  app_req: AppRequest,
  decoder: dynamic.Decoder(a),
) -> Result(a, Nil) {
  app_req.req
  |> mhttp.read_body
  |> result.replace_error(Nil)
  |> result.map(fn(req) { req.body })
  |> result.then(bit_string.to_string)
  |> result.then(fn(body) {
    body
    |> json.decode(decoder)
    |> result.replace_error(Nil)
  })
}
