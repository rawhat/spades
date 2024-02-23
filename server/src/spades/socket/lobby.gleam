import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/list
import gleam/otp/actor
import spades/game/game.{type Game}
import spades/session.{type Session}

pub type Message {
  Send(String)
}

pub type LobbyAction {
  Join(session: Session, subj: Subject(Message))
  Leave(id: Int)
  GameUpdate(game: Game)
}

pub type LobbyUser {
  LobbyUser(session: Session, subj: Subject(Message))
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
        |> list.each(fn(lobby_user) {
          game
          |> game_to_string
          |> Send
          |> process.send(lobby_user.subj, _)
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
