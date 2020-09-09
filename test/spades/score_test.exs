defmodule Spades.Game.Record.ScoreTest do
  use ExUnit.Case

  alias Spades.Game.Record.Hand
  alias Spades.Game.Record.Player
  alias Spades.Game.Record.Score

  setup_all do
    p1 = Player.new("1", "alex", :north_south)
    p2 = Player.new("2", "jon", :north_south)

    {:ok, p1: p1, p2: p2}
  end

  test "score with made tricks", %{p1: p1, p2: p2} do
    hand = Hand.new([])
    p1_hand = %Hand{hand | call: 3, tricks: 3}
    p2_hand = %Hand{hand | call: 2, tricks: 2}

    players = [
      %Player{p1 | hand: p1_hand} |> Player.unparse(),
      %Player{p2 | hand: p2_hand} |> Player.unparse()
    ]

    score =
      :spades@score.calculate_score(players)
      |> Score.from_record()

    assert score == %Score{points: 50, bags: 0}
  end

  test "score made with bags", %{p1: p1, p2: p2} do
    hand = Hand.new([])
    p1_hand = %Hand{hand | call: 3, tricks: 3}
    p2_hand = %Hand{hand | call: 2, tricks: 4}

    players = [
      %Player{p1 | hand: p1_hand} |> Player.unparse(),
      %Player{p2 | hand: p2_hand} |> Player.unparse()
    ]

    score =
      :spades@score.calculate_score(players)
      |> Score.from_record()

    assert score == %Score{points: 50, bags: 2}
  end

  test "score with one made, one broken", %{p1: p1, p2: p2} do
    hand = Hand.new([])
    p1_hand = %Hand{hand | call: 3, tricks: 3}
    p2_hand = %Hand{hand | call: 2, tricks: 1}

    players = [
      %Player{p1 | hand: p1_hand} |> Player.unparse(),
      %Player{p2 | hand: p2_hand} |> Player.unparse()
    ]

    score =
      :spades@score.calculate_score(players)
      |> Score.from_record()

    assert score == %Score{points: -50, bags: 0}
  end

  test "score with nil", %{p1: p1, p2: p2} do
    hand = Hand.new([])
    p1_hand = %Hand{hand | call: 0, tricks: 0}
    p2_hand = %Hand{hand | call: 2, tricks: 3}

    players = [
      %Player{p1 | hand: p1_hand} |> Player.unparse(),
      %Player{p2 | hand: p2_hand} |> Player.unparse()
    ]

    score =
      :spades@score.calculate_score(players)
      |> Score.from_record()

    assert score == %Score{points: 70, bags: 1}
  end

  test "score with combination made", %{p1: p1, p2: p2} do
    hand = Hand.new([])
    p1_hand = %Hand{hand | call: 2, tricks: 3}
    p2_hand = %Hand{hand | call: 2, tricks: 1}

    players = [
      %Player{p1 | hand: p1_hand} |> Player.unparse(),
      %Player{p2 | hand: p2_hand} |> Player.unparse()
    ]

    score =
      :spades@score.calculate_score(players)
      |> Score.from_record()

    assert score == %Score{points: 40, bags: 0}
  end

  test "updating score" do
    old =
      %Score{points: 10, bags: 0}
      |> Score.unparse()

    diff =
      %Score{points: 0, bags: 1}
      |> Score.unparse()

    new =
      :spades@score.add(diff, old)
      |> Score.parse()

    assert new == %Score{points: 10, bags: 1}
  end

  test "bagging out with over 5" do
    old =
      %Score{points: 10, bags: 4}
      |> Score.unparse()

    diff =
      %Score{points: 0, bags: 1}
      |> Score.unparse()

    new =
      :spades@score.add(diff, old)
      |> Score.parse()

    assert new == %Score{points: -40, bags: 5}
  end

  test "bagging out with over 10" do
    old =
      %Score{points: 10, bags: 6}
      |> Score.unparse()

    diff =
      %Score{points: 0, bags: 5}
      |> Score.unparse()

    new =
      :spades@score.add(diff, old)
      |> Score.parse()

    assert new == %Score{points: -30, bags: 1}
  end

  test "double bagging out" do
    old =
      %Score{points: 10, bags: 1}
      |> Score.unparse()

    diff =
      %Score{points: 0, bags: 10}
      |> Score.unparse()

    new =
      :spades@score.add(diff, old)
      |> Score.parse()

    assert new == %Score{points: -80, bags: 1}
  end
end
