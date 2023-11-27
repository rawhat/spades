import gleam/bit_array
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/list
import gleam/map.{type Map}
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
  LobbyState(users: Map(Int, LobbyUser))
}

pub fn start() -> Result(Subject(LobbyAction), actor.StartError) {
  actor.start(
    LobbyState(map.new()),
    fn(msg, state) {
      case msg {
        Join(user, sender) ->
          LobbyState(map.insert(state.users, user.id, LobbyUser(user, sender)))
        Leave(id) -> LobbyState(map.delete(state.users, id))
        GameUpdate(game) -> {
          state.users
          |> map.values
          |> list.map(fn(lobby_user) { lobby_user.conn })
          |> list.each(fn(existing) {
            game
            |> game_to_string
            |> bit_array.from_string
            |> mist.send_text_frame(existing, _)
          })
          state
        }
      }
      |> actor.continue
    },
  )
}

fn game_to_string(game: Game) -> String {
  json.object([
    #("id", json.int(game.id)),
    #("name", json.string(game.name)),
    #("players", json.int(map.size(game.players))),
  ])
  |> json.to_string
}
