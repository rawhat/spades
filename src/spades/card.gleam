import gleam/int.{to_string}
import gleam/iterator.{from_list, range, to_list}
import gleam/list.{flatten}
import gleam/order.{Eq, Gt, Lt, Order}
import gleam/string.{String, concat}

pub type Suit {
  Clubs
  Hearts
  Diamonds
  Spades
}

pub fn suit_to_string(suit: Suit) -> String {
  case suit {
    Clubs -> "Clubs"
    Hearts -> "Hearts"
    Diamonds -> "Diamonds"
    Spades -> "Spades"
  }
}

pub type Value {
  Ace
  King
  Queen
  Jack
  Number(value: Int)
}

pub fn value_to_string(value: Value) -> String {
  case value {
    Ace -> "Ace"
    King -> "King"
    Queen -> "Queen"
    Jack -> "Jack"
    Number(value: value) -> to_string(value)
  }
}

pub fn value_order(v1: Value, v2: Value) -> Order {
  case tuple(v1, v2) {
    tuple(a, b) if a == b -> Eq
    tuple(Ace, _) -> Lt
    tuple(King, Ace) -> Gt
    tuple(King, _) -> Lt
    tuple(Queen, Ace) -> Gt
    tuple(Queen, King) -> Gt
    tuple(Queen, _) -> Lt
    tuple(Jack, Ace) -> Gt
    tuple(Jack, King) -> Gt
    tuple(Jack, Queen) -> Gt
    tuple(Jack, _) -> Lt
    tuple(Number(n), Number(p)) if n > p -> Lt
    tuple(Number(n), Number(p)) if n < p -> Gt
    tuple(Number(_), _) -> Gt
  }
}

pub type Card {
  Card(suit: Suit, value: Value)
}

pub fn new(suit: Suit, value: Value) -> Card {
  Card(suit: suit, value: value)
}

pub fn string(card: Card) -> String {
  concat([value_to_string(card.value), " of ", suit_to_string(card.suit)])
}

pub fn new_deck() -> List(Card) {
  let values =
    range(from: 2, to: 10)
    |> iterator.map(Number(_))
    |> to_list

  [Ace, King, Queen, Jack, ..values]
  |> from_list
  |> iterator.map(fn(value) {
    [Clubs, Diamonds, Hearts, Spades]
    |> from_list
    |> iterator.map(Card(_, value))
    |> to_list
  })
  |> to_list
  |> flatten
}
