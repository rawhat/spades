import gleam/json.{Json}
import gleam/list
import gleam/map.{Map}
import gleam/option.{Some}
import gleam/otp/actor
import gleam/otp/process.{Sender}
import gleam/result
import spades/game/card.{Card}
import spades/game/hand.{Call}
import spades/game/game.{Game, GameReturn, Success}
import spades/game/player.{EastWest, NorthSouth, Player, Position}
import spades/session.{Session}
import mist/websocket.{TextMessage}
import glisten/tcp.{HandlerMessage}

pub type GameEntry {
  GameEntry(id: Int, name: String, players: Int)
}

pub type GameUser {
  GameUser(sender: Sender(HandlerMessage), session: Session)
}

pub fn return_to_entry(return: GameReturn) -> GameEntry {
  GameEntry(return.game.id, return.game.name, map.size(return.game.players))
}

fn entry_to_json(entry: GameEntry) -> json.Json {
  json.object([
    #("id", json.int(entry.id)),
    #("name", json.string(entry.name)),
    #("players", json.int(entry.players)),
  ])
}

pub fn game_entry_to_json(entry: GameEntry) -> String {
  entry
  |> entry_to_json
  |> json.to_string
}

pub fn game_entries_to_json(entries: List(GameEntry)) -> String {
  entries
  |> json.array(entry_to_json)
  |> json.to_string
}

pub type ManagerAction {
  NewGame(caller: Sender(GameReturn), session: Session, game_name: String)
  AddPlayer(
    caller: Sender(HandlerMessage),
    game_id: Int,
    session: Session,
    position: Position,
  )
  MakeCall(
    caller: Sender(HandlerMessage),
    game_id: Int,
    session: Session,
    call: Call,
  )
  PlayCard(
    caller: Sender(HandlerMessage),
    game_id: Int,
    session: Session,
    card: Card,
  )
  ListGames(caller: Sender(List(GameEntry)))
  Join(id: Int, sender: Sender(HandlerMessage), session: Session)
  Leave(id: Int, session: Session)
  Broadcast(id: Int, game: GameReturn)
}

pub type GameState {
  GameState(users: List(GameUser), game: Game)
}

pub type ManagerState {
  ManagerState(games: Map(Int, GameState), next_id: Int)
}

pub fn start() -> Result(Sender(ManagerAction), actor.StartError) {
  actor.start(
    ManagerState(map.new(), 1),
    fn(message, state) {
      case message {
        NewGame(caller, session, game_name) -> {
          let new_game = game.new(state.next_id, game_name, session.username)
          let game_state = GameState([], new_game)
          process.send(caller, Success(new_game, []))
          let new_games = map.insert(state.games, state.next_id, game_state)
          actor.Continue(ManagerState(new_games, state.next_id + 1))
        }
        AddPlayer(caller, game_id, session, position) ->
          case map.get(state.games, game_id) {
            Ok(game_state) -> {
              let new_player =
                Player(session.id, session.username, position, hand.new())
              let resp = game.add_player(game_state.game, new_player)
              resp.game
              |> game_to_json
              |> json.to_string
              |> TextMessage
              |> websocket.send(caller, _)
              state
              |> update_if_success(resp)
              |> actor.Continue
            }
            _ -> actor.Continue(state)
          }
        MakeCall(caller, game_id, session, call) ->
          case map.get(state.games, game_id) {
            Error(_) -> actor.Continue(state)
            Ok(game_state) -> {
              let resp = game.make_call(game_state.game, session.id, call)
              resp.game
              |> game_to_json
              |> json.to_string
              |> TextMessage
              |> websocket.send(caller, _)
              state
              |> update_if_success(resp)
              |> actor.Continue
            }
          }
        PlayCard(caller, game_id, session, card) ->
          case map.get(state.games, game_id) {
            Error(_) -> actor.Continue(state)
            Ok(game_state) -> {
              let resp = game.play_card(game_state.game, session.id, card)
              resp.game
              |> game_to_json
              |> json.to_string
              |> TextMessage
              |> websocket.send(caller, _)
              state
              |> update_if_success(resp)
              |> actor.Continue
            }
          }
        ListGames(caller) -> {
          state.games
          |> map.values
          |> list.map(fn(game_state) {
            let game = game_state.game
            GameEntry(game.id, game.name, map.size(game.players))
          })
          |> process.send(caller, _)
          actor.Continue(state)
        }
        Join(id, sender, session) -> {
          let user = GameUser(sender, session)
          case map.has_key(state.games, id) {
            True ->
              state.games
              |> map.update(
                id,
                fn(existing) {
                  assert Some(GameState(users, game)) = existing
                  GameState([user, ..users], game)
                },
              )
              |> fn(games) { ManagerState(..state, games: games) }
            _ -> state
          }
          |> actor.Continue
        }
        Leave(id, session) ->
          case map.get(state.games, id) {
            Ok(game_state) -> {
              let new_users =
                list.filter(
                  game_state.users,
                  fn(user) { user.session != session },
                )
              state.games
              |> map.insert(id, GameState(..game_state, users: new_users))
              |> fn(games) { ManagerState(..state, games: games) }
            }
            _ -> state
          }
          |> actor.Continue
        Broadcast(id, return) -> {
          let _ =
            state.games
            |> map.get(id)
            |> result.map(fn(game_state) {
              let message =
                return.game
                |> game_to_json
                |> json.to_string
                |> TextMessage
              list.each(
                game_state.users,
                fn(user) { websocket.send(user.sender, message) },
              )
            })
          actor.Continue(state)
        }
      }
    },
  )
}

fn update_if_success(state: ManagerState, return: GameReturn) -> ManagerState {
  case return {
    Success(updated_game, _events) ->
      state.games
      |> map.update(
        updated_game.id,
        fn(existing) {
          assert Some(GameState(users, _game)) = existing
          GameState(users, updated_game)
        },
      )
      |> fn(games) { ManagerState(..state, games: games) }
    _ -> state
  }
}

fn game_to_json(g: Game) -> Json {
  json.object([
    #("created_by", json.string(g.created_by)),
    #("current_player", player.position_to_json(g.current_player)),
    #("id", json.int(g.id)),
    #(
      "last_trick",
      json.nullable(
        g.last_trick,
        fn(trick) { json.array(trick, game.play_to_json) },
      ),
    ),
    #("name", json.string(g.name)),
    #(
      "players",
      g.players
      |> map.values
      |> list.map(player.to_public)
      |> json.array(player.public_to_json),
    ),
    #("player_position", game.player_position_to_json(g.player_position)),
    #(
      "scores",
      json.object([
        #(
          "north_south",
          g.scores
          |> map.get(NorthSouth)
          |> result.map(hand.score_to_int)
          |> result.unwrap(0)
          |> json.int,
        ),
        #(
          "east_west",
          g.scores
          |> map.get(EastWest)
          |> result.map(hand.score_to_int)
          |> result.unwrap(0)
          |> json.int,
        ),
      ]),
    ),
    #("spades_broken", json.bool(g.spades_broken)),
    #(
      "state",
      case g.state {
        game.Waiting -> "waiting"
        game.Bidding -> "bidding"
        game.Playing -> "playing"
      }
      |> json.string,
    ),
    #("trick", json.array(g.trick, game.play_to_json)),
  ])
}
