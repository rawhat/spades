defmodule Spades.Game.GameTest do
  use ExUnit.Case

  alias Spades.Game
  alias Spades.Game.Deck
  alias Spades.Game.Player

  setup_all do
    p1 = Player.new("alex", 0)
    p2 = Player.new("jon", 0)
    p3 = Player.new("jake", 1)
    p4 = Player.new("gopal", 1)

    deck = Deck.new()

    game =
      Game.new(deck)
      |> Game.add_player(p1)
      |> Game.add_player(p2)
      |> Game.add_player(p3)
      |> Game.add_player(p4)
      |> Game.make_call(p1.name, 0)
      |> Game.make_call(p2.name, 3)
      |> Game.make_call(p3.name, 3)
      |> Game.make_call(p4.name, 4)

    one = Map.get(game.players, p1.name)
    two = Map.get(game.players, p2.name)
    three = Map.get(game.players, p3.name)
    four = Map.get(game.players, p4.name)

    {:ok, deck: deck, p1: one, p2: two, p3: three, p4: four, game: game}
  end

  test "is playing after seed", %{game: game} do
    assert game.state == :playing
  end

  test "play card for first player", %{p1: p1, game: game} do
    g = Game.play_card(game, p1.name, Enum.at(p1.hand.cards, 0))

    assert Enum.count(g.trick) == 1
  end

  test "play four cards, assign trick", %{p1: p1, p2: p2, p3: p3, p4: p4, game: game} do
    g =
      Game.play_card(game, p1.name, Enum.at(p1.hand.cards, 0))
      |> Game.play_card(p2.name, Enum.at(p2.hand.cards, 0))
      |> Game.play_card(p3.name, Enum.at(p3.hand.cards, 0))
      |> Game.play_card(p4.name, Enum.at(p4.hand.cards, 0))

    IO.puts("hi")
    IO.inspect(g)

    assert Enum.count(g.trick) == 0
  end

  test "play all cards, round ends", %{p1: p1, p2: p2, p3: p3, p4: p4, game: game} do
    g =
      0..12
      |> Enum.reduce(game, fn index, game ->
        Game.play_card(game, p1.name, Enum.at(p1.hand.cards, index))
        |> Game.play_card(p2.name, Enum.at(p2.hand.cards, index))
        |> Game.play_card(p3.name, Enum.at(p3.hand.cards, index))
        |> Game.play_card(p4.name, Enum.at(p4.hand.cards, index))
      end)

    assert g.scores[0] != 0
  end
end
