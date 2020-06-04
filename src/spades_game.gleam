import gleam/io
import gleam/iterator.{from_list, range, to_list}
import gleam/list.{flatten}
import gleam/map.{Map}
import gleam/option.{Option, None, Some}
import gleam/pair

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

pub type PlayerId = String

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
    hand: Some(new_hand(cards)))
}

pub type GameState {
  Waiting
  Bidding
  Playing
}

pub type Trick = List(tuple(PlayerId, Card))

pub type Game {
  Game(
    advance: Bool,
    current_player: Option(PlayerId),
    deck: List(Card),
    id: String,
    name: String,
    play_order: List(PlayerId),
    players: Map(PlayerId, Player),
    scores: Map(Team, Int),
    spades_broken: Bool,
    state: GameState,
    trick: List(Trick))
}

pub fn set_advance(game: Game, advance: Bool) -> Game {
  Game(
    advance,
    current_player: game.current_player,
    deck: game.deck,
    id: game.id,
    name: game.name,
    play_order: game.play_order,
    players: game.players,
    scores: game.scores,
    spades_broken: game.spades_broken,
    state: game.state,
    trick: game.trick)
}

pub fn set_current_player(game: Game, current_player: Option(PlayerId)) -> Game {
  Game(
    advance: game.advance,
    current_player: current_player,
    deck: game.deck,
    id: game.id,
    name: game.name,
    play_order: game.play_order,
    players: game.players,
    scores: game.scores,
    spades_broken: game.spades_broken,
    state: game.state,
    trick: game.trick)
}

pub fn set_deck(game: Game, deck: List(Card)) -> Game {
  Game(
    advance: game.advance,
    current_player: game.current_player,
    deck: deck,
    id: game.id,
    name: game.name,
    play_order: game.play_order,
    players: game.players,
    scores: game.scores,
    spades_broken: game.spades_broken,
    state: game.state,
    trick: game.trick)
}

pub fn set_play_order(game: Game, play_order: List(PlayerId)) -> Game {
  Game(
    advance: game.advance,
    current_player: game.current_player,
    deck: game.deck,
    id: game.id,
    name: game.name,
    play_order: play_order,
    players: game.players,
    scores: game.scores,
    spades_broken: game.spades_broken,
    state: game.state,
    trick: game.trick)
}

pub fn set_players(game: Game, players: Map(PlayerId, Player)) -> Game {
  Game(
    advance: game.advance,
    current_player: game.current_player,
    deck: game.deck,
    id: game.id,
    name: game.name,
    play_order: game.play_order,
    players: players,
    scores: game.scores,
    spades_broken: game.spades_broken,
    state: game.state,
    trick: game.trick)
}

pub fn set_scores(game: Game, scores: Map(Team, Int)) -> Game {
  Game(
    advance: game.advance,
    current_player: game.current_player,
    deck: game.deck,
    id: game.id,
    name: game.name,
    play_order: game.play_order,
    players: game.players,
    scores: scores,
    spades_broken: game.spades_broken,
    state: game.state,
    trick: game.trick)
}

pub fn set_spades_broken(game: Game, spades_broken: Bool) -> Game {
  Game(
    advance: game.advance,
    current_player: game.current_player,
    deck: game.deck,
    id: game.id,
    name: game.name,
    play_order: game.play_order,
    players: game.players,
    scores: game.scores,
    spades_broken: spades_broken,
    state: game.state,
    trick: game.trick)
}

pub fn set_state(game: Game, state: GameState) -> Game {
  Game(
    advance: game.advance,
    current_player: game.current_player,
    deck: game.deck,
    id: game.id,
    name: game.name,
    play_order: game.play_order,
    players: game.players,
    scores: game.scores,
    spades_broken: game.spades_broken,
    state: state,
    trick: game.trick)
}

pub fn set_trick(game: Game, trick: List(Trick)) -> Game {
  Game(
    advance: game.advance,
    current_player: game.current_player,
    deck: game.deck,
    id: game.id,
    name: game.name,
    play_order: game.play_order,
    players: game.players,
    scores: game.scores,
    spades_broken: game.spades_broken,
    state: game.state,
    trick: trick)
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
  Game(
    advance: False,
    current_player: None,
    deck: case deck {
      Some(d) -> d
      None -> new_deck()
    },
    id: id,
    name: name,
    play_order: [],
    players: map.new(),
    scores: map.from_list([tuple(NorthSouth, 0), tuple(EastWest, 0)]),
    spades_broken: False,
    state: Waiting,
    trick: [])
}

pub fn deal_cards(game: Game) -> Game {
  case map.size(game.players) {
    4 -> {
      let players = map.values(game.players)
      game.deck
      |> list.index_map(fn(index, card) { tuple(index, card) })
      |> list.fold(map.new(), fn(p, m) {
        let index = pair.first(p) % 4
        [tuple(index, [])]
        |> map.from_list
        |> map.merge(m)
        |> map.update(index, fn(v) {
          case v {
            Ok(l) -> list.append(l, [pair.second(p)])
            _ -> []
          }
        })
      })
      |> map.values
      |> list.zip(players)
      |> list.fold(list.new(), fn(p, l) {
        let player =
          pair.second(p)
          |> receive_cards(pair.first(p))
        list.append(l, [tuple(player.id, player)])
      })
      |> map.from_list
      |> set_players(game, _)
    }
    _ -> game
  }
}

pub fn start_bidding(game: Game) -> Game {
  case map.size(game.players) {
    4 -> set_state(game, Bidding)
    _ -> game
  }
}

pub fn add_player(game: Game, player: Player) -> Game {
  let is_full = map.size(game.players) == 4
  let player_exists = map.has_key(game.players, player.id)
  let team_count =
    game.players
    |> map.filter(fn(_, v: Player) { v.team == player.team })
    |> map.size

  case is_full || player_exists || team_count == 2 {
    True -> game
    _ -> {
      game.players
      |> map.insert(player.id, player)
      |> set_players(game, _)
      |> deal_cards
      |> start_bidding
    }
  }
}
