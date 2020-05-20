defmodule Spades.Game.GameTest do
  use ExUnit.Case

  alias Spades.Game
  alias Spades.Game.Card
  alias Spades.Game.Player

  setup_all do
    p1 = Player.new("0", "alex", :north_south)
    p2 = Player.new("1", "jake", :east_west)
    p3 = Player.new("2", "jon", :north_south)
    p4 = Player.new("3", "gopal", :east_west)

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
      Game.new("1", "one", deck)
      |> Game.add_player(p1)
      |> Game.add_player(p2)
      |> Game.add_player(p3)
      |> Game.add_player(p4)
      |> Game.make_call(p1.id, 0)
      |> Game.make_call(p2.id, 3)
      |> Game.make_call(p3.id, 3)
      |> Game.make_call(p4.id, 4)

    one = Map.get(game.players, p1.id)
    two = Map.get(game.players, p2.id)
    three = Map.get(game.players, p3.id)
    four = Map.get(game.players, p4.id)

    {:ok, deck: deck, p1: one, p2: two, p3: three, p4: four, game: game}
  end

  test "is playing after seed", %{game: game} do
    assert game.state == :playing
  end

  test "play card for first player", %{p1: p1, game: game} do
    g = Game.play_card(game, p1.id, Enum.at(p1.hand.cards, 0))

    assert Enum.count(g.trick) == 1
  end

  test "play four cards, assign trick", %{game: game, deck: deck, p1: p1, p2: p2, p3: p3, p4: p4} do
    g =
      Game.play_card(game, p1.id, Enum.at(deck, 0))
      |> Game.play_card(p2.id, Enum.at(deck, 1))
      |> Game.play_card(p3.id, Enum.at(deck, 2))
      |> Game.play_card(p4.id, Enum.at(deck, 3))

    assert Enum.count(g.trick) == 0
    assert g.players[p1.id].hand.tricks == 1
    assert g.current_player == 0
  end

  test "play all cards, round ends", %{game: game, deck: deck, p1: p1, p2: p2, p3: p3, p4: p4} do
    g =
      Game.play_card(game, p1.id, Enum.at(deck, 0))
      |> Game.play_card(p2.id, Enum.at(deck, 1))
      |> Game.play_card(p3.id, Enum.at(deck, 2))
      |> Game.play_card(p4.id, Enum.at(deck, 3))
      |> Game.play_card(p1.id, Enum.at(deck, 4))
      |> Game.play_card(p2.id, Enum.at(deck, 5))
      |> Game.play_card(p3.id, Enum.at(deck, 6))
      |> Game.play_card(p4.id, Enum.at(deck, 7))

    assert g.scores == %{:north_south => -79, :east_west => -70}
    assert g.current_player == 0
    assert Enum.at(g.play_order, 0) == p2.id
  end

  test "can't play non-matching card", %{game: game, deck: deck, p1: p1, p2: p2} do
    g =
      Game.play_card(game, p1.id, Enum.at(deck, 0))
      |> Game.play_card(p2.id, Enum.at(deck, 5))

    assert g.trick == [%{id: p1.id, card: Enum.at(deck, 0)}]
  end

  test "spades not broken, can't lead with spades", %{p1: p1, p2: p2, p3: p3, p4: p4} do
    deck = [
      Card.new(:diamond, 2),
      Card.new(:diamond, 3),
      Card.new(:diamond, 4),
      Card.new(:diamond, 5),
      Card.new(:spades, 2),
      Card.new(:hearts, 2),
      Card.new(:hearts, 3),
      Card.new(:hearts, 4)
    ]

    game =
      Game.new("1", "one", deck)
      |> Game.add_player(p1)
      |> Game.add_player(p2)
      |> Game.add_player(p3)
      |> Game.add_player(p4)
      |> Game.make_call(p1.id, 1)
      |> Game.make_call(p2.id, 1)
      |> Game.make_call(p3.id, 1)
      |> Game.make_call(p4.id, 1)
      |> Game.play_card(p1.id, Card.new(:spades, 2))

    assert game.trick == []
  end

  test "only have spades, can lead with spades", %{p1: p1, p2: p2, p3: p3, p4: p4} do
    deck = [
      Card.new(:spades, 2),
      Card.new(:diamond, 3),
      Card.new(:diamond, 4),
      Card.new(:diamond, 5)
    ]

    game =
      Game.new("1", "one", deck)
      |> Game.add_player(p1)
      |> Game.add_player(p2)
      |> Game.add_player(p3)
      |> Game.add_player(p4)
      |> Game.make_call(p1.id, 1)
      |> Game.make_call(p2.id, 1)
      |> Game.make_call(p3.id, 1)
      |> Game.make_call(p4.id, 1)
      |> Game.play_card(p1.id, Card.new(:spades, 2))

    assert game.trick == [%{id: p1.id, card: Card.new(:spades, 2)}]
  end

  test "once spades are broken, they can be lead", %{p1: p1, p2: p2, p3: p3, p4: p4} do
    deck = [
      Card.new(:diamond, 2),
      Card.new(:diamond, 3),
      Card.new(:hearts, 4),
      Card.new(:hearts, 5),
      #
      Card.new(:diamond, 4),
      Card.new(:diamond, 5),
      Card.new(:spades, 4),
      Card.new(:spades, 5),
      #
      Card.new(:diamond, 6),
      Card.new(:diamond, 7),
      Card.new(:spades, 6),
      Card.new(:spades, 7)
    ]

    game =
      Game.new("1", "one", deck)
      |> Game.add_player(p1)
      |> Game.add_player(p2)
      |> Game.add_player(p3)
      |> Game.add_player(p4)
      |> Game.make_call(p1.id, 1)
      |> Game.make_call(p2.id, 1)
      |> Game.make_call(p3.id, 1)
      |> Game.make_call(p4.id, 1)
      |> Game.play_card(p1.id, Enum.at(deck, 0))
      |> Game.play_card(p2.id, Enum.at(deck, 1))
      |> Game.play_card(p3.id, Enum.at(deck, 6))
      |> Game.play_card(p4.id, Enum.at(deck, 7))
      |> Game.play_card(p4.id, Enum.at(deck, 11))

    assert game.trick == [%{id: p4.id, card: Enum.at(deck, 11)}]
  end

  test "leading suit with all offsuit wins", %{p1: p1, p2: p2, p3: p3, p4: p4} do
    deck = [
      Card.new(:diamond, 13),
      Card.new(:diamond, 4),
      Card.new(:hearts, 10),
      Card.new(:clubs, 5),
      #
      Card.new(:clubs, 4),
      Card.new(:clubs, 6),
      Card.new(:spades, 4),
      Card.new(:spades, 5)
    ]

    game =
      Game.new("1", "one", deck)
      |> Game.add_player(p1)
      |> Game.add_player(p2)
      |> Game.add_player(p3)
      |> Game.add_player(p4)
      |> Game.make_call(p1.id, 1)
      |> Game.make_call(p2.id, 1)
      |> Game.make_call(p3.id, 1)
      |> Game.make_call(p4.id, 1)
      |> Game.play_card(p1.id, Enum.at(deck, 0))
      |> Game.play_card(p2.id, Enum.at(deck, 1))
      |> Game.play_card(p3.id, Enum.at(deck, 2))
      |> Game.play_card(p4.id, Enum.at(deck, 3))

    assert game.current_player == 0
  end
end
