import gleam/io
import gleam/iterator.{from_list, range, to_list}
import gleam/list.{flatten}
import gleam/map.{Map}
import gleam/option.{None, Option, Some}
import gleam/order.{Eq, Gt, Lt, Order}
import gleam/pair
import gleam/result

pub type Suit {
  Clubs
  Hearts
  Diamonds
  Spades
}

pub type Value {
  Ace
  King
  Queen
  Jack
  Number(value: Int)
}

pub fn value_order(v1: Value, v2: Value) -> Order {
  case tuple(v1, v2) {
    tuple(a, b) if a == b -> Eq
    tuple(Ace, _) -> Gt
    tuple(King, Ace) -> Lt
    tuple(King, _) -> Gt
    tuple(Queen, Ace) -> Lt
    tuple(Queen, King) -> Lt
    tuple(Queen, _) -> Gt
    tuple(Jack, Ace) -> Lt
    tuple(Jack, King) -> Lt
    tuple(Jack, Queen) -> Lt
    tuple(Jack, _) -> Gt
    tuple(Number(n), Number(p)) if n > p -> Gt
    tuple(Number(n), Number(p)) if n < p -> Lt
    tuple(Number(_), _) -> Lt
  }
}

pub type Card {
  Card(suit: Suit, value: Value)
}

pub type Call {
  BlindNil
  Nil
  Call(value: Int)
}

pub type Hand {
  Hand(cards: List(Card), tricks: Int, call: Option(Call), revealed: Bool)
}

pub fn new_hand(cards: List(Card)) -> Hand {
  Hand(cards, 0, None, False)
}

pub type Team {
  NorthSouth
  EastWest
}

pub type PlayerId =
  String

pub type Player {
  Player(id: PlayerId, name: String, team: Team, hand: Option(Hand))
}

pub fn new_player(id: PlayerId, name: String, team: Team) -> Player {
  Player(id, name, team, None)
}

pub fn receive_cards(player: Player, cards: List(Card)) -> Player {
  Player(
    id: player.id,
    name: player.name,
    team: player.team,
    hand: Some(new_hand(cards)),
  )
}

pub type GameState {
  Waiting
  Bidding
  Playing
}

pub type Trick {
  Trick(player_id: PlayerId, card: Card)
}

pub type Score {
  Score(points: Int, bags: Int)
}

pub fn new_score() -> Score {
  Score(points: 0, bags: 0)
}

pub fn add(a: Score, b: Score) -> Score {
  Score(points: a.points + b.points, bags: a.bags + b.bags)
}

pub type Game {
  Game(
    current_player: Option(PlayerId),
    deck: List(Card),
    id: String,
    last_trick: Option(List(Trick)),
    name: String,
    play_order: List(PlayerId),
    players: Map(PlayerId, Player),
    scores: Map(Team, Score),
    spades_broken: Bool,
    state: GameState,
    trick: List(Trick),
  )
}

pub fn new_deck() -> List(Card) {
  let values =
    range(from: 2, to: 10)
    |> iterator.map(Number(_))
    |> to_list

  [Ace, King, Queen, Jack, ..values]
  |> from_list
  |> iterator.map(fn(value) {
    [Clubs, Diamonds, Hearts, Spades]
    |> from_list
    |> iterator.map(Card(_, value))
    |> to_list
  })
  |> to_list
  |> flatten
}

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
    id: id,
    last_trick: None,
    name: name,
    play_order: [],
    players: map.new(),
    scores: scores,
    spades_broken: False,
    state: Waiting,
    trick: [],
  )
}

pub fn partition(items: List(a), func: fn(a) -> Bool) -> tuple(List(a), List(a)) {
  items
  |> list.fold(
    tuple(list.new(), list.new()),
    fn(item, acc) {
      case func(item) {
        True ->
          acc
          |> pair.first
          |> list.append([item])
          |> fn(new) { tuple(new, pair.second(acc)) }
        _ ->
          acc
          |> pair.second
          |> list.append([item])
          |> fn(new) { tuple(pair.first(acc), new) }
      }
    },
  )
}

pub fn deal_cards(game: Game) -> Game {
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
    }
    _ -> game
  }
}

pub fn start_bidding(game: Game) -> Game {
  case map.size(game.players) {
    4 -> Game(..game, state: Bidding)
    _ -> game
  }
}

pub fn update_player_hand(
  game: Game,
  player_id: PlayerId,
  updater: fn(Hand) -> Hand,
) -> Result(Game, String) {
  let player =
    game.players
    |> map.get(player_id)
    |> result.map(fn(p) {
      Player(..p, hand: option.map(p.hand, updater))
    })
  case player {
    Ok(p) ->
      Game(
        ..game,
        players: map.insert(game.players, player_id, p)
      )
      |> Ok
    Error(_) -> Error("Couldn't update hand")
  }
}

pub fn reveal_player_card(
  game: Game,
  player_id: PlayerId,
) -> Result(Game, String) {
  update_player_hand(game, player_id, fn(hand) { Hand(..hand, revealed: True) })
}

pub fn make_player_call(
  game: Game,
  player_id: PlayerId,
  call: Call,
) -> Result(Game, String) {
  update_player_hand(
    game,
    player_id,
    fn(hand) { Hand(..hand, call: Some(call)) },
  )
}

pub fn is_current(game: Game, player_id: PlayerId) -> Bool {
  game.current_player
  |> option.map(fn(id) { id == player_id })
  |> option.is_some
}

pub fn next_player(game: Game) -> Game {
  case game.play_order {
    [_, next, ..] -> Game(..game, current_player: Some(next))
    _ -> game
  }
}

pub fn start_game(game: Game) -> Game {
  let has_call = fn(player: Player) -> Bool {
    player.hand
    |> option.map(fn(h: Hand) { h.call })
    |> option.is_some
  }

  let all_called =
    game.players
    |> map.values
    |> list.all(has_call)

  case all_called {
    True -> Game(..game, state: Playing)
    _ -> game
  }
}

pub fn play_player_card(
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
}

pub fn add_to_trick(game: Game, player_id: PlayerId, card: Card) -> Game {
  Game(..game, trick: list.append(game.trick, [Trick(player_id, card)]))
}

pub fn has_suit(player: Player, suit: Suit) -> Bool {
  player.hand
  |> option.map(fn(h: Hand) { h.cards })
  |> option.map(fn(cards: List(Card)) {
    list.any(cards, fn(c: Card) { c.suit == suit })
  })
  |> option.is_some
}

pub fn trick_winner(trick: List(Trick)) -> PlayerId {
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
    tuple(_, True) -> {
      fn(play) {
        case play {
          Trick(card: Card(suit: Spades, ..), ..) -> True
          _ -> False
        }
      }
    }
    tuple([Trick(card: Card(suit: lead_suit, ..), ..), ..], _) -> {
      fn(play) {
        case play {
          Trick(card: Card(suit: suit, ..), ..) if suit == lead_suit -> True
          _ -> False
        }
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

pub fn award_trick(game: Game) -> Result(Game, String) {
  case list.length(game.trick) {
    4 -> {
      let winner = trick_winner(game.trick)
      update_player_hand(
        game,
        winner,
        fn(h) { Hand(..h, tricks: h.tricks + 1) },
      )
    }
    _ -> Ok(game)
  }
}

pub fn end_hand(game: Game) -> Game {
  case list.length(game.trick) {
    4 -> Game(..game, trick: [], last_trick: Some(game.trick))
    _ -> game
  }
}

pub fn score_from_call(call_and_taken: tuple(Call, Int)) -> Score {
  case call_and_taken {
    tuple(BlindNil, 0) -> Score(points: 100, bags: 0)
    tuple(BlindNil, _) -> Score(points: -100, bags: 0)
    tuple(Nil, 0) -> Score(points: 50, bags: 0)
    tuple(Nil, _) -> Score(points: -50, bags: 0)
    tuple(Call(value: called), taken) if called > taken ->
      Score(points: -1 * called, bags: 0)
    tuple(Call(value: called), taken) if taken >= called ->
      Score(points: 10 * called, bags: taken - called)
  }
}

pub fn calculate_score(players: List(Player)) -> Score {
  let calls_and_taken =
    players
    |> list.map(fn(player: Player) {
      case player.hand {
        Some(Hand(call: Some(call), tricks: tricks, ..)) ->
          Some(tuple(call, tricks))
        _ -> None
      }
    })
  let nil_not_nil =
    partition(
      calls_and_taken,
      fn(call) {
        case call {
          Some(tuple(Nil, _)) | Some(tuple(BlindNil, _)) -> True
          _ -> False
        }
      },
    )
  case nil_not_nil {
    tuple(
      [],
      [Some(tuple(Call(value: call1), taken1)), Some(tuple(Call(value: call2), taken2))],
    ) ->
      case tuple(call1 + call2, taken1 + taken2) {
        tuple(call, taken) if call > taken -> Score(points: -1 * call, bags: 0)
        tuple(call, taken) if taken >= call ->
          Score(points: call * 10, bags: taken - call)
      }
    tuple(nils, not_nils) ->
      list.append(nils, not_nils)
      |> list.fold(
        new_score(),
        fn(item, score) {
          item
          |> option.unwrap(tuple(Call(0), 0))
          |> score_from_call
          |> add(score)
        },
      )
  }
}

pub fn award_points(game: Game) -> Game {
  let tuple(north_south, east_west) =
    game.players
    |> map.values
    |> partition(fn(player: Player) { player.team == NorthSouth })
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

pub fn increment_play_order(game: Game) -> Game {
  let play_order = case game.play_order {
    [first, ..rest] -> list.append(rest, [first])
  }
  Game(..game, play_order: play_order)
}

pub fn set_bidding(game: Game) -> Game {
  Game(..game, state: Bidding)
}

pub fn end_round(game: Game) -> Game {
  let all_empty =
    game.players
    |> map.values
    |> list.all(fn(p: Player) {
      p.hand
      |> option.map(fn(h: Hand) { list.length(h.cards) == 4 })
      |> option.unwrap(False)
    })
  case all_empty {
    False -> game
    _ ->
      Game(..game, last_trick: None)
      |> award_points
      |> increment_play_order
      |> deal_cards
      |> set_bidding
  }
}

// Public API
//   - Add player ✔️
//   - Reveal cards ✔️
//   - Make call
//   - Play card
//   (state fns)
pub fn add_player(game: Game, player: Player) -> Result(Game, String) {
  let is_full = map.size(game.players) == 4
  let player_exists = map.has_key(game.players, player.id)
  let team_count =
    game.players
    |> map.filter(fn(_, v: Player) { v.team == player.team })
    |> map.size

  case tuple(is_full, player_exists, team_count == 2) {
    tuple(True, _, _) -> Error("Cannot add player, game is full")
    tuple(_, True, _) -> Error("Cannot add player, already in game")
    tuple(_, _, True) -> Error("Cannot add player, team is full")
    _ ->
      game.players
      |> map.insert(player.id, player)
      |> fn(players) { Game(..game, players: players) }
      |> deal_cards
      |> start_bidding
      |> Ok
  }
}

pub fn reveal_cards(game: Game, player_id: PlayerId) -> Result(Game, String) {
  case map.get(game.players, player_id) {
    Ok(Player(hand: Some(Hand(revealed: False, ..)), ..)) ->
      reveal_player_card(game, player_id)
    _ -> Error("Player cannot reveal")
  }
}

pub fn make_call(
  game: Game,
  player_id: PlayerId,
  call: Call,
) -> Result(Game, String) {
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
    _ -> Error("Player cannot call")
  }
}

pub fn play_card(
  game: Game,
  player_id: PlayerId,
  card: Card,
) -> Result(Game, String) {
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
    tuple([], False, Spades) -> False
    tuple([], _, _) -> True
    tuple([Trick(card: lead, ..), ..], _, suit) ->
      lead.suit == suit || game.players
      |> map.get(player_id)
      |> result.map(fn(p) { has_suit(p, lead.suit) == False })
      |> result.unwrap(True)
  }
  case tuple(can_play, has_card, card_is_valid) {
    tuple(False, _, _) -> Error("Player cannot play card")
    tuple(_, False, _) -> Error("Player does not have card")
    tuple(_, _, False) -> Error("Card is not valid")
    _ ->
      game
      |> play_player_card(player_id, card)
      |> result.map(fn(g) { add_to_trick(g, player_id, card) })
      |> result.map(next_player)
      |> result.map(award_trick)
      |> result.flatten
      |> result.map(end_hand)
      |> result.map(end_round)
  }
}
