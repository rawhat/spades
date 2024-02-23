import gleam/dynamic.{type Decoder, DecodeError, field}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import spades/game/card.{type Card, Spades}

pub type Score {
  Score(points: Int, bags: Int)
}

pub type Call {
  BlindNil
  Nil
  Count(Int)
}

pub type Play {
  Play(player: Int, card: Card)
}

pub fn find_winning_card(trick: Trick) -> Card {
  let assert [leading, ..] = trick
  let leading_suit = leading.card.suit
  let assert Ok(max_leading) =
    trick
    |> list.map(fn(play) { play.card })
    |> card.max_of_suit(leading_suit)
  let max_spade =
    trick
    |> list.map(fn(play) { play.card })
    |> card.max_of_suit(Spades)

  case max_spade, max_leading {
    Ok(match), _ | Error(_), match -> match
  }
}

pub fn find_winner(trick: Trick) -> Int {
  let card = find_winning_card(trick)
  let assert Ok(Play(player: winner, ..)) =
    list.find(trick, fn(t) { t.card == card })
  winner
}

pub fn play_to_json(play: Play) -> Json {
  json.object([
    #("id", json.int(play.player)),
    #("card", card.to_json(play.card)),
  ])
}

pub type Trick =
  List(Play)

pub fn call_decoder() -> Decoder(Call) {
  dynamic.any([
    fn(value) {
      dynamic.string(value)
      |> result.then(fn(call) {
        case call {
          "blind_nil" -> Ok(BlindNil)
          "nil" -> Ok(Nil)
          _ -> Error([DecodeError("call", call, [])])
        }
      })
    },
    field("count", fn(value) {
      dynamic.int(value)
      |> result.map(Count)
    }),
  ])
}

pub fn call_to_json(call: Call) -> Json {
  case call {
    BlindNil -> json.int(-2)
    Nil -> json.int(-1)
    Count(n) -> json.int(n)
  }
}

pub type Hand {
  Hand(cards: List(Card), tricks: Int, call: Option(Call), revealed: Bool)
}

pub fn new() -> Hand {
  Hand(cards: [], tricks: 0, call: None, revealed: False)
}

fn combine(left: Score, right: Score) -> Score {
  Score(left.points + right.points, left.bags + right.bags)
}

fn score_hand(call: Option(Call), tricks: Int) -> Score {
  let assert Some(call) = call
  case call, tricks {
    Nil, n if n > 0 -> Score(-50, n)
    Nil, _ -> Score(50, 0)
    BlindNil, n if n > 0 -> Score(-100, n)
    BlindNil, _ -> Score(100, 0)
    Count(called), taken if taken >= called ->
      Score(called * 10, taken - called)
    Count(called), _ -> Score(called * 10 * -1, 0)
  }
}

pub fn team_score(left: Hand, right: Hand) -> Score {
  let #(nil_hand, not_nil_hands) =
    list.partition([left, right], fn(hand) {
      hand.call == Some(Nil) || hand.call == Some(BlindNil)
    })

  case nil_hand, not_nil_hands {
    [left], [right] | [left, right], [] -> {
      let left = score_hand(left.call, left.tricks)
      let right = score_hand(right.call, right.tricks)
      combine(left, right)
    }
    [], [left, right] -> {
      let assert Some(Count(left_call)) = left.call
      let assert Some(Count(right_call)) = right.call
      score_hand(
        Some(Count(left_call + right_call)),
        left.tricks + right.tricks,
      )
    }
    _, _ -> Score(0, 0)
  }
}

pub fn remove_card(hand: Hand, card: Card) -> Hand {
  Hand(..hand, cards: list.filter(hand.cards, fn(c) { c != card }))
}

pub fn score_to_int(score: Score) -> Int {
  score.points + score.bags
}
