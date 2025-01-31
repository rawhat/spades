import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import logging
import spades/game/card.{type Card}
import spades/game/game.{type Game, type GameReturn, Success}
import spades/game/hand.{type Call}
import spades/game/player.{type Position, EastWest, North, NorthSouth, Player}
import spades/session.{type Session}

pub type GameEntry {
  GameEntry(id: Int, name: String, players: Int)
}

pub type Message {
  Send(String)
}

pub type GameUser {
  GameUser(subj: Subject(Message), session: Session)
}

pub fn return_to_entry(return: GameReturn) -> GameEntry {
  GameEntry(return.game.id, return.game.name, dict.size(return.game.players))
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
  Join(subj: Subject(Message), game_id: Int, session: Session)
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
    player_position: Dict(Position, Int),
    scores: Dict(player.Team, hand.Score),
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
      |> dict.values
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
      json.nullable(game.last_trick, fn(trick) {
        json.array(trick, hand.play_to_json)
      }),
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
            |> dict.get(NorthSouth)
            |> result.map(hand.score_to_int)
            |> result.unwrap(0)
            |> json.int,
        ),
        #(
          "east_west",
          game.scores
            |> dict.get(EastWest)
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
  |> dict.get(player_id)
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
              |> dict.values
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
                  |> dict.get(NorthSouth)
                  |> result.map(hand.score_to_int)
                  |> result.unwrap(0)
                  |> json.int,
              ),
              #(
                "east_west",
                game.scores
                  |> dict.get(EastWest)
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
  ManagerState(games: Dict(Int, GameState), next_id: Int)
}

pub fn start() -> Result(Subject(ManagerAction), actor.StartError) {
  actor.start(ManagerState(dict.new(), 1), fn(message, state) {
    case message {
      Act(caller, session, action) -> {
        let #(game_id, action) = case action {
          AddBot(game_id, position) -> #(game_id, fn(game_state: GameState) {
            game.add_bot(game_state.game, position)
          })
          AddPlayer(game_id, position) -> #(game_id, fn(game_state: GameState) {
            Player(session.id, session.username, position, hand.new())
            |> game.add_player(game_state.game, _)
          })
          PlayCard(game_id, card) -> #(game_id, fn(game_state: GameState) {
            game.play_card(game_state.game, session.id, card)
          })
          MakeCall(game_id, call) -> #(game_id, fn(game_state: GameState) {
            game.make_call(game_state.game, session.id, call)
          })
          Reveal(game_id) -> #(game_id, fn(game_state: GameState) {
            game.reveal_hand(game_state.game, session.id)
          })
        }
        state.games
        |> dict.get(game_id)
        |> result.map(action)
        |> result.map(fn(game_return) {
          process.send(caller, game_return)
          state
          |> update_if_success(game_return)
          |> actor.continue
        })
        |> result.unwrap(actor.continue(state))
      }

      Broadcast(return) -> {
        let _ =
          state.games
          |> dict.get(return.game.id)
          |> result.map(fn(game_state) {
            list.each(game_state.users, fn(user) {
              game_return_to_json(user.session.id, return)
              |> json.to_string
              |> Send
              |> process.send(user.subj, _)
            })
          })
        actor.continue(state)
      }

      ListGames(caller) -> {
        state.games
        |> dict.values
        |> list.map(fn(game_state) {
          let game = game_state.game
          GameEntry(game.id, game.name, dict.size(game.players))
        })
        |> process.send(caller, _)
        actor.continue(state)
      }
      Read(caller, game_id, player_id) -> {
        let _ =
          state.games
          |> dict.get(game_id)
          |> result.map(fn(game_state) { game_state.game })
          |> result.map(fn(game) { game.Success(game, []) })
          |> result.map(game_return_to_json(player_id, _))
          |> result.map(process.send(caller, _))
        actor.continue(state)
      }

      NewGame(caller, session, game_name) -> {
        let new_player = player.new(session.id, session.username, North)
        let game_state =
          state.next_id
          |> game.new(game_name, session.username)
          |> game.add_player(new_player)
        process.send(caller, game_state)
        let new_games =
          dict.insert(
            state.games,
            state.next_id,
            GameState([], game_state.game),
          )
        actor.continue(ManagerState(new_games, state.next_id + 1))
      }
      Join(caller, game_id, session) -> {
        let user = GameUser(caller, session)
        case dict.has_key(state.games, game_id) {
          True ->
            state.games
            |> dict.upsert(game_id, fn(existing) {
              let assert Some(GameState(users, game)) = existing
              GameState([user, ..users], game)
            })
            |> fn(games) { ManagerState(..state, games: games) }
          _ -> state
        }
        |> actor.continue
      }
      Leave(id, session) ->
        case dict.get(state.games, id) {
          Ok(game_state) -> {
            let new_users =
              list.filter(game_state.users, fn(user) { user.session != session })
            state.games
            |> dict.insert(id, GameState(..game_state, users: new_users))
            |> fn(games) { ManagerState(..state, games: games) }
          }
          _ -> state
        }
        |> actor.continue
    }
  })
}

pub fn handle_message(
  data: String,
  game_manager: Subject(ManagerAction),
  session: Session,
) -> Result(Nil, Nil) {
  let add_bot_decoder = {
    use id <- decode.subfield(["data", "id"], decode.int)
    use position <- decode.subfield(
      ["data", "position"],
      player.position_decoder(),
    )
    decode.success(AddBot(id, position))
  }

  let add_player_decoder = {
    use id <- decode.subfield(["data", "id"], decode.int)
    use position <- decode.subfield(
      ["data", "position"],
      player.position_decoder(),
    )
    decode.success(AddPlayer(id, position))
  }

  let make_call_decoder = {
    use id <- decode.subfield(["data", "id"], decode.int)
    use call <- decode.subfield(["data", "call"], hand.call_decoder())
    decode.success(MakeCall(id, call))
  }

  let play_card_decoder = {
    use id <- decode.subfield(["data", "id"], decode.int)
    use card <- decode.subfield(["data", "card"], card.decoder())
    decode.success(PlayCard(id, card))
  }

  let reveal_decoder = {
    use id <- decode.subfield(["data", "id"], decode.int)
    decode.success(Reveal(id))
  }

  let decoder = {
    use tag <- decode.field("type", decode.string)
    case tag {
      "add_bot" -> add_bot_decoder
      "add_player" -> add_player_decoder
      "make_call" -> make_call_decoder
      "play_card" -> play_card_decoder
      "reveal_hand" -> reveal_decoder
      _ -> decode.failure(Reveal(0), "Msg")
    }
  }

  json.parse(data, decoder)
  |> result.replace_error(Nil)
  |> result.then(fn(action) {
    process.try_call(game_manager, Act(_, session, action), 10)
    |> result.replace_error(Nil)
  })
  |> result.map(fn(game_return) {
    process.send(game_manager, Broadcast(game_return))
  })
  |> result.map_error(fn(err) {
    logging.log(
      logging.Error,
      "Failed to parse game manager message" <> string.inspect(err),
    )
    Nil
  })
}

fn update_if_success(state: ManagerState, return: GameReturn) -> ManagerState {
  case return {
    Success(updated_game, _events) ->
      state.games
      |> dict.upsert(updated_game.id, fn(existing) {
        let assert Some(GameState(users, _game)) = existing
        GameState(users, updated_game)
      })
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
      json.nullable(g.last_trick, fn(trick) {
        json.array(trick, hand.play_to_json)
      }),
    ),
    #("name", json.string(g.name)),
    #(
      "players",
      g.players
        |> dict.values
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
            |> dict.get(NorthSouth)
            |> result.map(hand.score_to_int)
            |> result.unwrap(0)
            |> json.int,
        ),
        #(
          "east_west",
          g.scores
            |> dict.get(EastWest)
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
