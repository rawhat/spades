import gleam/list
import gleam/option.{None, Option, Some}
import spades/card.{Card, Suit}

pub type Call {
  BlindNil
  Nil
  Value(value: Int)
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

pub type Position {
  North
  South
  East
  West
}

pub fn team_from_position(position: Position) -> Team {
  case position {
    North | South -> NorthSouth
    East | West -> EastWest
  }
}

pub type PlayerId =
  String

pub type Player {
  Player(id: PlayerId, name: String, position: Position, hand: Option(Hand))
}

pub type PublicPlayer {
  PublicPlayer(
    cards: Int,
    call: Option(Call),
    id: String,
    name: String,
    position: Position,
    team: Team,
    tricks: Int,
    revealed: Bool,
  )
}

pub fn new_player(id: PlayerId, name: String, position: Position) -> Player {
  Player(id, name, position, None)
}

pub fn receive_cards(player: Player, cards: List(Card)) -> Player {
  Player(..player, hand: Some(new_hand(cards)))
}

pub fn has_suit(player: Player, suit: Suit) -> Bool {
  player.hand
  |> option.map(fn(h: Hand) { h.cards })
  |> option.map(fn(cards: List(Card)) {
    list.any(cards, fn(c: Card) { c.suit == suit })
  })
  |> option.unwrap(False)
}

pub fn to_public(player: Player) -> PublicPlayer {
  let hand =
    player.hand
    |> option.unwrap(Hand(list.new(), 0, None, False))
  PublicPlayer(
    cards: list.length(hand.cards),
    call: hand.call,
    id: player.id,
    name: player.name,
    position: player.position,
    team: team_from_position(player.position),
    tricks: hand.tricks,
    revealed: hand.revealed,
  )
}
