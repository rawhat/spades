import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/list
import gleam/dict.{type Dict}
import gleam/otp/actor
import spades/game/game.{type Game}
import spades/session.{type Session}
import mist.{type WebsocketConnection}

pub type LobbyAction {
  Join(session: Session, conn: WebsocketConnection)
  Leave(id: Int)
  GameUpdate(game: Game)
}

pub type LobbyUser {
  LobbyUser(session: Session, conn: WebsocketConnection)
}

pub type LobbyState {
  LobbyState(users: Dict(Int, LobbyUser))
}

pub fn start() -> Result(Subject(LobbyAction), actor.StartError) {
  actor.start(LobbyState(dict.new()), fn(msg, state) {
    case msg {
      Join(user, sender) ->
        LobbyState(dict.insert(state.users, user.id, LobbyUser(user, sender)))
      Leave(id) -> LobbyState(dict.delete(state.users, id))
      GameUpdate(game) -> {
        state.users
        |> dict.values
        |> list.map(fn(lobby_user) { lobby_user.conn })
        |> list.each(fn(existing) {
          game
          |> game_to_string
          |> mist.send_text_frame(existing, _)
        })
        state
      }
    }
    |> actor.continue
  })
}

fn game_to_string(game: Game) -> String {
  json.object([
    #("id", json.int(game.id)),
    #("name", json.string(game.name)),
    #("players", json.int(dict.size(game.players))),
  ])
  |> json.to_string
}
