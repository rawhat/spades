import gleam/bit_builder
import gleam/bit_string
import gleam/dynamic
import gleam/erlang/charlist.{Charlist}
import gleam/http.{Get, Post}
import gleam/http/cookie
import gleam/http/request.{Request}
import gleam/http/response
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
import spades/game_manager.{ManagerAction}
import spades/games
import spades/session.{SessionAction, Validate}
import spades/user

pub type AppError {
  NotFound
}

pub type AppRequest {
  AppRequest(
    db: pgo.Connection,
    manager: Sender(ManagerAction),
    req: Request(Body),
    static_root: String,
    salt: String,
    session_manager: Sender(SessionAction),
  )
}

pub type AppResult =
  Result(HandlerResponse, AppError)

pub fn result_to_response() -> Middleware(
  AppRequest,
  AppResult,
  AppRequest,
  HandlerResponse,
) {
  fn(next) {
    fn(req) {
      case next(req) {
        Ok(resp) -> resp
        Error(NotFound) -> empty_response(404)
      }
    }
  }
}

pub type Middleware(in1, out1, in2, out2) =
  fn(fn(in1) -> out1) -> fn(in2) -> out2

pub fn app_middleware(
  manager: Sender(ManagerAction),
  db: pgo.Connection,
  static_root: String,
  salt: String,
  session_manager: Sender(SessionAction),
) -> Middleware(AppRequest, HandlerResponse, Request(Body), HandlerResponse) {
  fn(next) {
    fn(req) {
      let app_request =
        AppRequest(db, manager, req, static_root, salt, session_manager)
      next(app_request)
    }
  }
}

pub fn router(app_req: AppRequest) -> AppResult {
  case app_req.req.method, request.path_segments(app_req.req) {
    Get, ["static", ..path] -> serve_static_file(path, app_req.static_root)
    Get, ["api", "game"] ->
      app_req.manager
      |> games.list
      |> result.map(encoder.games_list)
      |> result.map(json_response(200, _))
      |> result.unwrap(empty_response(400))
    Post, ["api", "user"] -> {
      // TODO:  make this a function?  at least most of it
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
        |> result.map(fn(_ok) {
          json_response(200, session.to_json(value))
          |> session.add_cookie_header(value)
        })
        |> result.replace_error(Nil)
      })
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
        |> session.add_cookie_header(session.Session(
          user.id,
          user.username,
          user.password_hash,
        ))
      })
      |> result.map_error(fn(_err) { empty_response(403) })
      |> result.unwrap_both
    }
    Get, ["socket", "lobby", "websocket"] -> {
      io.debug(#("upgrading", app_req.req))
      websocket.with_handler(fn(msg, sender) {
        io.debug(#("got a msg", msg))
        Ok(Nil)
      })
      |> websocket.on_init(fn(sender) {
        io.debug(#("init lobby"))
        Nil
      })
      |> websocket.on_close(fn(sender) {
        io.debug(#("close lobby"))
        Nil
      })
      |> http.Upgrade
    }
    Get, ["socket", "game", "websocket"] -> {
      io.debug(#("upgrading", app_req.req))
      websocket.with_handler(fn(msg, sender) {
        io.debug(#("got a msg", msg))
        Ok(Nil)
      })
      |> websocket.on_init(fn(sender) {
        io.debug(#("init lobby"))
        Nil
      })
      |> websocket.on_close(fn(sender) {
        io.debug(#("close lobby"))
        Nil
      })
      |> http.Upgrade
    }
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
