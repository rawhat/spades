import gleam/dict
import gleam/function
import gleam/list
import gleeunit/should
import spades/game/card.{Card}
import spades/game/game.{Bidding, Failure, InvalidSuit, Playing, Success}
import spades/game/hand.{Count, Play}
import spades/game/player.{East, North, NorthSouth, Player, South, West}
import spades/game/scaffold

pub fn add_player_updates_game_test() {
  let g = game.new(1, "test-game", "1")
  let player = Player(id: 1, name: "alex", position: North, hand: hand.new())

  let assert Success(g, _events) = game.add_player(g, player)

  should.equal(g.players, dict.from_list([#(player.id, player)]))
  should.equal(g.teams, dict.from_list([#(NorthSouth, [player.id])]))
  should.equal(g.player_position, dict.from_list([#(North, player.id)]))
}

pub fn add_duplicate_position_errors_test() {
  let g = game.new(1, "test-game", "1")
  let player = Player(id: 1, name: "alex", position: North, hand: hand.new())

  let assert Success(g, _events) = game.add_player(g, player)

  game.add_player(g, player)
  |> should.equal(Failure(g, game.TeamFull))
}

pub fn add_team_overflow_errors_test() {
  let g = game.new(1, "test-game", "1")
  let p1 = Player(id: 1, name: "alex", position: North, hand: hand.new())
  let p2 = Player(id: 2, name: "jon", position: South, hand: hand.new())
  let p3 = Player(id: 3, name: "billy", position: North, hand: hand.new())

  let assert Success(g, _events) = game.add_player(g, p1)
  let assert Success(g, _events) = game.add_player(g, p2)

  game.add_player(g, p3)
  |> should.equal(Failure(g, game.TeamFull))
}

pub fn add_more_than_four_errors_test() {
  let #(g, _players) = scaffold.populate_game()
  let p5 = Player(id: 5, name: "krampus", position: North, hand: hand.new())

  game.add_player(g, p5)
  |> should.equal(Failure(g, game.GameFull))
}

pub fn add_player_to_start_bidding_test() {
  let #(g, _players) = scaffold.populate_game()

  should.equal(g.state, game.Bidding)

  let assert Ok(p1) = dict.get(g.players, 1)

  list.length(p1.hand.cards)
  |> should.equal(13)
}

pub fn bidding_finished_play_card_test() {
  let #(g, [p1, p2, p3, p4]) = scaffold.populate_game()
  let assert Success(g, _events) =
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

  let assert Success(g, _events) =
    g
    |> game.make_call(p1.id, Count(3))
    |> game.then(game.make_call(_, p3.id, Count(3)))
    |> game.then(game.make_call(_, p2.id, Count(3)))
    |> game.then(game.make_call(_, p4.id, Count(3)))
    |> game.then(game.play_card(_, p1.id, first_card))

  should.equal(g.trick, [Play(p1.id, first_card)])
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

  let assert Success(g, _events) =
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

  let assert Success(g, _events) =
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
  let first_card = Card(card.Diamonds, card.Number(8))
  let second_card = Card(card.Diamonds, card.Number(9))
  let third_card = Card(card.Diamonds, card.Number(10))
  let fourth_card = Card(card.Diamonds, card.Number(7))
  let deck = [fourth_card, third_card, second_card, first_card]

  let #(g, [p1, p2, p3, p4]) = scaffold.populate_game_with_deck(deck)

  let assert Success(g, _events) =
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
  let assert Ok(north_south_score) = dict.get(g.scores, NorthSouth)
  should.equal(north_south_score, hand.Score(10, 0))
  should.equal(g.current_player, p2.position)
}

pub fn find_winner_with_same_suit_test() {
  let trick = [
    Play(player: 1, card: Card(card.Diamonds, card.Number(2))),
    Play(player: 3, card: Card(card.Diamonds, card.Number(6))),
    Play(player: 2, card: Card(card.Diamonds, card.Number(4))),
    Play(player: 4, card: Card(card.Diamonds, card.Ace)),
  ]

  trick
  |> hand.find_winner
  |> should.equal(4)
}

pub fn find_winner_with_all_else_offsuit_test() {
  let trick = [
    Play(player: 1, card: Card(card.Diamonds, card.Number(2))),
    Play(player: 3, card: Card(card.Clubs, card.Number(6))),
    Play(player: 2, card: Card(card.Hearts, card.Number(4))),
    Play(player: 4, card: Card(card.Hearts, card.Ace)),
  ]

  trick
  |> hand.find_winner
  |> should.equal(1)
}

pub fn find_winner_with_spade_test() {
  let trick = [
    Play(player: 1, card: Card(card.Diamonds, card.Number(2))),
    Play(player: 3, card: Card(card.Spades, card.Jack)),
    Play(player: 2, card: Card(card.Hearts, card.Number(4))),
    Play(player: 4, card: Card(card.Spades, card.Number(7))),
  ]

  trick
  |> hand.find_winner
  |> should.equal(3)
}

pub fn play_spades_when_having_other_suits_and_not_broken_test() {
  let deck = [
    Card(card.Diamonds, card.Number(2)),
    Card(card.Diamonds, card.Number(8)),
    Card(card.Diamonds, card.Number(7)),
    Card(card.Diamonds, card.Number(6)),
    Card(card.Hearts, card.Number(4)),
    Card(card.Clubs, card.Number(2)),
    Card(card.Hearts, card.Number(2)),
    Card(card.Spades, card.Number(2)),
    Card(card.Diamonds, card.Number(5)),
    Card(card.Diamonds, card.Number(4)),
    Card(card.Diamonds, card.Number(3)),
    Card(card.Diamonds, card.Number(9)),
  ]

  let #(g, [p1, p2, p3, p4]) = scaffold.populate_game_with_deck(deck)

  let assert Success(g, _events) =
    g
    |> game.make_call(p1.id, Count(1))
    |> game.then(game.make_call(_, p3.id, Count(1)))
    |> game.then(game.make_call(_, p2.id, Count(0)))
    |> game.then(game.make_call(_, p4.id, Count(1)))
    |> game.then(game.play_card(_, p1.id, Card(card.Diamonds, card.Number(9))))
    |> game.then(game.play_card(_, p3.id, Card(card.Diamonds, card.Number(3))))
    |> game.then(game.play_card(_, p2.id, Card(card.Diamonds, card.Number(4))))
    |> game.then(game.play_card(_, p4.id, Card(card.Diamonds, card.Number(5))))

  g
  |> game.play_card(p1.id, Card(card.Spades, card.Number(2)))
  |> should.equal(Failure(g, InvalidSuit))
}

pub fn play_with_multiple_bots_proceeds_through_states_test() {
  let deck = [
    Card(card.Diamonds, card.Number(2)),
    Card(card.Diamonds, card.Number(8)),
    Card(card.Diamonds, card.Number(7)),
    Card(card.Diamonds, card.Number(6)),
    Card(card.Hearts, card.Number(4)),
    Card(card.Clubs, card.Number(2)),
    Card(card.Hearts, card.Number(2)),
    Card(card.Spades, card.Number(2)),
  ]
  let human = player.new(1, "alex", North)

  let assert Success(g, _events) =
    game.new(0, "test", "alex")
    |> game.set_shuffle(function.identity)
    |> game.set_deck(deck)
    |> game.add_player(human)
    |> game.then(game.add_bot(_, South))
    |> game.then(game.add_bot(_, East))
    |> game.then(game.add_bot(_, West))

  should.equal(g.state, Bidding)

  let assert Success(g, _events) = game.make_call(g, human.id, Count(1))

  should.equal(g.state, Playing)

  let assert Success(g, _events) =
    game.play_card(g, human.id, Card(card.Diamonds, card.Number(6)))

  should.equal(g.current_player, North)
}
