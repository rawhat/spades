import gleam/otp/process.{Sender}
import gleam/result
import spades/game_manager.{GameEntry, ListGames, ManagerAction}

pub fn list(manager: Sender(ManagerAction)) -> Result(List(GameEntry), Nil) {
  manager
  |> process.try_call(ListGames, 1_000)
  |> result.replace_error(Nil)
}
