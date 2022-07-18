import gleam/json.{Json}
import gleam/list
import gleam/option.{Option, Some}
import spades/game/hand.{Call, Hand}
import spades/game/card.{Card}

pub type Position {
  North
  East
  South
  West
}

pub fn position_to_json(position: Position) -> Json {
  case position {
    North -> json.string("north")
    South -> json.string("south")
    East -> json.string("east")
    West -> json.string("west")
  }
}

pub type Team {
  EastWest
  NorthSouth
}

pub fn team_to_json(team: Team) -> Json {
  case team {
    NorthSouth -> json.string("north_south")
    EastWest -> json.string("east_west")
  }
}

pub type Player {
  Player(id: Int, name: String, position: Position, hand: Hand)
}

pub type PublicPlayer {
  PublicPlayer(
    cards: Int,
    call: Option(Call),
    id: Int,
    name: String,
    position: Position,
    team: Team,
    tricks: Int,
    revealed: Bool,
  )
}

pub fn to_public(player: Player) -> PublicPlayer {
  PublicPlayer(
    cards: list.length(player.hand.cards),
    call: player.hand.call,
    id: player.id,
    name: player.name,
    position: player.position,
    team: position_to_team(player),
    tricks: player.hand.tricks,
    revealed: player.hand.revealed,
  )
}

pub fn public_to_json(player: PublicPlayer) -> Json {
  json.object([
    #("cards", json.int(player.cards)),
    #("call", json.nullable(player.call, fn(call) { hand.call_to_json(call) })),
    #("id", json.int(player.id)),
    #("name", json.string(player.name)),
    #("position", position_to_json(player.position)),
    #("team", team_to_json(player.team)),
    #("tricks", json.int(player.tricks)),
    #("revealed", json.bool(player.revealed)),
  ])
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
