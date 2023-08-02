import gleam/erlang/process
import gleam/erlang/os
import gleam/function
import gleam/result
import gleam/string
import mist/handler
import mist
import spades/database
import spades/game_manager
import spades/socket/lobby
import spades/router.{
  app_middleware, result_to_response, router, session_middleware,
}
import spades/session

external fn get_cwd() -> Result(String, Nil) =
  "file" "get_cwd"

pub fn main() {
  let assert Ok(manager) = game_manager.start()

  let db = database.initialize()
  let assert Ok(_) = database.migrate(db)
  let assert Ok(cwd) = get_cwd()
  let static_root = string.append(cwd, "/priv")

  let assert Ok(salt) = os.get_env("PASSWORD_SALT")

  let assert Ok(session_manager) = session.start()
  let assert Ok(lobby_manager) = lobby.start()

  let handler =
    router
    |> session_middleware
    |> app_middleware(
      manager,
      db,
      static_root,
      salt,
      session_manager,
      lobby_manager,
    )
    |> function.compose(result_to_response)

  use _ <- result.then(
    handler
    |> handler.with_func
    |> mist.serve(4000, _)
    |> result.replace_error("Failed to start"),
  )

  process.sleep_forever()

  Ok(Nil)
}
