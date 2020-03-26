defmodule Spades.Game.GameTest do
  use ExUnit.Case

  alias Spades.Game
  alias Spades.Game.Card
  alias Spades.Game.Player

  setup_all do
    p1 = Player.new("alex", 0)
    p2 = Player.new("jon", 0)
    p3 = Player.new("jake", 1)
    p4 = Player.new("gopal", 1)

    deck = [
      # First hand
      Card.new(:diamond, 1),
      Card.new(:diamond, 6),
      Card.new(:diamond, 5),
      Card.new(:diamond, 4),

      # Second hand
      Card.new(:hearts, 10),
      Card.new(:hearts, 9),
      Card.new(:hearts, 12),
      Card.new(:spades, 2)
    ]

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

  test "play four cards, assign trick", %{game: game, deck: deck, p1: p1} do
    g =
      Game.play_card(game, "alex", Enum.at(deck, 0))
      |> Game.play_card("jon", Enum.at(deck, 1))
      |> Game.play_card("jake", Enum.at(deck, 2))
      |> Game.play_card("gopal", Enum.at(deck, 3))

    assert Enum.count(g.trick) == 0
    assert g.players[p1.name].hand.tricks == 1
    assert g.current_player == 0
  end

  test "play all cards, round ends", %{game: game, deck: deck} do
    g =
      Game.play_card(game, "alex", Enum.at(deck, 0))
      |> Game.play_card("jon", Enum.at(deck, 1))
      |> Game.play_card("jake", Enum.at(deck, 2))
      |> Game.play_card("gopal", Enum.at(deck, 3))
      |> Game.play_card("alex", Enum.at(deck, 4))
      |> Game.play_card("jon", Enum.at(deck, 5))
      |> Game.play_card("jake", Enum.at(deck, 6))
      |> Game.play_card("gopal", Enum.at(deck, 7))

    assert g.scores == %{0 => -79, 1 => -70}
  end
end
