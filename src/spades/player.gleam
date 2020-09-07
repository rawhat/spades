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

pub type PlayerId =
  String

pub type Player {
  Player(id: PlayerId, name: String, team: Team, hand: Option(Hand))
}

pub type PublicPlayer {
  PublicPlayer(
    cards: Int,
    call: Option(Call),
    id: String,
    name: String,
    team: Team,
    tricks: Int,
    revealed: Bool,
  )
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
    team: player.team,
    tricks: hand.tricks,
    revealed: hand.revealed,
  )
}
