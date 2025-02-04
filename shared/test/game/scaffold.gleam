import game/card.{type Deck}
import game/game.{type Game, Success}
import game/hand
import game/player.{type Player, East, North, Player, South, West}
import gleam/function

pub fn populate_game() -> #(Game, List(Player)) {
  let p1 = Player(id: 1, name: "alex", position: North, hand: hand.new())
  let p2 = Player(id: 2, name: "jon", position: South, hand: hand.new())
  let p3 = Player(id: 3, name: "billy", position: East, hand: hand.new())
  let p4 = Player(id: 4, name: "jake", position: West, hand: hand.new())

  let assert Success(g, _events) =
    game.new(1, "test-game", "1")
    |> game.set_shuffle(function.identity)
    |> game.add_player(p1)
    |> game.then(game.add_player(_, p2))
    |> game.then(game.add_player(_, p3))
    |> game.then(game.add_player(_, p4))

  #(g, [p1, p2, p3, p4])
}

pub fn populate_game_with_deck(deck: Deck) -> #(Game, List(Player)) {
  let p1 = Player(id: 1, name: "alex", position: North, hand: hand.new())
  let p2 = Player(id: 2, name: "jon", position: South, hand: hand.new())
  let p3 = Player(id: 3, name: "billy", position: East, hand: hand.new())
  let p4 = Player(id: 4, name: "jake", position: West, hand: hand.new())

  let assert Success(g, _events) =
    game.new(1, "test-game", "1")
    |> game.set_shuffle(function.identity)
    |> game.set_deck(deck)
    |> game.add_player(p1)
    |> game.then(game.add_player(_, p2))
    |> game.then(game.add_player(_, p3))
    |> game.then(game.add_player(_, p4))

  #(g, [p1, p2, p3, p4])
}
