import envoy
import gleam/erlang
import gleam/erlang/process
import gleam/result
import gleam/string
import logging
import mist
import spades/database
import spades/game_manager
import spades/lobby_manager
import spades/router.{
  app_middleware, result_to_response, router, session_middleware,
}
import spades/session

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
  let assert Ok(lobby_manager) = lobby_manager.start()

  let assert Ok(lustre_priv) = erlang.priv_directory("lustre")
  let server_component_path =
    lustre_priv <> "/static/lustre-server-component.mjs"

  let assert Ok(_) =
    fn(req) {
      use <- result_to_response
      use req <- app_middleware(
        req,
        manager,
        db,
        static_root,
        server_component_path,
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
    |> result.replace_error("Failed to start")

  process.sleep_forever()

  Ok(Nil)
}
