defmodule Spades.Game.HandTest do
  use ExUnit.Case

  alias Spades.Game.Card
  alias Spades.Game.Hand

  setup do
    ace_of_spades = Card.new(:spades, 1)
    two_of_hearts = Card.new(:hearts, 2)

    hand = Hand.new([ace_of_spades, two_of_hearts])

    {:ok, hand: hand, ace_of_spades: ace_of_spades, two_of_hearts: two_of_hearts}
  end

  test "nil hand returns is_nil?", %{hand: hand} do
    nil_hand = Hand.call(hand, 0)

    assert Hand.is_nil?(nil_hand) == true
  end

  test "non-nil hand returns false", %{hand: hand} do
    non_nil_hand = Hand.call(hand, 1)

    assert Hand.is_nil?(non_nil_hand) == false
  end

  test "scoring nil hand", %{hand: hand} do
    nil_hand = Hand.call(hand, 0)

    assert Hand.score(nil_hand) == 50
  end

  test "scoring broken nil hand", %{hand: hand} do
    broken_nil =
      Hand.call(hand, 0)
      |> Hand.take()

    assert Hand.score(broken_nil) == -49
  end

  test "scoring made tricks hand", %{hand: hand} do
    five_tricks_made =
      Hand.call(hand, 5)
      |> Hand.take()
      |> Hand.take()
      |> Hand.take()
      |> Hand.take()
      |> Hand.take()

    assert Hand.score(five_tricks_made) == 50
  end

  test "scoring broken tricks hand", %{hand: hand} do
    five_tricks_broken =
      Hand.call(hand, 5)
      |> Hand.take()
      |> Hand.take()
      |> Hand.take()
      |> Hand.take()

    assert Hand.score(five_tricks_broken) == -50
  end
end
