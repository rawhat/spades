import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import spades/card
import spades/player.{BlindNil, Call, Nil, Player, Value}
import spades/util.{partition}

pub type Score {
  Score(points: Int, bags: Int)
}

pub fn new_score() -> Score {
  Score(points: 0, bags: 0)
}

pub fn add(new_score: Score, old_score: Score) -> Score {
  let new_points = old_score.points + new_score.points
  case tuple(old_score.bags, old_score.bags + new_score.bags) {
    // Bagging out twice means (2 * bag out penalty + 10 for carry over)
    tuple(old, new) if old < 5 && new >= 10 ->
      Score(points: new_points - 100 + 10, bags: new - 10)
    // Bagging out once to 5-10
    tuple(old, new) if old < 5 && new >= 5 ->
      Score(points: new_points - 50, bags: new)
    // Bagging out once to 10+, bag out penalty + carry over
    tuple(old, new) if old >= 5 && new >= 10 ->
      Score(points: new_points - 50 + 10, bags: new - 10)
    tuple(_, new) -> Score(points: new_points, bags: new)
  }
}

pub fn score_from_call(call_and_taken: tuple(Call, Int)) -> Score {
  case call_and_taken {
    tuple(BlindNil, 0) -> Score(points: 100, bags: 0)
    tuple(BlindNil, _) -> Score(points: -100, bags: 0)
    tuple(Nil, 0) -> Score(points: 50, bags: 0)
    tuple(Nil, _) -> Score(points: -50, bags: 0)
    tuple(Value(called), taken) if called > taken ->
      Score(points: -10 * called, bags: 0)
    tuple(Value(called), taken) if taken >= called ->
      Score(points: 10 * called, bags: taken - called)
  }
}

pub fn calculate_score(players: List(Player)) -> Score {
  let calls_and_taken =
    players
    |> list.map(fn(player: Player) {
      case player.hand {
        Some(player.Hand(call: Some(call), tricks: tricks, ..)) ->
          Some(tuple(call, tricks))
        _ -> None
      }
    })
  let nil_not_nil =
    partition(
      calls_and_taken,
      fn(call) {
        case call {
          Some(tuple(Nil, _)) | Some(tuple(BlindNil, _)) -> True
          _ -> False
        }
      },
    )
  case nil_not_nil {
    tuple(
      [],
      [
        Some(tuple(Value(value: call1), taken1)),
        Some(tuple(Value(value: call2), taken2)),
      ],
    ) ->
      case tuple(call1 + call2, taken1 + taken2) {
        tuple(call, taken) if call > taken -> Score(points: -10 * call, bags: 0)
        tuple(call, taken) if taken >= call ->
          Score(points: call * 10, bags: taken - call)
      }
    tuple(nils, not_nils) ->
      list.append(nils, not_nils)
      |> list.fold(
        new_score(),
        fn(item, score) {
          item
          |> option.unwrap(tuple(Value(value: 0), 0))
          |> score_from_call
          |> add(score)
        },
      )
  }
}
