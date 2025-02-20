import gleam/bit_array
import gleam/bytes_tree
import gleam/dynamic/decode.{type Decoder}
import gleam/erlang/charlist.{type Charlist}
import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/http.{Get, Post}
import gleam/http/cookie
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import gleam/pair
import gleam/result
import gleam/string
import mist.{type Connection, type ResponseData, Custom, Text}
import pog
import spades/encoder
import spades/game_manager.{type ManagerAction, Join, Leave, NewGame, Read}
import spades/games
import spades/session.{type Session, type SessionAction, Validate}
import spades/socket/lobby.{type LobbyAction, GameUpdate}
import spades/user

pub type AppError {
  NotFound
}

pub type AppRequest {
  AppRequest(
    db: pog.Connection,
    game_manager: Subject(ManagerAction),
    req: Request(Connection),
    static_root: String,
    salt: String,
    lobby_manager: Subject(LobbyAction),
    session_manager: Subject(SessionAction),
    session: Result(Session, Nil),
  )
}

pub type AppResult =
  Result(Response(ResponseData), AppError)

pub fn result_to_response(handler: fn() -> AppResult) -> Response(ResponseData) {
  case handler() {
    Ok(resp) -> resp
    Error(NotFound) -> empty_response(404)
  }
}

pub fn app_middleware(
  req: Request(Connection),
  manager: Subject(ManagerAction),
  db: pog.Connection,
  static_root: String,
  salt: String,
  session_manager: Subject(SessionAction),
  lobby_manager: Subject(LobbyAction),
  next: fn(AppRequest) -> AppResult,
) -> AppResult {
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

pub fn session_middleware(
  req: AppRequest,
  next: fn(AppRequest) -> AppResult,
) -> AppResult {
  case get_cookie_from_request(req) {
    Ok(session) ->
      AppRequest(..req, session: Ok(session))
      |> next
      |> result.map(session.add_cookie_header(_, session))
    Error(Nil) -> next(req)
  }
}

pub fn router(app_req: AppRequest) -> AppResult {
  case app_req.req.method, request.path_segments(app_req.req) {
    Get, ["assets" as start, ..path] | Get, ["images" as start, ..path] ->
      serve_static_file([start, ..path], app_req.static_root)
    Get, ["favicon.ico"] ->
      serve_static_file(["favicon.ico"], app_req.static_root)
    Post, ["api", "session"] -> {
      let assert Ok(req) = mist.read_body(app_req.req, 1024 * 1024 * 10)
      let assert Ok(body_string) = bit_array.to_string(req.body)
      let decoder = decode.at(["session"], session.login_decoder())
      let assert Ok(login_request) = json.parse(body_string, decoder)
      user.login(
        app_req.db,
        app_req.salt,
        login_request.username,
        login_request.password,
      )
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
      let decoder = decode.at(["user"], session.login_decoder())
      let assert Ok(login_request) = get_json_body(app_req, decoder)
      user.create(
        app_req.db,
        app_req.salt,
        login_request.username,
        login_request.password,
      )
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
    Get, ["api", "session"] -> {
      use <- with_authentication(app_req)
      app_req
      |> get_cookie_from_request
      |> result.map(fn(session) { json_response(200, session.to_json(session)) })
      |> result.replace_error(empty_response(403))
      |> result.unwrap_both
    }
    Get, ["api", "game"] -> {
      use <- with_authentication(app_req)
      app_req.game_manager
      |> games.list
      |> result.map(encoder.games_list)
      |> result.map(json_response(200, _))
      |> result.unwrap(empty_response(400))
    }
    Post, ["api", "game"] -> {
      use <- with_authentication(app_req)
      let game_name_decoder = {
        use name <- decode.field("name", decode.string)
        decode.success(name)
      }
      {
        use game_name <- result.then(get_json_body(app_req, game_name_decoder))
        use session <- result.then(app_req.session)
        use new_game <- result.then(
          process.try_call(
            app_req.game_manager,
            fn(caller) { NewGame(caller, session, game_name) },
            500,
          )
          |> result.replace_error(Nil),
        )
        process.send(app_req.lobby_manager, GameUpdate(new_game.game))
        let game =
          new_game
          |> game_manager.return_to_entry
          |> game_manager.game_entry_to_json
        Ok(json_response(200, game))
      }
      |> result.replace_error(empty_response(400))
      |> result.unwrap_both
    }
    Get, ["api", "game", game_id] -> {
      use <- with_authentication(app_req)
      let assert Ok(session) = app_req.session
      game_id
      |> int.parse
      |> result.then(games.read(app_req.game_manager, _, session.id))
      |> result.map(json.to_string)
      |> result.map(json_response(200, _))
      |> result.replace_error(empty_response(404))
      |> result.unwrap_both
    }
    Get, ["socket", "lobby"] -> {
      use <- with_authentication(app_req)
      app_req.session
      |> result.map(fn(session) {
        mist.websocket(
          request: app_req.req,
          on_init: fn(conn) {
            let subj = process.new_subject()
            let selector =
              process.new_selector()
              |> process.selecting(subj, function.identity)
            process.send(app_req.lobby_manager, lobby.Join(session, subj))
            let assert Ok(games) = games.list(app_req.game_manager)
            let _ =
              games
              |> game_manager.game_entries_to_json
              |> mist.send_text_frame(conn, _)
            #(Nil, Some(selector))
          },
          handler: fn(state, _conn, _msg) { actor.continue(state) },
          on_close: fn(_state) {
            process.send(app_req.lobby_manager, lobby.Leave(session.id))
            Nil
          },
        )
      })
      |> result.replace_error(empty_response(403))
      |> result.unwrap_both
    }
    Get, ["socket", "game", id] -> {
      use <- with_authentication(app_req)
      {
        use id <- result.then(int.parse(id))
        use session <- result.then(app_req.session)
        mist.websocket(
          request: app_req.req,
          on_init: fn(conn) {
            let subj = process.new_subject()
            process.send(app_req.game_manager, Join(subj, id, session))
            let assert Ok(game) =
              process.try_call(
                app_req.game_manager,
                Read(_, id, session.id),
                60,
              )
            let _ =
              game
              |> json.to_string
              |> mist.send_text_frame(conn, _)
            let selector =
              process.new_selector()
              |> process.selecting(subj, function.identity)
            #(Nil, Some(selector))
          },
          handler: fn(state, conn, msg) {
            case msg {
              Custom(game_manager.Send(data)) -> {
                let _ = mist.send_text_frame(conn, data)
                actor.continue(state)
              }
              Text(data) -> {
                let _ =
                  game_manager.handle_message(
                    data,
                    app_req.game_manager,
                    session,
                  )
                actor.continue(state)
              }
              mist.Binary(_) -> actor.continue(state)
              mist.Closed | mist.Shutdown -> actor.Stop(process.Normal)
            }
          },
          on_close: fn(_state) {
            process.send(app_req.game_manager, Leave(id, session))
            Nil
          },
        )
        |> Ok
      }
      |> result.replace_error(empty_response(403))
      |> result.unwrap_both
    }
    Get, [] | Get, _ -> serve_static_file(["index.html"], app_req.static_root)
    _, _ -> empty_response(404)
  }
  |> Ok
}

fn with_authentication(
  req: AppRequest,
  handler: fn() -> Response(ResponseData),
) -> Response(ResponseData) {
  req.session
  |> result.then(session.validate)
  |> result.replace_error(empty_response(403))
  |> result.map(fn(_ok) { handler() })
  |> result.unwrap_both
}

@external(erlang, "filename", "extension")
fn do_file_extension(name: Charlist) -> Charlist

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

fn serve_static_file(path: List(String), root: String) -> Response(ResponseData) {
  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_tree.new()))

  let full_path =
    path
    |> string.join("/")
    |> string.append("/", _)
    |> string.append(root, _)

  full_path
  |> mist.send_file(0, None)
  |> result.map(fn(data) {
    let content_type = content_type_from_extension(full_path)
    response.new(200)
    |> response.set_body(data)
    |> response.prepend_header("content-type", content_type)
  })
  |> result.replace_error(not_found)
  |> result.unwrap_both
}

fn empty_response(status: Int) -> Response(ResponseData) {
  status
  |> response.new
  |> response.set_body(mist.Bytes(bytes_tree.new()))
}

fn json_response(status: Int, data: String) -> Response(ResponseData) {
  status
  |> response.new
  |> response.set_body(mist.Bytes(bytes_tree.from_string(data)))
  |> response.prepend_header("content-type", "application/json")
}

fn get_cookie_from_request(app_req: AppRequest) -> Result(session.Session, Nil) {
  app_req.req
  |> request.get_header("cookie")
  |> result.map(cookie.parse)
  |> result.then(fn(cookies) {
    list.find(cookies, fn(p) {
      case p {
        #("session", _session) -> True
        _ -> False
      }
    })
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

fn get_json_body(app_req: AppRequest, decoder: Decoder(a)) -> Result(a, Nil) {
  app_req.req
  |> mist.read_body(1024 * 1024 * 10)
  |> result.replace_error(Nil)
  |> result.map(fn(req) { req.body })
  |> result.then(bit_array.to_string)
  |> result.then(fn(body) {
    body
    |> json.parse(decoder)
    |> result.replace_error(Nil)
  })
}
