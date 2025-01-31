import envoy
import gleam/erlang/process
import gleam/result
import gleam/string
import logging
import mist
import spades/database
import spades/game_manager
import spades/router.{
  app_middleware, result_to_response, router, session_middleware,
}
import spades/session
import spades/socket/lobby

@external(erlang, "file", "get_cwd")
fn get_cwd() -> Result(String, Nil)

pub fn main() {
  logging.configure()
  let assert Ok(manager) = game_manager.start()

  let db = database.initialize()
  let assert Ok(cwd) = get_cwd()
  let static_root = string.append(cwd, "/priv")

  let assert Ok(salt) = envoy.get("PASSWORD_SALT")

  let assert Ok(session_manager) = session.start()
  let assert Ok(lobby_manager) = lobby.start()

  use _ <- result.then(
    fn(req) {
      use <- result_to_response
      use req <- app_middleware(
        req,
        manager,
        db,
        static_root,
        salt,
        session_manager,
        lobby_manager,
      )
      use req <- session_middleware(req)
      router(req)
    }
    |> mist.new
    |> mist.port(4000)
    |> mist.bind("0.0.0.0")
    |> mist.start_http
    |> result.replace_error("Failed to start"),
  )

  process.sleep_forever()

  Ok(Nil)
}
