import gleam/dynamic.{DecodeError, Decoder, field}
import gleam/int
import gleam/iterator
import gleam/json.{Json}
import gleam/list
import gleam/order.{Eq, Gt, Lt, Order}
import gleam/result
import gleam/string

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
  fn(value) {
    value
    |> dynamic.string
    |> result.then(fn(suit) {
      case suit {
        "C" -> Ok(Clubs)
        "D" -> Ok(Diamonds)
        "H" -> Ok(Hearts)
        "S" -> Ok(Spades)
        _ -> Error([DecodeError("suit", suit, [])])
      }
    })
  }
}

fn value_decoder() -> Decoder(Value) {
  fn(value) {
    value
    |> dynamic.string
    |> result.then(fn(value) {
      case value {
        "J" -> Ok(Jack)
        "Q" -> Ok(Queen)
        "K" -> Ok(King)
        "A" -> Ok(Ace)
        number ->
          number
          |> int.parse
          |> result.map(Number)
          |> result.replace_error([DecodeError("value", number, [])])
      }
    })
  }
}

pub fn decoder() -> Decoder(Card) {
  dynamic.decode2(
    Card,
    field("suit", suit_decoder()),
    field("value", value_decoder()),
  )
}

fn order_of(cards: List(Card), suit: Suit, order: Order) -> Result(Card, Nil) {
  cards
  |> list.filter(fn(card) { card.suit == suit })
  |> list.fold(
    Error(Nil),
    fn(res, card) {
      res
      |> result.map(fn(existing) {
        case compare(existing, card) {
          ordering if ordering == order -> card
          _ -> existing
        }
      })
      |> result.unwrap(card)
      |> Ok
    },
  )
}

pub fn max_of_suit(cards: List(Card), suit: Suit) -> Result(Card, Nil) {
  order_of(cards, suit, Lt)
}

pub fn min_of_suit(cards: List(Card), suit: Suit) -> Result(Card, Nil) {
  order_of(cards, suit, Gt)
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
  let suits = iterator.from_list([Clubs, Diamonds, Hearts, Spades])

  let values =
    list.range(2, 10)
    |> list.map(Number)
    |> list.append([Jack, Queen, King, Ace])
    |> iterator.from_list

  values
  |> iterator.cycle
  |> iterator.take(52)
  |> iterator.zip(iterator.cycle(suits))
  |> iterator.map(fn(card) {
    let #(value, suit) = card
    Card(suit, value)
  })
  |> iterator.to_list
}

pub fn shuffle(deck: Deck) -> Deck {
  list.shuffle(deck)
}
