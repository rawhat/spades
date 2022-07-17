import gleeunit/should
import gleam/list
import gleam/map
import spades/game/card.{Card}
import spades/game/game.{Failure, Success}
import spades/game/hand.{Count}
import spades/game/player.{North, NorthSouth, Player, South}
import spades/game/scaffold

pub fn add_player_updates_game_test() {
  let g = game.new(1, "test-game", "1")
  let player = Player(id: "1", name: "alex", position: North, hand: hand.new())

  assert Success(g, _events) = game.add_player(g, player)

  should.equal(g.players, map.from_list([#(player.id, player)]))
  should.equal(g.teams, map.from_list([#(NorthSouth, [player.id])]))
  should.equal(g.player_position, map.from_list([#(North, player.id)]))
}

pub fn add_duplicate_position_errors_test() {
  let g = game.new(1, "test-game", "1")
  let player = Player(id: "1", name: "alex", position: North, hand: hand.new())

  assert Success(g, _events) = game.add_player(g, player)

  game.add_player(g, player)
  |> should.equal(Failure(g, game.TeamFull))
}

pub fn add_team_overflow_errors_test() {
  let g = game.new(1, "test-game", "1")
  let p1 = Player(id: "1", name: "alex", position: North, hand: hand.new())
  let p2 = Player(id: "2", name: "jon", position: South, hand: hand.new())
  let p3 = Player(id: "3", name: "billy", position: North, hand: hand.new())

  assert Success(g, _events) = game.add_player(g, p1)
  assert Success(g, _events) = game.add_player(g, p2)

  game.add_player(g, p3)
  |> should.equal(Failure(g, game.TeamFull))
}

pub fn add_more_than_four_errors_test() {
  let #(g, _players) = scaffold.populate_game()
  let p5 = Player(id: "5", name: "krampus", position: North, hand: hand.new())

  game.add_player(g, p5)
  |> should.equal(Failure(g, game.GameFull))
}

pub fn add_player_to_start_bidding_test() {
  let #(g, _players) = scaffold.populate_game()

  should.equal(g.state, game.Bidding)

  assert Ok(p1) = map.get(g.players, "1")

  list.length(p1.hand.cards)
  |> should.equal(13)
}

pub fn bidding_finished_play_card_test() {
  let #(g, [p1, p2, p3, p4]) = scaffold.populate_game()
  assert Success(g, _events) =
    g
    |> game.make_call(p1.id, Count(3))
    |> game.then(game.make_call(_, p3.id, Count(3)))
    |> game.then(game.make_call(_, p2.id, Count(3)))
    |> game.then(game.make_call(_, p4.id, Count(3)))

  should.equal(g.state, game.Playing)
  should.equal(g.current_player, North)
}

pub fn playing_valid_card_adds_to_trick_test() {
  let first_card = Card(card.Diamonds, card.Number(10))
  let deck = [
    Card(card.Diamonds, card.Number(7)),
    Card(card.Diamonds, card.Number(8)),
    Card(card.Diamonds, card.Number(9)),
    first_card,
  ]

  let #(g, [p1, p2, p3, p4]) = scaffold.populate_game_with_deck(deck)

  assert Success(g, _events) =
    g
    |> game.make_call(p1.id, Count(3))
    |> game.then(game.make_call(_, p3.id, Count(3)))
    |> game.then(game.make_call(_, p2.id, Count(3)))
    |> game.then(game.make_call(_, p4.id, Count(3)))
    |> game.then(game.play_card(_, p1.id, first_card))

  should.equal(g.trick, [game.Play(p1.id, first_card)])
}

pub fn playing_not_leading_suit_fails_test() {
  let first_card = Card(card.Diamonds, card.Number(10))
  let second_card = Card(card.Hearts, card.Number(9))
  let deck = [
    Card(card.Hearts, card.Number(7)),
    Card(card.Hearts, card.Number(8)),
    second_card,
    Card(card.Hearts, card.Number(10)),
    Card(card.Diamonds, card.Number(7)),
    Card(card.Diamonds, card.Number(8)),
    Card(card.Diamonds, card.Number(9)),
    first_card,
  ]

  let #(g, [p1, p2, p3, p4]) = scaffold.populate_game_with_deck(deck)

  assert Success(g, _events) =
    g
    |> game.make_call(p1.id, Count(3))
    |> game.then(game.make_call(_, p3.id, Count(3)))
    |> game.then(game.make_call(_, p2.id, Count(3)))
    |> game.then(game.make_call(_, p4.id, Count(3)))
    |> game.then(game.play_card(_, p1.id, first_card))

  g
  |> game.play_card(p3.id, second_card)
  |> should.equal(Failure(g, game.InvalidSuit))
}

pub fn playing_spade_when_not_broken_fails_test() {
  let first_card = Card(card.Diamonds, card.Number(10))
  let second_card = Card(card.Spades, card.Number(2))
  let deck = [
    Card(card.Hearts, card.Number(7)),
    Card(card.Hearts, card.Number(8)),
    second_card,
    Card(card.Hearts, card.Number(10)),
    Card(card.Diamonds, card.Number(7)),
    Card(card.Diamonds, card.Number(8)),
    Card(card.Diamonds, card.Number(9)),
    first_card,
  ]

  let #(g, [p1, p2, p3, p4]) = scaffold.populate_game_with_deck(deck)

  assert Success(g, _events) =
    g
    |> game.make_call(p1.id, Count(3))
    |> game.then(game.make_call(_, p3.id, Count(3)))
    |> game.then(game.make_call(_, p2.id, Count(3)))
    |> game.then(game.make_call(_, p4.id, Count(3)))
    |> game.then(game.play_card(_, p1.id, first_card))

  g
  |> game.play_card(p3.id, second_card)
  |> should.equal(Failure(g, game.InvalidSuit))
}

pub fn playing_a_full_round_completes_trick_and_scores_test() {
  let first_card = Card(card.Diamonds, card.Number(10))
  let second_card = Card(card.Diamonds, card.Number(9))
  let third_card = Card(card.Diamonds, card.Number(8))
  let fourth_card = Card(card.Diamonds, card.Number(7))
  let deck = [fourth_card, third_card, second_card, first_card]

  let #(g, [p1, p2, p3, p4]) = scaffold.populate_game_with_deck(deck)

  assert Success(g, _events) =
    g
    |> game.make_call(p1.id, Count(1))
    |> game.then(game.make_call(_, p3.id, Count(1)))
    |> game.then(game.make_call(_, p2.id, Count(0)))
    |> game.then(game.make_call(_, p4.id, Count(1)))
    |> game.then(game.play_card(_, p1.id, first_card))
    |> game.then(game.play_card(_, p3.id, second_card))
    |> game.then(game.play_card(_, p2.id, third_card))
    |> game.then(game.play_card(_, p4.id, fourth_card))

  should.equal(g.state, game.Bidding)
  assert Ok(north_south_score) = map.get(g.scores, NorthSouth)
  should.equal(north_south_score, hand.Score(10, 0))
}
