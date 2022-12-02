import gleam/dynamic.{decode2, field}
import gleam/erlang/process.{Subject}
import gleam/json.{Json}
import gleam/list
import gleam/map.{Map}
import gleam/option.{Some}
import gleam/otp/actor
import gleam/result
import spades/game/card.{Card}
import spades/game/hand.{Call}
import spades/game/game.{Game, GameReturn, Success}
import spades/game/player.{EastWest, North, NorthSouth, Player, Position}
import spades/session.{Session}
import mist/logger
import mist/websocket.{TextMessage}
import glisten/handler.{HandlerMessage}

pub type GameEntry {
  GameEntry(id: Int, name: String, players: Int)
}

pub type GameUser {
  GameUser(sender: Subject(HandlerMessage), session: Session)
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

pub type GameAction {
  AddBot(game_id: Int, position: Position)
  AddPlayer(game_id: Int, position: Position)
  MakeCall(game_id: Int, call: Call)
  PlayCard(game_id: Int, card: Card)
  Reveal(game_id: Int)
}

pub type ManagerAction {
  Act(caller: Subject(GameReturn), session: Session, action: GameAction)
  Broadcast(game: GameReturn)
  ListGames(caller: Subject(List(GameEntry)))
  NewGame(caller: Subject(GameReturn), session: Session, name: String)
  Read(caller: Subject(Json), game_id: Int, player_id: Int)
  Join(caller: Subject(HandlerMessage), game_id: Int, session: Session)
  Leave(game_id: Int, session: Session)
}

pub type PublicGame {
  PublicGame(
    created_by: String,
    current_player: Position,
    id: Int,
    last_trick: option.Option(hand.Trick),
    name: String,
    players: List(player.PublicPlayer),
    player_position: Map(Position, Int),
    scores: Map(player.Team, hand.Score),
    spades_broken: Bool,
    state: game.State,
    trick: hand.Trick,
  )
}

pub fn to_public(game: Game) -> PublicGame {
  PublicGame(
    created_by: game.created_by,
    current_player: game.current_player,
    id: game.id,
    last_trick: game.last_trick,
    name: game.name,
    players: game.players
    |> map.values
    |> list.map(player.to_public),
    player_position: game.player_position,
    scores: game.scores,
    spades_broken: game.spades_broken,
    state: game.state,
    trick: game.trick,
  )
}

pub fn public_to_json(game: PublicGame) -> Json {
  json.object([
    #("created_by", json.string(game.created_by)),
    #("current_player", player.position_to_json(game.current_player)),
    #("id", json.int(game.id)),
    #(
      "last_trick",
      json.nullable(
        game.last_trick,
        fn(trick) { json.array(trick, hand.play_to_json) },
      ),
    ),
    #("name", json.string(game.name)),
    #(
      "players",
      game.players
      |> json.array(player.public_to_json),
    ),
    #("player_position", game.player_position_to_json(game.player_position)),
    #(
      "scores",
      json.object([
        #(
          "north_south",
          game.scores
          |> map.get(NorthSouth)
          |> result.map(hand.score_to_int)
          |> result.unwrap(0)
          |> json.int,
        ),
        #(
          "east_west",
          game.scores
          |> map.get(EastWest)
          |> result.map(hand.score_to_int)
          |> result.unwrap(0)
          |> json.int,
        ),
      ]),
    ),
    #("spades_broken", json.bool(game.spades_broken)),
    #("state", game.state_to_json(game.state)),
    #("trick", json.array(game.trick, hand.play_to_json)),
  ])
}

// TODO:  This can be refactored a lot... i think some kind of like
//   fn get_public_players_json(Game) -> Json
//   fn get_sorted_player_cards_json(Game) -> Json
//   ...
fn state_for_player(game: Game, player_id: Int) -> List(#(String, Json)) {
  game.players
  |> map.get(player_id)
  |> result.map(fn(player) {
    [
      #("type", json.string("player_state")),
      #(
        "data",
        json.object([
          #("call", json.nullable(player.hand.call, hand.call_to_json)),
          #(
            "cards",
            player.hand.cards
            |> card.hand_sort
            |> json.array(card.to_json),
          ),
          #("created_by", json.string(game.created_by)),
          #("current_player", player.position_to_json(game.current_player)),
          #("id", json.int(game.id)),
          #(
            "last_trick",
            json.nullable(game.last_trick, json.array(_, hand.play_to_json)),
          ),
          #("name", json.string(game.name)),
          #(
            "players",
            game.players
            |> map.values
            |> list.map(player.to_public)
            |> json.array(player.public_to_json),
          ),
          #(
            "player_position",
            game.player_position_to_json(game.player_position),
          ),
          #("position", player.position_to_json(player.position)),
          #("revealed", json.bool(player.hand.revealed)),
          #(
            "scores",
            json.object([
              #(
                "north_south",
                game.scores
                |> map.get(NorthSouth)
                |> result.map(hand.score_to_int)
                |> result.unwrap(0)
                |> json.int,
              ),
              #(
                "east_west",
                game.scores
                |> map.get(EastWest)
                |> result.map(hand.score_to_int)
                |> result.unwrap(0)
                |> json.int,
              ),
            ]),
          ),
          #("spades_broken", json.bool(game.spades_broken)),
          #(
            "state",
            case game.state {
              game.Waiting -> "waiting"
              game.Bidding -> "bidding"
              game.Playing -> "playing"
            }
            |> json.string,
          ),
          #(
            "team",
            player
            |> player.position_to_team
            |> player.team_to_json,
          ),
          #("trick", json.array(game.trick, hand.play_to_json)),
          #("tricks", json.int(player.hand.tricks)),
        ]),
      ),
    ]
  })
  |> result.unwrap([
    #("type", json.string("game_state")),
    #("data", game_to_json(game)),
  ])
}

pub type GameState {
  GameState(users: List(GameUser), game: Game)
}

pub type ManagerState {
  ManagerState(games: Map(Int, GameState), next_id: Int)
}

pub fn start() -> Result(Subject(ManagerAction), actor.StartError) {
  actor.start(
    ManagerState(map.new(), 1),
    fn(message, state) {
      // io.debug(#("game manager got a message", message))
      case message {
        Act(caller, session, action) -> {
          let #(game_id, action) = case action {
            AddBot(game_id, position) -> #(
              game_id,
              fn(game_state: GameState) {
                game.add_bot(game_state.game, position)
              },
            )
            AddPlayer(game_id, position) -> #(
              game_id,
              fn(game_state: GameState) {
                Player(session.id, session.username, position, hand.new())
                |> game.add_player(game_state.game, _)
              },
            )
            PlayCard(game_id, card) -> #(
              game_id,
              fn(game_state: GameState) {
                game.play_card(game_state.game, session.id, card)
              },
            )
            MakeCall(game_id, call) -> #(
              game_id,
              fn(game_state: GameState) {
                game.make_call(game_state.game, session.id, call)
              },
            )
            Reveal(game_id) -> #(
              game_id,
              fn(game_state: GameState) {
                game.reveal_hand(game_state.game, session.id)
              },
            )
          }
          state.games
          |> map.get(game_id)
          |> result.map(action)
          |> result.map(fn(game_return) {
            process.send(caller, game_return)
            state
            |> update_if_success(game_return)
            |> actor.Continue
          })
          |> result.unwrap(actor.Continue(state))
        }

        Broadcast(return) -> {
          let _ =
            state.games
            |> map.get(return.game.id)
            |> result.map(fn(game_state) {
              list.each(
                game_state.users,
                fn(user) {
                  game_return_to_json(user.session.id, return)
                  |> json.to_string
                  |> TextMessage
                  |> websocket.send(user.sender, _)
                },
              )
            })
          actor.Continue(state)
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
        Read(caller, game_id, player_id) -> {
          let _ =
            state.games
            |> map.get(game_id)
            |> result.map(fn(game_state) { game_state.game })
            |> result.map(fn(game) { game.Success(game, []) })
            |> result.map(game_return_to_json(player_id, _))
            |> result.map(process.send(caller, _))
          actor.Continue(state)
        }

        NewGame(caller, session, game_name) -> {
          let new_player = player.new(session.id, session.username, North)
          let game_state =
            state.next_id
            |> game.new(game_name, session.username)
            |> game.add_player(new_player)
          process.send(caller, game_state)
          let new_games =
            map.insert(
              state.games,
              state.next_id,
              GameState([], game_state.game),
            )
          actor.Continue(ManagerState(new_games, state.next_id + 1))
        }
        Join(caller, game_id, session) -> {
          let user = GameUser(caller, session)
          case map.has_key(state.games, game_id) {
            True ->
              state.games
              |> map.update(
                game_id,
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
      }
    },
  )
}

pub fn handler(
  msg: websocket.Message,
  game_manager: Subject(ManagerAction),
  session: Session,
) -> Result(Nil, Nil) {
  assert websocket.TextMessage(data) = msg

  field("type", dynamic.string)
  |> json.decode(data, _)
  |> result.replace_error(Nil)
  |> result.then(fn(msg_type) {
    case msg_type {
      "add_bot" ->
        decode2(
          AddBot,
          field("id", dynamic.int),
          field("position", player.position_decoder()),
        )
      "add_player" ->
        decode2(
          AddPlayer,
          field("id", dynamic.int),
          field("position", player.position_decoder()),
        )
      "make_call" ->
        decode2(
          MakeCall,
          field("id", dynamic.int),
          field("call", hand.call_decoder()),
        )
      "play_card" ->
        decode2(
          PlayCard,
          field("id", dynamic.int),
          field("card", card.decoder()),
        )
      "reveal_hand" -> fn(dyn) {
        dyn
        |> field("id", dynamic.int)
        |> result.map(Reveal)
      }
    }
    |> field("data", _)
    |> json.decode(data, _)
    |> result.replace_error(Nil)
  })
  |> result.then(fn(action) {
    process.try_call(game_manager, Act(_, session, action), 10)
    |> result.replace_error(Nil)
  })
  |> result.map(fn(game_return) {
    process.send(game_manager, Broadcast(game_return))
  })
  |> result.map_error(fn(err) {
    logger.error(#("Failed to parse game manager message", err))
    Nil
  })
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
        fn(trick) { json.array(trick, hand.play_to_json) },
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
    #("trick", json.array(g.trick, hand.play_to_json)),
  ])
}

fn game_return_to_json(id: Int, return: GameReturn) -> Json {
  let game_json = state_for_player(return.game, id)
  let events_json = case return {
    game.Success(_game, events) -> json.array(events, game.serialize_event)
    game.Failure(..) -> json.array([], game.serialize_event)
  }
  json.object([#("events", events_json), ..game_json])
}
