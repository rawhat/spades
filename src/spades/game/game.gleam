import gleam/int
import gleam/io
import gleam/iterator
import gleam/json.{Json}
import gleam/list
import gleam/map.{Map}
import gleam/option.{None, Option, Some}
import gleam/result
import spades/game/bot
import spades/game/card.{Card, Deck, Spades}
import spades/game/hand.{Call, Hand, Play, Score, Trick}
import spades/game/player.{
  East, EastWest, North, NorthSouth, Player, Position, South, Team, West,
}

pub type Event {
  AwardedTrick(winner: Int)
  Called(id: Int, call: Call)
  DealtCards
  HandEnded
  PlayedCard(id: Int, card: Card)
  RevealedCards(id: Int)
  RoundEnded
  StateChanged(old: State, new: State)
}

pub fn serialize_event(event: Event) -> Json {
  let #(event_type, data) = case event {
    AwardedTrick(winner) -> #("awarded_trick", [#("winner", json.int(winner))])
    Called(id, call) -> #(
      "called",
      [#("id", json.int(id)), #("call", hand.call_to_json(call))],
    )
    DealtCards -> #("dealt_cards", [])
    HandEnded -> #("hand_ended", [])
    PlayedCard(id, card) -> #(
      "played_card",
      [#("id", json.int(id)), #("card", card.to_json(card))],
    )
    RevealedCards(id) -> #("revealed_cards", [#("id", json.int(id))])
    RoundEnded -> #("round_ended", [])
    StateChanged(old, new) -> #(
      "state_changed",
      [#("old", state_to_json(old)), #("new", state_to_json(new))],
    )
  }

  json.object([#("type", json.string(event_type)), ..data])
}

pub type State {
  Bidding
  Playing
  Waiting
}

pub fn state_to_json(state: State) -> Json {
  case state {
    Waiting -> "waiting"
    Bidding -> "bidding"
    Playing -> "playing"
  }
  |> json.string
}

pub type Game {
  Game(
    created_by: String,
    current_player: Position,
    deck: Deck,
    events: List(Event),
    id: Int,
    last_trick: Option(Trick),
    name: String,
    play_order: List(Position),
    player_position: Map(Position, Int),
    players: Map(Int, Player),
    scores: Map(Team, Score),
    shuffle: fn(List(Card)) -> List(Card),
    spades_broken: Bool,
    state: State,
    teams: Map(Team, List(Int)),
    trick: Trick,
  )
}

pub fn player_position_to_json(positions: Map(Position, Int)) -> Json {
  json.object([
    #(
      "north",
      positions
      |> map.get(North)
      |> option.from_result
      |> json.nullable(json.int),
    ),
    #(
      "east",
      positions
      |> map.get(East)
      |> option.from_result
      |> json.nullable(json.int),
    ),
    #(
      "south",
      positions
      |> map.get(South)
      |> option.from_result
      |> json.nullable(json.int),
    ),
    #(
      "west",
      positions
      |> map.get(West)
      |> option.from_result
      |> json.nullable(json.int),
    ),
  ])
}

pub type ErrorReason {
  GameFull
  TeamFull
  NotYourTurn
  InvalidSuit
  SpadesNotBroken
  InvalidAction
}

pub type GameReturn {
  Success(game: Game, events: List(Event))
  Failure(game: Game, reason: ErrorReason)
}

pub fn new(id: Int, name: String, created_by: String) -> Game {
  Game(
    created_by: created_by,
    current_player: North,
    deck: card.make_deck(),
    events: [],
    id: id,
    last_trick: None,
    name: name,
    play_order: [North, East, South, West],
    player_position: map.new(),
    players: map.new(),
    scores: map.from_list([#(NorthSouth, Score(0, 0)), #(EastWest, Score(0, 0))]),
    shuffle: list.shuffle,
    spades_broken: False,
    state: Waiting,
    teams: map.new(),
    trick: [],
  )
}

pub fn set_deck(game: Game, deck: Deck) -> Game {
  Game(..game, deck: deck)
}

pub fn set_shuffle(game: Game, shuffle: fn(List(Card)) -> List(Card)) -> Game {
  Game(..game, shuffle: shuffle)
}

pub fn add_bot(game: Game, position: Position) -> GameReturn {
  case map.get(game.player_position, position) {
    Error(Nil) -> {
      let bot_id =
        game.players
        |> map.values
        |> list.filter(fn(player) { player.id < 0 })
        |> list.fold(-1, fn(min, bot) { int.min(min, bot.id - 1) })
      let existing_names =
        game.players
        |> map.values
        |> list.map(fn(player) { player.name })
      assert Ok(name) =
        iterator.repeatedly(bot_name)
        |> iterator.drop_while(fn(name) { list.contains(existing_names, name) })
        |> iterator.take(1)
        |> iterator.at(0)
      let new_bot = player.new(bot_id, name, position)
      add_player(game, new_bot)
    }
    Ok(_) -> Failure(game, TeamFull)
  }
}

pub fn add_player(game: Game, new_player: Player) -> GameReturn {
  let player_count = map.size(game.players)
  let has_player = map.has_key(game.players, new_player.id)
  let team = player.position_to_team(new_player)

  let team_size =
    game.teams
    |> map.get(team)
    |> result.map(list.length)
    |> result.unwrap(0)

  case player_count, has_player, team_size {
    count, False, size if count < 4 && size < 2 ->
      Success(
        Game(
          ..game,
          players: map.insert(game.players, new_player.id, new_player),
          player_position: map.insert(
            game.player_position,
            new_player.position,
            new_player.id,
          ),
          teams: map.update(
            game.teams,
            team,
            fn(existing) {
              existing
              |> option.map(fn(existing) { [new_player.id, ..existing] })
              |> option.unwrap([new_player.id])
            },
          ),
        ),
        [],
      )
    count, False, team_size if team_size == 2 && count < 4 ->
      Failure(game, TeamFull)
    count, True, _team_size if count < 4 -> Failure(game, TeamFull)
    count, _has, _team_size if count == 4 -> Failure(game, GameFull)
    _, _, _ -> Failure(game, InvalidAction)
  }
  |> advance_state
}

pub fn make_call(game: Game, player_id: Int, call: Call) -> GameReturn {
  let game_state = game.state
  let attempting_player = map.get(game.players, player_id)

  case game_state, game.current_player, attempting_player {
    Bidding, current, Ok(Player(position: attempting, ..)) if current == attempting ->
      Game(
        ..game,
        players: map.update(
          game.players,
          player_id,
          fn(existing) {
            assert Some(existing) = existing
            player.make_call(existing, call)
          },
        ),
      )
      |> fn(g) { Success(g, [Called(player_id, call)]) }
      |> advance_state
    Bidding, current, Ok(Player(position: attempting, ..)) if current != attempting ->
      Failure(game, NotYourTurn)
    _, _, _ -> Failure(game, InvalidAction)
  }
}

pub fn play_card(game: Game, player_id: Int, card: Card) -> GameReturn {
  let game_state = game.state
  assert Ok(attempting_player) = map.get(game.players, player_id)
  let has_card = player.has_card(attempting_player, card)
  let only_has_spades =
    list.all(attempting_player.hand.cards, fn(card) { card.suit == Spades })
  let has_leading_suit = case game.trick {
    [] -> True
    [Play(card: Card(suit, ..), ..), ..] ->
      list.any(attempting_player.hand.cards, fn(card) { card.suit == suit })
  }
  io.debug(#(
    "player",
    player_id,
    "attempting to play",
    card,
    "and can play?",
    has_card,
    game.trick,
    game.spades_broken,
    has_leading_suit,
    only_has_spades,
  ))
  let can_play = case
    has_card,
    card.suit,
    game.trick,
    game.spades_broken,
    has_leading_suit,
    only_has_spades
  {
    True, Spades, _, _, _, True -> True
    True, Spades, _, True, False, _ -> True
    True, suit_to_play, [Play(card: Card(suit: leading_suit, ..), ..), ..], _, True, _ if suit_to_play == leading_suit ->
      True
    True, _, _, _, False, _ -> True
    True, Spades, [], False, _, False -> False
    True, _, [], _, _, _ -> True
    _, _, _, _, _, _ -> False
  }

  case game_state, game.current_player, attempting_player, can_play {
    Playing, current, Player(position: attempting, ..), True if current == attempting -> {
      let updated_player =
        Player(
          ..attempting_player,
          hand: hand.remove_card(attempting_player.hand, card),
        )
      Game(
        ..game,
        trick: list.append(game.trick, [Play(updated_player.id, card)]),
        players: map.insert(game.players, player_id, updated_player),
      )
      |> Success([PlayedCard(player_id, card)])
      |> advance_state
    }

    _, _, _, False -> Failure(game, InvalidSuit)
    Playing, current, Player(position: attempting, ..), True if current != attempting ->
      Failure(game, NotYourTurn)
    _, _, _, _ -> Failure(game, InvalidAction)
  }
}

pub fn reveal_hand(game: Game, player_id: Int) -> GameReturn {
  assert Ok(player) = map.get(game.players, player_id)
  case game.state, game.current_player, player {
    Bidding, current, Player(
      hand: Hand(revealed: False, call: None, ..),
      position: position,
      ..,
    ) if current == position -> {
      let new_players =
        game.players
        |> map.update(
          player_id,
          fn(p) {
            assert Some(p) = p
            Player(..p, hand: Hand(..p.hand, revealed: True))
          },
        )
      Success(Game(..game, players: new_players), [RevealedCards(player_id)])
    }
    _, _, _ -> Failure(game, InvalidAction)
  }
}

pub fn advance_state(return: GameReturn) -> GameReturn {
  case return {
    Failure(_game, _reason) -> return
    Success(game, events) -> {
      let player_count = map.size(game.players)
      let all_called =
        game.players
        |> map.values
        |> list.all(fn(p) { option.is_some(p.hand.call) })
      let all_played =
        game.players
        |> map.values
        |> list.all(fn(p) { list.length(p.hand.cards) == 0 })
      let trick_finished = list.length(game.trick) == 4
      io.debug(#(
        "advance args",
        game.state,
        player_count,
        all_called,
        all_played,
        trick_finished,
      ))
      case game.state, player_count, all_called, all_played, trick_finished {
        Waiting, count, _called, _played, _finished if count == 4 ->
          game
          |> start_bidding
          |> Success(list.append(events, [StateChanged(Waiting, Bidding)]))
        Waiting, _, _, _, _ -> return
        Bidding, 4, True, _played, _finished -> {
          io.debug(#("gonna start bidding with existing events", events))
          game
          |> start_playing
          |> Success(list.append(events, [StateChanged(Bidding, Playing)]))
        }
        Bidding, 4, _called, _played, _finished ->
          game
          |> next_player
          |> Success(events)
        Playing, 4, True, True, True ->
          game
          |> complete_trick(events)
          |> complete_round
        Playing, 4, True, False, True -> complete_trick(game, events)
        Playing, 4, True, _, _ ->
          game
          |> next_player
          |> Success(events)
        _, _, _, _, _ -> return
      }
      |> fn(return) {
        case return {
          Success(game, events) -> {
            assert Success(game, new_events) = perform_bot_action(game)
            Success(game, list.append(events, new_events))
          }
          _ -> return
        }
      }
    }
  }
}

fn start_bidding(game: Game) -> Game {
  game
  |> deal_cards
  |> fn(game) { Game(..game, state: Bidding) }
}

fn start_playing(game: Game) -> Game {
  game
  |> next_player
  |> fn(game) { Game(..game, state: Playing) }
}

fn complete_trick(game: Game, events: List(Event)) -> GameReturn {
  // find winner
  let winner = hand.find_winner(game.trick)
  // award trick
  let has_spade = list.any(game.trick, fn(trick) { trick.card.suit == Spades })
  let updated_players =
    map.update(
      game.players,
      winner,
      fn(existing) {
        assert Some(existing) = existing
        case existing.id == winner {
          True -> player.add_trick(existing)
          _ -> existing
        }
      },
    )
  assert Ok(current_player) = map.get(game.players, winner)
  Game(
    ..game,
    current_player: current_player.position,
    last_trick: Some(game.trick),
    players: updated_players,
    trick: [],
    spades_broken: game.spades_broken || has_spade,
  )
  |> Success(list.append(events, [AwardedTrick(winner)]))
}

fn complete_round(game_return: GameReturn) -> GameReturn {
  assert Success(game, events) = game_return
  game
  |> update_scores
  |> advance_dealer
  |> reset_players
  |> start_bidding
  |> Success(list.append(events, [StateChanged(Playing, Bidding)]))
}

fn get_next_position(game: Game) -> Position {
  case game.current_player {
    North -> East
    East -> South
    South -> West
    West -> North
  }
}

fn next_player(game: Game) -> Game {
  let next = get_next_position(game)

  Game(..game, current_player: next)
}

fn deal_cards(game: Game) -> Game {
  assert Ok(shuffled) =
    game.deck
    |> iterator.iterate(game.shuffle)
    |> iterator.take(12)
    |> iterator.last

  let [north, east, south, west] =
    shuffled
    |> list.index_fold(
      map.new(),
      fn(groups, card, index) {
        let position = 4 - index % 4
        map.update(
          groups,
          position,
          fn(existing) {
            let cards = option.unwrap(existing, [])
            [card, ..cards]
          },
        )
      },
    )
    |> map.values
    |> list.map(list.reverse)

  assert Ok(north_id) = map.get(game.player_position, North)
  assert Ok(east_id) = map.get(game.player_position, East)
  assert Ok(south_id) = map.get(game.player_position, South)
  assert Ok(west_id) = map.get(game.player_position, West)

  assert Ok(north_player) = map.get(game.players, north_id)
  assert Ok(east_player) = map.get(game.players, east_id)
  assert Ok(south_player) = map.get(game.players, south_id)
  assert Ok(west_player) = map.get(game.players, west_id)

  Game(
    ..game,
    players: map.from_list([
      #(north_id, player.receive_cards(north_player, north)),
      #(east_id, player.receive_cards(east_player, east)),
      #(south_id, player.receive_cards(south_player, south)),
      #(west_id, player.receive_cards(west_player, west)),
    ]),
  )
}

fn update_scores(game: Game) -> Game {
  assert Ok(north_id) = map.get(game.player_position, North)
  assert Ok(east_id) = map.get(game.player_position, East)
  assert Ok(south_id) = map.get(game.player_position, South)
  assert Ok(west_id) = map.get(game.player_position, West)

  assert Ok(north_player) = map.get(game.players, north_id)
  assert Ok(east_player) = map.get(game.players, east_id)
  assert Ok(south_player) = map.get(game.players, south_id)
  assert Ok(west_player) = map.get(game.players, west_id)

  let north_south_score = hand.team_score(north_player.hand, south_player.hand)
  let east_west_score = hand.team_score(east_player.hand, west_player.hand)

  Game(
    ..game,
    scores: game.scores
    |> map.update(NorthSouth, update_score(_, north_south_score))
    |> map.update(EastWest, update_score(_, east_west_score)),
  )
}

fn advance_dealer(game: Game) -> Game {
  let [current, next, ..rest] = game.play_order
  Game(
    ..game,
    play_order: list.append([next, ..rest], [current]),
    current_player: next,
  )
}

fn reset_players(game: Game) -> Game {
  let new_players =
    game.players
    |> map.map_values(fn(_key, value) { Player(..value, hand: hand.new()) })

  Game(..game, players: new_players)
}

fn update_score(existing: Option(Score), new: Score) -> Score {
  assert Some(score) = existing
  let new_bags = score.bags + new.bags
  case new_bags {
    bags if bags >= 10 -> Score(score.points + new.points - 40, 0)
    bags if bags >= 5 -> Score(score.points + new.points - 50, bags)
    bags -> Score(score.points + new.points, bags)
  }
}

pub fn then(return: GameReturn, action: fn(Game) -> GameReturn) -> GameReturn {
  case return {
    Success(game, events) ->
      case action(game) {
        Success(new_game, new_events) ->
          Success(new_game, list.append(events, new_events))
        failure -> failure
      }
    failure -> failure
  }
}

const names = [
  "A-aron", "Billium", "Craiggg", "Dante", "Ephram", "Fangio", "Gordon",
  "Hecate", "Izalith", "Jerome", "Krampus", "Leeroy", "Monte", "Neecey", "Oscar",
  "Persephone", "Quenton", "Riggs", "Simon", "Thaddeus", "Uther", "Banessa",
  "Whiskers", "Xena", "Ygritte", "Zenyatta",
]

pub fn bot_name() -> String {
  let names_length = list.length(names)
  assert Ok(name) =
    int.random(0, names_length)
    |> list.at(names, _)
  name
}

fn perform_bot_action(game: Game) -> GameReturn {
  game.current_player
  |> map.get(game.player_position, _)
  |> result.map(fn(id) {
    case id < 0 {
      True -> {
        assert Ok(current_bot) = map.get(game.players, id)
        case game.state {
          Waiting -> Success(game, [])
          Bidding -> {
            let bot_call = bot.call(game.players, current_bot)
            io.debug(#("bidding", bot_call, "for bot", id))
            game
            |> make_call(id, bot_call)
          }
          Playing -> {
            io.debug(#("current trick is", game.trick))
            let bot_card =
              bot.play_card(
                game.players,
                game.spades_broken,
                game.trick,
                current_bot,
              )
            io.debug(#("playing", bot_card, "for bot", id))
            game
            |> play_card(id, bot_card)
          }
        }
      }
      False -> Success(game, [])
    }
  })
  |> result.unwrap(Failure(game, NotYourTurn))
}
