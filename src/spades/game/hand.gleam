import gleam/list
import gleam/option.{None, Option, Some}
import spades/game/card.{Card}

pub type Score {
  Score(points: Int, bags: Int)
}

pub type Call {
  BlindNil
  Nil
  Count(Int)
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
  assert Some(call) = call
  case call, tricks {
    Nil, n if n > 0 -> Score(-50, n)
    BlindNil, n if n > 0 -> Score(-100, n)
    Count(called), taken if taken >= called ->
      Score(called * 10, taken - called)
    Count(called), _ -> Score(called * 10 * -1, 0)
  }
}

pub fn team_score(left: Hand, right: Hand) -> Score {
  let #(nil_hand, not_nil_hands) =
    list.partition(
      [left, right],
      fn(hand) { hand.call == Some(Nil) || hand.call == Some(BlindNil) },
    )

  case nil_hand, not_nil_hands {
    [left], [right] | [left, right], [] -> {
      let left = score_hand(left.call, left.tricks)
      let right = score_hand(right.call, right.tricks)
      combine(left, right)
    }
    [], [left, right] -> {
      assert Some(Count(left_call)) = left.call
      assert Some(Count(right_call)) = right.call
      score_hand(
        Some(Count(left_call + right_call)),
        left.tricks + right.tricks,
      )
    }
  }
}

pub fn remove_card(hand: Hand, card: Card) -> Hand {
  Hand(..hand, cards: list.filter(hand.cards, fn(c) { c != card }))
}
