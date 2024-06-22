import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/order
import gleam/result
import spades/game/card.{
  type Card, type Suit, type Value, Ace, Jack, King, Queen, Spades,
}
import spades/game/hand.{
  type Call, type Play, type Trick, BlindNil, Count, Nil as NilCall,
}
import spades/game/player.{type Player, East, North, South, West}

pub fn call(players: Dict(Int, Player), bot: Player) -> Call {
  let total_calls = existing_calls(players)

  let hand_score = score_hand(bot)

  let has_ace_of_spades =
    list.any(bot.hand.cards, fn(card) {
      card.suit == Spades && card.value == Ace
    })

  let teammate = get_teammate(players, bot)

  case option.to_result(teammate.hand.call, Nil) {
    Ok(call) if call == Count(0) || call == NilCall || call == BlindNil ->
      float.ceiling(int.to_float(13 - total_calls) *. 3.0 /. 2.0)
      |> float.ceiling
      |> float.round
      |> int.min(13 - total_calls)
      |> int.max(hand_score)
      |> Count
    Ok(_call)
      if total_calls >= 9 && hand_score < 3 && has_ace_of_spades == False
    -> NilCall
    _ ->
      case total_calls + hand_score > 13 {
        True -> Count(13 - total_calls)
        False -> Count(hand_score)
      }
  }
}

pub fn play_card(
  players: Dict(Int, Player),
  spades_broken: Bool,
  trick: List(Play),
  bot: Player,
) -> Card {
  let assert Some(call) = bot.hand.call
  case call {
    BlindNil | NilCall -> play_for_nil(trick, bot)
    _ -> play_to_win(players, spades_broken, trick, bot)
  }
}

fn existing_calls(players: Dict(Int, Player)) -> Int {
  players
  |> dict.values
  |> list.filter_map(fn(player) { option.to_result(player.hand.call, Nil) })
  |> list.fold(0, fn(acc, call) {
    case call {
      Count(n) -> acc + n
      _ -> acc
    }
  })
}

fn score_hand(bot: Player) -> Int {
  bot.hand.cards
  |> list.map(fn(card) { card.value })
  |> list.map(ranking_from_card)
  |> list.fold(0.0, fn(acc, ranking) { acc +. ranking })
  |> float.ceiling
  |> float.round
}

fn get_teammate(players: Dict(Int, Player), bot: Player) -> Player {
  let position = case bot.position {
    North -> South
    West -> East
    South -> North
    East -> West
  }

  let assert Ok(teammate) =
    players
    |> dict.values
    |> list.find(fn(player) { player.position == position })

  teammate
}

fn ranking_from_card(value: Value) -> Float {
  case value {
    Ace -> 1.0
    King -> 0.75
    Queen -> 0.5
    Jack -> 0.25
    _ -> 0.0
  }
}

fn play_for_nil(trick: Trick, bot: Player) -> Card {
  case trick {
    [] -> {
      let non_spades =
        bot.hand.cards
        |> list.filter(fn(card) { card.suit != Spades })
        |> card.min_value
      case non_spades {
        Error(Nil) -> {
          let assert Ok(min) = card.min_of_suit(bot.hand.cards, Spades)
          min
        }
        Ok(min) -> min
      }
    }
    [lead, ..] -> {
      let suited_cards =
        bot.hand.cards
        |> list.filter(fn(card) { card.suit == lead.card.suit })
      case suited_cards {
        [] ->
          bot.hand.cards
          |> list.filter(fn(card) { card.suit != Spades })
          |> card.max_value
          |> result.lazy_unwrap(fn() {
            let assert Ok(min_spade) = card.min_of_suit(bot.hand.cards, Spades)
            min_spade
          })
        suited ->
          suited
          |> list.filter(fn(c) { card.compare(c, lead.card) == order.Lt })
          |> card.max_value
          |> result.lazy_unwrap(fn() {
            let assert Ok(broken) = card.max_value(suited)
            broken
          })
      }
    }
  }
}

fn play_to_win(
  players: Dict(Int, Player),
  spades_broken: Bool,
  trick: Trick,
  bot: Player,
) -> Card {
  case trick {
    [] -> winning_card([], spades_broken, bot.hand.cards)
    trick -> {
      let assert Ok(lead_suit) =
        trick
        |> list.first
        |> result.map(fn(play) { play.card.suit })
      let assert Ok(trick_leader) =
        trick
        |> hand.find_winner
        |> dict.get(players, _)
      let teammate = get_teammate(players, bot)
      let assert Some(teammate_call) = teammate.hand.call
      let let_teammate_win =
        trick_leader.id == teammate.id
        && { teammate_call != BlindNil || teammate_call != NilCall }
      case let_teammate_win {
        True -> low_card(lead_suit, bot.hand.cards)
        False -> winning_card(trick, spades_broken, bot.hand.cards)
      }
    }
  }
}

fn low_card(lead_suit: Suit, cards: List(Card)) -> Card {
  let lowest_suited_card = card.min_of_suit(cards, lead_suit)
  let low_throwaway =
    cards
    |> list.filter(fn(card) { card.suit != lead_suit && card.suit != Spades })
    |> card.min_value
  let spades_throwaway = card.min_of_suit(cards, Spades)

  case lowest_suited_card, low_throwaway, spades_throwaway {
    Ok(card), _, _ -> card
    Error(Nil), Ok(card), _ -> card
    Error(Nil), Error(Nil), Ok(card) -> card
    _, _, _ -> {
      let assert [card, ..] = cards
      card
    }
  }
}

fn winning_card(
  trick: List(Play),
  spades_broken: Bool,
  cards: List(Card),
) -> Card {
  case trick {
    [] -> {
      let assert Ok(card) =
        cards
        |> list.sort(card.compare)
        |> list.reverse
        |> fn(ordered: List(Card)) {
          case spades_broken {
            False -> list.filter(ordered, fn(card) { card.suit != Spades })
            True -> ordered
          }
        }
        |> list.first
      card
    }
    [lead, ..] -> {
      let lead_suit = lead.card.suit
      let highest_spade = card.max_of_suit(cards, Spades)
      let suited_cards = list.filter(cards, fn(card) { card.suit == lead_suit })
      case suited_cards {
        [] ->
          case highest_spade {
            Ok(spade) -> spade
            _ -> {
              let assert Ok(min) = card.min_value(cards)
              min
            }
          }
        _ ->
          suited_cards
          |> card.max_of_suit(lead_suit)
          |> result.then(fn(max) {
            case card.compare(max, lead.card) {
              order.Lt -> card.min_of_suit(suited_cards, lead_suit)
              order.Gt | _ -> Ok(max)
            }
          })
          |> result.lazy_unwrap(fn() {
            let assert Ok(min) = card.min_value(cards)
            highest_spade
            |> result.unwrap(min)
          })
      }
    }
  }
}
