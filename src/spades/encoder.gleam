import gleam/json.{array, int, object, string}

import spades/game_manager.{GameEntry}

pub fn games_list(entries: List(GameEntry)) -> String {
  entries
  |> array(fn(entry) {
    object([
      #("id", int(entry.id)),
      #("name", string(entry.name)),
      #("created_by", string(entry.created_by))
    ])
  })
  |> json.to_string
}
