import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/order.{type Order, Eq, Gt, Lt}
import gleam/result
import gleam/string
import gleam/yielder

pub type Suit {
  Clubs
  Diamonds
  Hearts
  Spades
}

pub type Value {
  Number(Int)
  Jack
  Queen
  King
  Ace
}

pub fn compare_suit(left: Card, right: Card) -> Order {
  case left.suit, right.suit {
    a, b if a == b -> Eq
    Spades, _ -> Lt
    Diamonds, Spades -> Gt
    Diamonds, _ -> Lt
    Clubs, Spades -> Gt
    Clubs, Diamonds -> Gt
    Clubs, _ -> Lt
    Hearts, Spades -> Gt
    Hearts, Diamonds -> Gt
    Hearts, Clubs -> Gt
    _, _ -> Lt
  }
}

pub fn compare_value(left: Card, right: Card) -> Order {
  case left.value, right.value {
    a, b if a == b -> Eq
    Number(n), Number(m) -> int.compare(n, m)
    Number(_value), _ -> Lt
    Ace, _ -> Gt
    King, Ace -> Lt
    King, _ -> Gt
    Queen, Ace -> Lt
    Queen, King -> Lt
    Queen, _ -> Gt
    Jack, Ace -> Lt
    Jack, King -> Lt
    Jack, Queen -> Lt
    Jack, _ -> Gt
  }
}

pub fn compare(left: Card, right: Card) -> Order {
  case compare_suit(left, right) {
    Eq -> compare_value(left, right)
    suit_order -> suit_order
  }
}

pub type Card {
  Card(suit: Suit, value: Value)
}

fn suit_decoder() -> Decoder(Suit) {
  decode.string
  |> decode.then(fn(suit) {
    case suit {
      "C" -> decode.success(Clubs)
      "D" -> decode.success(Diamonds)
      "H" -> decode.success(Hearts)
      "S" -> decode.success(Spades)
      _ -> decode.failure(Clubs, "Suit")
    }
  })
}

fn value_decoder() -> Decoder(Value) {
  decode.string
  |> decode.then(fn(value) {
    decode.one_of(decode.int |> decode.map(Number), or: [
      case value {
        "J" -> decode.success(Jack)
        "Q" -> decode.success(Queen)
        "K" -> decode.success(King)
        "A" -> decode.success(Ace)
        _ -> decode.failure(Number(0), "Value")
      },
    ])
  })
}

pub fn decoder() -> Decoder(Card) {
  use suit <- decode.field("suit", suit_decoder())
  use value <- decode.field("value", value_decoder())
  decode.success(Card(suit, value))
}

fn order_of(cards: List(Card), suit: Suit, order: Order) -> Result(Card, Nil) {
  cards
  |> list.filter(fn(card) { card.suit == suit })
  |> list.fold(Error(Nil), fn(res, card) {
    res
    |> result.map(fn(existing) {
      case compare(existing, card) {
        ordering if ordering == order -> card
        _ -> existing
      }
    })
    |> result.unwrap(card)
    |> Ok
  })
}

pub fn max_of_suit(cards: List(Card), suit: Suit) -> Result(Card, Nil) {
  order_of(cards, suit, Lt)
}

pub fn min_of_suit(cards: List(Card), suit: Suit) -> Result(Card, Nil) {
  order_of(cards, suit, Gt)
}

pub fn min_value(cards: List(Card)) -> Result(Card, Nil) {
  cards
  |> list.sort(compare)
  |> list.first
}

pub fn max_value(cards: List(Card)) -> Result(Card, Nil) {
  cards
  |> list.sort(compare)
  |> list.reverse
  |> list.first
}

pub fn suit_to_string(suit: Suit) -> String {
  case suit {
    Clubs -> "C"
    Diamonds -> "D"
    Hearts -> "H"
    Spades -> "S"
  }
}

pub fn value_to_string(value: Value) -> String {
  case value {
    Number(n) -> int.to_string(n)
    Jack -> "J"
    Queen -> "Q"
    King -> "K"
    Ace -> "A"
  }
}

pub fn to_json(card: Card) -> Json {
  json.object([
    #("suit", json.string(suit_to_string(card.suit))),
    #("value", json.string(value_to_string(card.value))),
  ])
}

pub fn to_string(card: Card) -> String {
  let suit = suit_to_string(card.suit)
  let value = value_to_string(card.value)

  string.append(value, suit)
}

pub fn hand_sort(cards: List(Card)) -> List(Card) {
  list.sort(cards, compare)
}

pub type Deck =
  List(Card)

pub fn make_deck() -> Deck {
  let suits = yielder.from_list([Clubs, Diamonds, Hearts, Spades])

  let values =
    list.range(2, 10)
    |> list.map(Number)
    |> list.append([Jack, Queen, King, Ace])
    |> yielder.from_list

  values
  |> yielder.cycle
  |> yielder.take(52)
  |> yielder.zip(yielder.cycle(suits))
  |> yielder.map(fn(card) {
    let #(value, suit) = card
    Card(suit, value)
  })
  |> yielder.to_list
}
