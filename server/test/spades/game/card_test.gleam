import gleam/order.{Eq, Gt, Lt}
import spades/game/card.{
  Ace, Card, Clubs, Diamonds, Hearts, Jack, King, Number, Queen, Spades,
}
import startest/expect

pub fn same_suit_number_test() {
  let one = Card(Diamonds, Number(2))
  let two = Card(Diamonds, Number(10))

  card.compare(one, two)
  |> expect.to_equal(Lt)
}

pub fn suit_ranking_number_test() {
  let one = Card(Spades, Number(2))
  let two = Card(Diamonds, Number(10))

  card.compare(one, two)
  |> expect.to_equal(Lt)
}

pub fn face_card_greater_test() {
  let one = Card(Spades, Ace)
  let two = Card(Spades, Jack)

  card.compare(one, two)
  |> expect.to_equal(Gt)
}

pub fn face_card_equal_test() {
  let one = Card(Spades, Jack)
  let two = Card(Spades, Jack)

  card.compare(one, two)
  |> expect.to_equal(Eq)
}

pub fn face_card_less_test() {
  let one = Card(Spades, Queen)
  let two = Card(Spades, King)

  card.compare(one, two)
  |> expect.to_equal(Lt)
}

pub fn max_with_match_test() {
  let cards = [
    Card(Diamonds, Number(2)),
    Card(Hearts, Ace),
    Card(Diamonds, Ace),
    Card(Diamonds, Number(10)),
  ]

  card.max_of_suit(cards, Diamonds)
  |> expect.to_equal(Ok(Card(Diamonds, Ace)))
}

pub fn max_with_no_match_test() {
  let cards = [
    Card(Diamonds, Number(2)),
    Card(Hearts, Ace),
    Card(Diamonds, Ace),
    Card(Diamonds, Number(10)),
  ]

  card.max_of_suit(cards, Spades)
  |> expect.to_equal(Error(Nil))
}

pub fn min_with_match_test() {
  let cards = [
    Card(Diamonds, Number(2)),
    Card(Hearts, Number(2)),
    Card(Diamonds, Ace),
    Card(Diamonds, Number(10)),
  ]

  card.min_of_suit(cards, Diamonds)
  |> expect.to_equal(Ok(Card(Diamonds, Number(2))))
}

pub fn min_with_no_match_test() {
  let cards = [
    Card(Diamonds, Number(2)),
    Card(Hearts, Number(2)),
    Card(Diamonds, Ace),
    Card(Diamonds, Number(10)),
  ]

  card.min_of_suit(cards, Clubs)
  |> expect.to_equal(Error(Nil))
}

pub fn to_string_test() {
  let one = Card(Hearts, Queen)

  card.to_string(one)
  |> expect.to_equal("QH")
}

pub fn hand_sorting_test() {
  let cards = [
    Card(Diamonds, Number(10)),
    Card(Hearts, Ace),
    Card(Diamonds, Queen),
    Card(Spades, Jack),
    Card(Spades, Number(2)),
    Card(Clubs, Number(9)),
    Card(Hearts, Number(3)),
    Card(Clubs, Number(4)),
  ]

  card.hand_sort(cards)
  |> expect.to_equal([
    Card(Spades, Number(2)),
    Card(Spades, Jack),
    Card(Diamonds, Number(10)),
    Card(Diamonds, Queen),
    Card(Clubs, Number(4)),
    Card(Clubs, Number(9)),
    Card(Hearts, Number(3)),
    Card(Hearts, Ace),
  ])
}

fn list_at(list: List(a), index: Int) -> Result(a, Nil) {
  case list, index {
    [], _ -> Error(Nil)
    [value, ..], 0 -> Ok(value)
    [_, ..rest], i -> list_at(rest, i - 1)
  }
}

pub fn make_deck_test() {
  let actual = card.make_deck()

  actual
  |> list_at(0)
  |> expect.to_equal(Ok(Card(Clubs, Number(2))))

  actual
  |> list_at(1)
  |> expect.to_equal(Ok(Card(Diamonds, Number(3))))

  actual
  |> list_at(2)
  |> expect.to_equal(Ok(Card(Hearts, Number(4))))

  actual
  |> list_at(3)
  |> expect.to_equal(Ok(Card(Spades, Number(5))))

  actual
  |> list_at(13)
  |> expect.to_equal(Ok(Card(Diamonds, Number(2))))

  actual
  |> list_at(51)
  |> expect.to_equal(Ok(Card(Spades, Ace)))
}
