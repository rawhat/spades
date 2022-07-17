import gleam/list
import gleam/option.{Some}
import spades/game/hand.{Call, Hand}
import spades/game/card.{Card}

pub type Position {
  North
  East
  South
  West
}

pub type Team {
  EastWest
  NorthSouth
}

pub type Player {
  Player(id: String, name: String, position: Position, hand: Hand)
}

pub type PublicPlayer {
  PublicPlayer(
    cards: Int,
    call: Call,
    id: String,
    name: String,
    position: Position,
    team: Team,
    tricks: Int,
    revealed: Bool,
  )
}

pub fn position_to_team(player: Player) -> Team {
  case player.position {
    North | South -> NorthSouth
    East | West -> EastWest
  }
}

pub fn receive_cards(player: Player, cards: List(Card)) -> Player {
  Player(..player, hand: Hand(..player.hand, cards: cards))
}

pub fn make_call(player: Player, call: Call) -> Player {
  Player(..player, hand: Hand(..player.hand, call: Some(call)))
}

pub fn has_card(player: Player, card: Card) -> Bool {
  list.contains(player.hand.cards, card)
}

pub fn add_trick(player: Player) -> Player {
  Player(..player, hand: Hand(..player.hand, tricks: player.hand.tricks + 1))
}
