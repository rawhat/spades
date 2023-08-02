import gleam/map.{Map}
import gleam/option.{Some}
import gleeunit/should
import spades/game/bot
import spades/game/card.{Ace, Card, Diamonds, Hearts, King, Number, Spades}
import spades/game/hand.{Call, Count, Nil, Play}
import spades/game/player.{East, North, Player, South, West}

fn make_players() {
  map.from_list([
    #(2, player.new(2, "other1", East)),
    #(3, player.new(3, "other2", West)),
    #(4, player.new(4, "teammate", South)),
  ])
}

fn update_call(
  players: Map(Int, Player),
  id: Int,
  call: Call,
) -> Map(Int, Player) {
  map.update(
    players,
    id,
    fn(existing) {
      let assert Some(other1) = existing
      player.make_call(other1, call)
    },
  )
}

pub fn leading_call_with_strong_hand_test() {
  player.new(1, "bot", North)
  |> player.receive_cards([Card(Spades, Ace), Card(Diamonds, King)])
  |> bot.call(make_players(), _)
  |> should.equal(Count(2))
}

pub fn leading_call_with_weak_hand_test() {
  player.new(1, "bot", North)
  |> player.receive_cards([Card(Spades, Number(4)), Card(Diamonds, Number(3))])
  |> bot.call(make_players(), _)
  |> should.equal(Count(0))
}

pub fn middle_call_with_strong_hand_test() {
  let players =
    make_players()
    |> update_call(2, Count(6))
    |> update_call(3, Count(6))

  player.new(1, "bot", North)
  |> player.receive_cards([Card(Spades, Ace), Card(Diamonds, King)])
  |> bot.call(players, _)
  |> should.equal(Count(1))
}

pub fn covering_teammate_nil_test() {
  let players =
    make_players()
    |> update_call(2, Count(3))
    |> update_call(3, Count(3))
    |> update_call(4, Nil)

  player.new(1, "bot", North)
  |> player.receive_cards([Card(Spades, Ace), Card(Diamonds, King)])
  |> bot.call(players, _)
  |> should.equal(Count(7))
}

pub fn playing_to_win_force_to_play_suited_test() {
  let players =
    make_players()
    |> update_call(2, Count(3))
    |> update_call(3, Count(3))
    |> update_call(4, Nil)

  player.new(1, "bot", North)
  |> player.receive_cards([Card(Spades, Ace), Card(Diamonds, King)])
  |> player.make_call(Count(3))
  |> bot.play_card(
    players,
    False,
    [
      Play(2, Card(Diamonds, Number(6))),
      Play(3, Card(Diamonds, Number(7))),
      Play(4, Card(Diamonds, Number(8))),
    ],
    _,
  )
  |> should.equal(Card(Diamonds, King))
}

pub fn playing_to_win_try_to_win_with_higher_test() {
  let players =
    make_players()
    |> update_call(2, Count(3))
    |> update_call(3, Count(3))
    |> update_call(4, Nil)

  player.new(1, "bot", North)
  |> player.receive_cards([Card(Spades, Ace), Card(Diamonds, King)])
  |> player.make_call(Count(3))
  |> bot.play_card(
    players,
    False,
    [
      Play(2, Card(Diamonds, Number(6))),
      Play(3, Card(Diamonds, Number(7))),
      Play(4, Card(Diamonds, Number(2))),
    ],
    _,
  )
  |> should.equal(Card(Diamonds, King))
}

pub fn playing_to_win_uses_spade_to_win_test() {
  let players =
    make_players()
    |> update_call(2, Count(3))
    |> update_call(3, Count(3))
    |> update_call(4, Nil)

  player.new(1, "bot", North)
  |> player.receive_cards([Card(Spades, Ace), Card(Diamonds, King)])
  |> player.make_call(Count(3))
  |> bot.play_card(
    players,
    False,
    [
      Play(2, Card(Hearts, Number(6))),
      Play(3, Card(Hearts, Number(7))),
      Play(4, Card(Hearts, Number(2))),
    ],
    _,
  )
  |> should.equal(Card(Spades, Ace))
}

pub fn playing_to_win_lets_teammate_win_test() {
  let players =
    make_players()
    |> update_call(2, Count(3))
    |> update_call(3, Count(3))
    |> update_call(4, Nil)

  player.new(1, "bot", North)
  |> player.receive_cards([Card(Spades, Ace), Card(Diamonds, King)])
  |> player.make_call(Count(3))
  |> bot.play_card(
    players,
    False,
    [
      Play(2, Card(Hearts, Number(6))),
      Play(3, Card(Hearts, Number(7))),
      Play(4, Card(Hearts, Number(10))),
    ],
    _,
  )
  |> should.equal(Card(Diamonds, King))
}

pub fn playing_to_win_spades_when_possible_test() {
  let players =
    make_players()
    |> update_call(2, Count(3))
    |> update_call(3, Count(3))
    |> update_call(4, Nil)

  player.new(1, "bot", North)
  |> player.receive_cards([Card(Spades, Ace), Card(Diamonds, King)])
  |> player.make_call(Count(3))
  |> bot.play_card(
    players,
    False,
    [
      Play(2, Card(Hearts, Number(6))),
      Play(3, Card(Hearts, Number(10))),
      Play(4, Card(Hearts, Number(7))),
    ],
    _,
  )
  |> should.equal(Card(Spades, Ace))
}

pub fn playing_for_nil_leads_with_low_card_test() {
  let players =
    make_players()
    |> update_call(2, Count(3))
    |> update_call(3, Count(3))
    |> update_call(4, Nil)

  player.new(1, "bot", North)
  |> player.receive_cards([Card(Hearts, Number(10)), Card(Hearts, Number(2))])
  |> player.make_call(Nil)
  |> bot.play_card(players, False, [], _)
  |> should.equal(Card(Hearts, Number(2)))
}

pub fn playing_for_nil_plays_highest_card_under_test() {
  let players =
    make_players()
    |> update_call(2, Count(3))
    |> update_call(3, Count(3))
    |> update_call(4, Nil)

  player.new(1, "bot", North)
  |> player.receive_cards([Card(Hearts, Number(10)), Card(Hearts, Number(2))])
  |> player.make_call(Nil)
  |> bot.play_card(
    players,
    False,
    [
      Play(2, Card(Hearts, Number(6))),
      Play(3, Card(Hearts, Number(7))),
      Play(4, Card(Hearts, King)),
    ],
    _,
  )
  |> should.equal(Card(Hearts, Number(10)))
}
