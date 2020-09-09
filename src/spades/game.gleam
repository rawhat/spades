import gleam/io
import gleam/iterator
import gleam/list
import gleam/map.{Map}
import gleam/option.{None, Option, Some}
import gleam/pair
import gleam/result
import gleam/string
import spades/card.{
  Card, Spades, new_deck, sort as sort_cards, string as card_to_string, value_order,
}
import spades/player.{
  BlindNil, Call, EastWest, Hand, NorthSouth, Player, PlayerId, Position, PublicPlayer,
  Team, has_suit, receive_cards, team_from_position, to_public,
}
import spades/score.{Score, add, calculate_score, new_score}
import spades/util.{drop_while, partition}

pub type GameState {
  Waiting
  Bidding
  Playing
}

pub type Trick {
  Trick(player_id: PlayerId, card: Card)
}

pub type Event {
  AwardedTrick(winner: PlayerId)
  Called(player: PlayerId, call: Call)
  DealtCards
  HandEnded
  PlayedCard(player: PlayerId, card: Card)
  RevealedCards(player: PlayerId)
  RoundEnded
  StateChanged(old: GameState, new: GameState)
}

pub type Game {
  Game(
    current_player: Option(Position),
    deck: List(Card),
    events: List(Event),
    id: String,
    last_trick: Option(List(Trick)),
    name: String,
    player_position: Map(Position, PlayerId),
    play_order: List(Position),
    players: Map(PlayerId, Player),
    scores: Map(Team, Score),
    spades_broken: Bool,
    state: GameState,
    trick: List(Trick),
  )
}

pub type GameWithEvents =
  tuple(Game, List(Event))

fn with_events(game: Game) -> GameWithEvents {
  tuple(Game(..game, events: []), game.events)
}

pub type PublicScore {
  PublicScore(east_west: Int, north_south: Int)
}

fn get_public_scores(scores: Map(Team, Score)) -> PublicScore {
  let get_score = fn(team: Team) -> Int {
    case map.get(scores, team) {
      Ok(Score(points, bags)) -> points + bags
      _ -> 0
    }
  }
  PublicScore(
    east_west: get_score(EastWest),
    north_south: get_score(NorthSouth),
  )
}

pub type PublicState {
  PublicState(
    current_player: Option(Position),
    id: String,
    last_trick: Option(List(Trick)),
    name: String,
    player_position: Map(Position, PlayerId),
    players: List(PublicPlayer),
    scores: PublicScore,
    spades_broken: Bool,
    state: GameState,
    trick: List(Trick),
  )
}

pub type GameStateForPlayer {
  GameStateForPlayer(
    call: Option(Call),
    cards: List(Card),
    current_player: Option(Position),
    id: String,
    last_trick: Option(List(Trick)),
    name: String,
    player_position: Map(Position, PlayerId),
    players: List(PublicPlayer),
    position: Position,
    revealed: Bool,
    scores: PublicScore,
    spades_broken: Bool,
    state: GameState,
    team: Team,
    trick: List(Trick),
    tricks: Int,
  )
}

pub fn state(game: Game) -> PublicState {
  PublicState(
    current_player: game.current_player,
    id: game.id,
    last_trick: game.last_trick,
    name: game.name,
    players: game.players
    |> map.values
    |> list.map(to_public),
    player_position: game.player_position,
    scores: get_public_scores(game.scores),
    spades_broken: game.spades_broken,
    state: game.state,
    trick: game.trick,
  )
}

pub fn state_for_player(
  game: Game,
  player_id: PlayerId,
) -> Result(GameStateForPlayer, PublicState) {
  case map.get(game.players, player_id) {
    Error(_) ->
      game
      |> state
      |> Error
    Ok(Player(hand: hand, position: position, ..)) -> {
      let player_hand = option.unwrap(hand, Hand(list.new(), 0, None, False))
      GameStateForPlayer(
        call: player_hand.call,
        cards: sort_cards(player_hand.cards),
        current_player: game.current_player,
        id: game.id,
        last_trick: game.last_trick,
        name: game.name,
        players: game.players
        |> map.values
        |> list.map(to_public),
        player_position: game.player_position,
        position: position,
        revealed: player_hand.revealed,
        scores: get_public_scores(game.scores),
        spades_broken: game.spades_broken,
        state: game.state,
        team: team_from_position(position),
        trick: game.trick,
        tricks: player_hand.tricks,
      )
      |> Ok
    }
  }
}

fn add_event(game: Game, event: Event) -> Game {
  Game(..game, events: list.append(game.events, [event]))
}

fn deal_cards(game: Game) -> Game {
  case map.size(game.players) {
    4 -> {
      let players = map.values(game.players)
      game.deck
      |> list.index_map(fn(index, card) { tuple(index, card) })
      |> list.fold(
        map.new(),
        fn(p, m) {
          let index = pair.first(p) % 4
          [tuple(index, [])]
          |> map.from_list
          |> map.merge(m)
          |> map.update(
            index,
            fn(v) {
              case v {
                Ok(l) -> list.append(l, [pair.second(p)])
                _ -> []
              }
            },
          )
        },
      )
      |> map.values
      |> list.zip(players)
      |> list.fold(
        list.new(),
        fn(p, l) {
          let player =
            pair.second(p)
            |> receive_cards(pair.first(p))
          list.append(l, [tuple(player.id, player)])
        },
      )
      |> map.from_list
      |> fn(new_players) { Game(..game, players: new_players) }
      |> add_event(DealtCards)
    }
    _ -> game
  }
}

fn start_bidding(game: Game) -> Game {
  case map.size(game.players) {
    4 ->
      Game(..game, state: Bidding)
      |> add_event(StateChanged(old: game.state, new: Bidding))
    _ -> game
  }
}

fn is_current(game: Game, player_id: PlayerId) -> Bool {
  game.current_player
  |> option.map(fn(position) {
    map.get(game.player_position, position)
    |> option.from_result
  })
  |> option.flatten
  |> option.map(fn(id) { id == player_id })
  |> option.unwrap(False)
}

fn next_player(game: Game) -> Game {
  let next = case game.current_player {
    Some(position) ->
      game.play_order
      |> iterator.from_list
      |> iterator.cycle
      |> iterator.take(5)
      |> drop_while(fn(p) { p != position })
      |> list.tail
      |> result.map(list.head)
      |> result.flatten
      |> option.from_result
    None ->
      game.play_order
      |> list.head
      |> option.from_result
  }
  Game(..game, current_player: next)
}

fn start_game(game: Game) -> Game {
  let all_called =
    game.players
    |> map.values
    |> list.all(fn(player: Player) {
      player.hand
      |> option.map(fn(h: Hand) { h.call })
      |> option.flatten
      |> option.is_some
    })

  case all_called {
    True ->
      Game(..game, state: Playing)
      |> add_event(StateChanged(old: game.state, new: Playing))
    _ -> game
  }
}

fn update_player_hand(
  game: Game,
  player_id: PlayerId,
  updater: fn(Hand) -> Hand,
) -> Result(Game, String) {
  let player =
    game.players
    |> map.get(player_id)
    |> result.map(fn(p) { Player(..p, hand: option.map(p.hand, updater)) })
  case player {
    Ok(p) ->
      Game(..game, players: map.insert(game.players, player_id, p))
      |> Ok
    Error(_) -> Error("Couldn't update hand")
  }
}

fn reveal_player_card(
  game: Game,
  player_id: PlayerId,
) -> Result(GameWithEvents, String) {
  game
  |> update_player_hand(player_id, fn(hand) { Hand(..hand, revealed: True) })
  |> result.map(fn(g) { add_event(g, RevealedCards(player: player_id)) })
  |> result.map(with_events)
}

fn make_player_call(
  game: Game,
  player_id: PlayerId,
  call: Call,
) -> Result(Game, String) {
  update_player_hand(
    game,
    player_id,
    fn(hand) { Hand(..hand, call: Some(call)) },
  )
  |> result.map(fn(g) { add_event(g, Called(player: player_id, call: call)) })
}

fn play_player_card(
  game: Game,
  player_id: PlayerId,
  card: Card,
) -> Result(Game, String) {
  update_player_hand(
    game,
    player_id,
    fn(hand) {
      Hand(..hand, cards: list.filter(hand.cards, fn(c) { c != card }))
    },
  )
  |> result.map(fn(g) {
    add_event(g, PlayedCard(player: player_id, card: card))
  })
}

fn add_to_trick(game: Game, player_id: PlayerId, card: Card) -> Game {
  Game(..game, trick: list.append(game.trick, [Trick(player_id, card)]))
}

fn trick_winner(trick: List(Trick)) -> PlayerId {
  let has_spade =
    list.any(
      trick,
      fn(t) {
        case t {
          Trick(card: Card(suit: Spades, ..), ..) -> True
          _ -> False
        }
      },
    )

  let filter_fn: fn(Trick) -> Bool = case tuple(trick, has_spade) {
    tuple(_, True) -> fn(play) {
      case play {
        Trick(card: Card(suit: Spades, ..), ..) -> True
        _ -> False
      }
    }
    tuple([Trick(card: Card(suit: lead_suit, ..), ..), ..], _) -> fn(play) {
      case play {
        Trick(card: Card(suit: suit, ..), ..) if suit == lead_suit -> True
        _ -> False
      }
    }
  }

  trick
  |> list.filter(filter_fn)
  |> list.sort(fn(a: Trick, b: Trick) {
    value_order(a.card.value, b.card.value)
  })
  |> list.head
  |> result.map(fn(t: Trick) { t.player_id })
  |> result.unwrap("")
}

fn award_trick(game: Game) -> Result(Game, String) {
  case list.length(game.trick) {
    4 -> {
      let winner = trick_winner(game.trick)
      update_player_hand(
        game,
        winner,
        fn(h) { Hand(..h, tricks: h.tricks + 1) },
      )
      |> result.map(fn(g) {
        Game(
          ..g,
          current_player:
            game.player_position
            |> map.to_list
            |> list.map(pair.swap)
            |> map.from_list
            |> map.get(winner)
            |> option.from_result
        )
      })
      |> result.map(fn(g) { add_event(g, AwardedTrick(winner)) })
    }
    _ -> Ok(game)
  }
}

fn end_hand(game: Game) -> Game {
  case list.length(game.trick) {
    4 ->
      Game(..game, trick: [], last_trick: Some(game.trick))
      |> add_event(HandEnded)
    _ -> game
  }
}

fn award_points(game: Game) -> Game {
  let tuple(north_south, east_west) =
    game.players
    |> map.values
    |> partition(fn(player: Player) {
      team_from_position(player.position) == NorthSouth
    })
  Game(
    ..game,
    scores: game.scores
    |> map.update(
      NorthSouth,
      fn(old_score) {
        let old =
          old_score
          |> result.unwrap(new_score())

        north_south
        |> calculate_score
        |> add(old)
      },
    )
    |> map.update(
      EastWest,
      fn(old_score) {
        let old =
          old_score
          |> result.unwrap(new_score())

        east_west
        |> calculate_score
        |> add(old)
      },
    ),
  )
}

fn increment_play_order(game: Game) -> Game {
  let play_order = case game.play_order {
    [first, ..rest] -> list.append(rest, [first])
  }
  Game(..game, play_order: play_order)
}

fn set_bidding(game: Game) -> Game {
  Game(..game, state: Bidding)
  |> add_event(StateChanged(old: game.state, new: Bidding))
}

fn end_round(game: Game) -> Game {
  let all_empty =
    game.players
    |> map.values
    |> list.all(fn(p: Player) {
      p.hand
      |> option.map(fn(h: Hand) { list.length(h.cards) == 0 })
      |> option.unwrap(False)
    })
  case all_empty {
    False -> game
    _ ->
      Game(..game, last_trick: None)
      |> add_event(RoundEnded)
      |> award_points
      |> increment_play_order
      |> fn(g) {
        Game(
          ..g,
          current_player: g.play_order
          |> list.head
          |> option.from_result,
        )
      }
      |> deal_cards
      |> set_bidding
  }
}

fn add_to_play_order(game: Game, position: Position) -> Game {
  Game(..game, play_order: list.append(game.play_order, [position]))
}

fn set_spades_broken(game: Game, card: Card) -> Game {
  case card.suit {
    Spades -> Game(..game, spades_broken: True)
    _ -> game
  }
}

// Public API
//   - Add player ✔️
//   - Reveal cards ✔️
//   - Make call ✔️
//   - Play card ✔️
//   (state fns)
pub fn new_game(id: String, name: String, deck: Option(List(Card))) -> Game {
  let d = case deck {
    Some(d) -> d
    None -> new_deck()
  }
  let scores =
    map.from_list([tuple(NorthSouth, new_score()), tuple(EastWest, new_score())])
  Game(
    current_player: None,
    deck: d,
    events: list.new(),
    id: id,
    last_trick: None,
    name: name,
    play_order: list.new(),
    player_position: map.new(),
    players: map.new(),
    scores: scores,
    spades_broken: False,
    state: Waiting,
    trick: list.new(),
  )
}

pub fn add_player(game: Game, player: Player) -> Result(GameWithEvents, String) {
  let is_full = map.size(game.players) == 4
  let player_exists = map.has_key(game.players, player.id)
  let team_count =
    game.players
    |> map.filter(fn(_, p: Player) {
      team_from_position(p.position) == team_from_position(player.position)
    })
    |> map.size

  case tuple(is_full, player_exists, team_count == 2) {
    tuple(True, _, _) ->
      Error(string.concat(["Cannot add player", player.id, " game is full"]))
    tuple(_, True, _) ->
      Error(string.concat(["Cannot add player ", player.id, " already in game"]))
    tuple(_, _, True) ->
      Error(string.concat(["Cannot add player ", player.id, " team is full"]))
    _ ->
      game.players
      |> map.insert(player.id, player)
      |> fn(players) {
        Game(
          ..game,
          players: players,
          player_position: map.insert(game.player_position, player.position, player.id),
          current_player: option.or(game.current_player, Some(player.position)),
        )
      }
      |> add_to_play_order(player.position)
      |> deal_cards
      |> start_bidding
      |> with_events
      |> Ok
  }
}

pub fn reveal_cards(
  game: Game,
  player_id: PlayerId,
) -> Result(GameWithEvents, String) {
  case map.get(game.players, player_id) {
    Ok(Player(hand: Some(Hand(revealed: False, ..)), ..)) ->
      reveal_player_card(game, player_id)
    p -> {
      let _ = io.debug(p)
      let _ = io.debug(player_id)
      Error("Player cannot reveal")
    }
  }
}

pub fn make_call(
  game: Game,
  player_id: PlayerId,
  call: Call,
) -> Result(GameWithEvents, String) {
  let can_play = is_current(game, player_id)
  let is_valid_call = case call {
    BlindNil ->
      game.players
      |> map.get(player_id)
      |> result.map(fn(p: Player) {
        p.hand
        |> option.map(fn(h: Hand) { h.revealed == False })
        |> option.unwrap(True)
      })
      |> result.unwrap(True)
    _ -> True
  }
  case tuple(can_play, is_valid_call) {
    tuple(False, _) -> Error("Player cannot call")
    tuple(_, False) -> Error("Not a valid call")
    _ ->
      make_player_call(game, player_id, call)
      |> result.map(next_player)
      |> result.map(start_game)
      |> result.map(with_events)
  }
}

pub fn play_card(
  game: Game,
  player_id: PlayerId,
  card: Card,
) -> Result(GameWithEvents, String) {
  let can_play = is_current(game, player_id)
  let has_card =
    game.players
    |> map.get(player_id)
    |> result.map(fn(player: Player) { player.hand })
    |> result.map(fn(hand: Option(Hand)) {
      hand
      |> option.map(fn(h: Hand) { list.any(h.cards, fn(c) { c == card }) })
      |> option.unwrap(False)
    })
    |> result.unwrap(False)
  let card_is_valid = case tuple(game.trick, game.spades_broken, card.suit) {
    tuple([], False, Spades) ->
      game.players
      |> map.get(player_id)
      |> result.map(fn(player: Player) { option.to_result(player.hand, Nil) })
      |> result.flatten
      |> result.map(fn(hand: Hand) {
        list.all(hand.cards, fn(c: Card) { c.suit == Spades })
      })
      |> result.unwrap(False)
    tuple([], _, _) -> True
    tuple([Trick(card: lead, ..), ..], _, suit) ->
      lead.suit == suit || game.players
      |> map.get(player_id)
      |> result.map(fn(p) { has_suit(p, lead.suit) == False })
      |> result.unwrap(True)
  }
  case tuple(can_play, has_card, card_is_valid) {
    tuple(False, _, _) ->
      Error(string.concat([
        "Player ",
        player_id,
        " cannot play card ",
        card_to_string(card),
      ]))
    tuple(_, False, _) ->
      Error(string.concat([
        "Player ",
        player_id,
        " does not have card ",
        card_to_string(card),
      ]))
    tuple(_, _, False) ->
      Error(string.concat(["Card is not valid ", card_to_string(card)]))
    _ ->
      game
      |> play_player_card(player_id, card)
      |> result.map(fn(g) { add_to_trick(g, player_id, card) })
      |> result.map(fn(g) { set_spades_broken(g, card) })
      |> result.map(next_player)
      |> result.map(award_trick)
      |> result.flatten
      |> result.map(end_hand)
      |> result.map(end_round)
      |> result.map(with_events)
  }
}
