import gleam/json.{array, int, object, string}
import spades/game_manager.{GameEntry}

pub fn games_list(entries: List(GameEntry)) -> String {
  entries
  |> array(fn(entry) {
    object([
      #("id", int(entry.id)),
      #("name", string(entry.name)),
      #("players", int(entry.players)),
    ])
  })
  |> json.to_string
}
