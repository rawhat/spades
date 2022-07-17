import gleam/list
import gleam/map.{Map}
import gleam/otp/actor
import gleam/otp/process.{Sender}
import spades/game/card.{Card}
import spades/game/hand.{Call}
import spades/game/game.{Game, GameReturn, Success}
import spades/game/player.{Player, Position}

pub type GameEntry {
  GameEntry(id: Int, name: String, created_by: String)
}

pub type ManagerAction {
  NewGame(caller: Sender(GameReturn), created_by: String, game_name: String)
  AddPlayer(
    caller: Sender(GameReturn),
    game_id: Int,
    player_id: String,
    player_name: String,
    player_position: Position,
  )
  // RemovePlayer(caller: Sender(GameReturn), game_id: String, player_id: String)
  // AddSpectator(caller: Sender(GameReturn), game_id: String, user_id: String)
  // RemoveSpectator(caller: Sender(GameReturn), game_id: String, user_id: String)
  MakeCall(
    caller: Sender(GameReturn),
    game_id: Int,
    player_id: String,
    call: Call,
  )
  PlayCard(
    caller: Sender(GameReturn),
    game_id: Int,
    player_id: String,
    card: Card,
  )
  ListGames(caller: Sender(List(GameEntry)))
}

pub type ManagerState {
  ManagerState(games: Map(Int, Game), next_id: Int)
}

pub fn start() -> Result(Sender(ManagerAction), actor.StartError) {
  actor.start(
    ManagerState(map.new(), 1),
    fn(message, state) {
      case message {
        NewGame(caller, created_by, game_name) -> {
          let new_game = game.new(state.next_id, game_name, created_by)
          let games = map.insert(state.games, state.next_id, new_game)
          process.send(caller, Success(new_game, []))
          actor.Continue(ManagerState(games, state.next_id + 1))
        }
        AddPlayer(caller, game_id, id, name, position) ->
          case map.get(state.games, game_id) {
            Ok(game) -> {
              let new_player = Player(id, name, position, hand.new())
              let resp = game.add_player(game, new_player)
              process.send(caller, resp)
              state
              |> update_if_success(resp)
              |> actor.Continue
            }
            _ -> actor.Continue(state)
          }
        MakeCall(caller, game_id, id, call) ->
          case map.get(state.games, game_id) {
            Error(_) -> actor.Continue(state)
            Ok(game) -> {
              let resp = game.make_call(game, id, call)
              process.send(caller, resp)
              state
              |> update_if_success(resp)
              |> actor.Continue
            }
          }
        PlayCard(caller, game_id, id, card) ->
          case map.get(state.games, game_id) {
            Error(_) -> actor.Continue(state)
            Ok(game) -> {
              let resp = game.play_card(game, id, card)
              process.send(caller, resp)
              state
              |> update_if_success(resp)
              |> actor.Continue
            }
          }
        ListGames(caller) -> {
          state.games
          |> map.values
          |> list.map(fn(game) {
            GameEntry(game.id, game.name, game.created_by)
          })
          |> process.send(caller, _)
          actor.Continue(state)
        }
      }
    },
  )
}

fn update_if_success(state: ManagerState, return: GameReturn) -> ManagerState {
  case return {
    Success(updated_game, _events) ->
      updated_game
      |> map.insert(state.games, updated_game.id, _)
      |> fn(games) { ManagerState(..state, games: games) }
    _ -> state
  }
}
