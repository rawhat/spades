import gleam/json
import gleam/list
import gleam/map.{Map}
import gleam/otp/actor
import gleam/otp/process.{Sender}
import glisten/tcp.{HandlerMessage}
import mist/websocket.{TextMessage}
import spades/game/game.{Game}
import spades/session.{Session}

pub type LobbyAction {
  Join(session: Session, sender: Sender(HandlerMessage))
  Leave(id: Int)
  GameUpdate(game: Game)
}

pub type LobbyUser {
  LobbyUser(session: Session, sender: Sender(HandlerMessage))
}

pub type LobbyState {
  LobbyState(users: Map(Int, LobbyUser))
}

pub fn start() -> Result(Sender(LobbyAction), actor.StartError) {
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
          |> list.map(fn(lobby_user) { lobby_user.sender })
          |> list.each(fn(existing) {
            let message =
              game
              |> game_to_string
              |> TextMessage
            websocket.send(message, existing)
          })
          state
        }
      }
      |> actor.Continue
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
