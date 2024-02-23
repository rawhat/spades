import gleam/erlang/process.{type Subject}
import gleam/json.{type Json}
import gleam/result
import spades/game_manager.{type GameEntry, type ManagerAction, ListGames, Read}

pub fn list(manager: Subject(ManagerAction)) -> Result(List(GameEntry), Nil) {
  manager
  |> process.try_call(ListGames, 1000)
  |> result.replace_error(Nil)
}

pub fn read(
  manager: Subject(ManagerAction),
  game_id: Int,
  player_id: Int,
) -> Result(Json, Nil) {
  manager
  |> process.try_call(Read(_, game_id, player_id), 1000)
  |> result.replace_error(Nil)
}
