import game/card.{type Card}
import game/game.{type Game, type GameEntry, type GameReturn, GameEntry, Success}
import game/hand.{type Call}
import game/player.{type Position, North, Player}
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
import spades/session.{type Session}

pub type Message {
  Send(String)
}

pub type GameUser {
  GameUser(subj: Subject(Message), session: Session)
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
              game.game_return_to_json(user.session.id, return)
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
          |> result.map(game.game_return_to_json(player_id, _))
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
