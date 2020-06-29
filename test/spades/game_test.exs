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
      Card.new(:diamonds, 1),
      Card.new(:diamonds, 6),
      Card.new(:diamonds, 5),
      Card.new(:diamonds, 4),

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

    assert g.last_trick == [
             %{id: p1.id, card: Enum.at(deck, 0)},
             %{id: p2.id, card: Enum.at(deck, 1)},
             %{id: p3.id, card: Enum.at(deck, 2)},
             %{id: p4.id, card: Enum.at(deck, 3)}
           ]
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

    assert g.scores == %{
             :north_south => %{points: -80, bags: 0},
             :east_west => %{points: -70, bags: 0}
           }

    assert g.current_player == 0
    assert Enum.at(g.play_order, 0) == p2.id
    assert g.state == :bidding
    assert g.last_trick == []

    assert Enum.all?(g.players, fn {_, player} ->
             Enum.count(player.hand.cards) != 0
           end)
  end

  test "can't play non-matching card", %{game: game, deck: deck, p1: p1, p2: p2} do
    {:error, g, _reason} =
      Game.play_card(game, p1.id, Enum.at(deck, 0))
      |> Game.play_card(p2.id, Enum.at(deck, 5))

    assert g.trick == [%{id: p1.id, card: Enum.at(deck, 0)}]
  end

  test "spades not broken, can't lead with spades", %{p1: p1, p2: p2, p3: p3, p4: p4} do
    deck = [
      Card.new(:diamonds, 2),
      Card.new(:diamonds, 3),
      Card.new(:diamonds, 4),
      Card.new(:diamonds, 5),
      Card.new(:spades, 2),
      Card.new(:hearts, 2),
      Card.new(:hearts, 3),
      Card.new(:hearts, 4)
    ]

    {:error, game, reason} =
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
    assert String.contains?(reason, "2S")
  end

  test "only have spades, can lead with spades", %{p1: p1, p2: p2, p3: p3, p4: p4} do
    deck = [
      Card.new(:spades, 2),
      Card.new(:diamonds, 3),
      Card.new(:diamonds, 4),
      Card.new(:diamonds, 5)
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
      Card.new(:diamonds, 2),
      Card.new(:diamonds, 3),
      Card.new(:hearts, 4),
      Card.new(:hearts, 5),
      #
      Card.new(:diamonds, 4),
      Card.new(:diamonds, 5),
      Card.new(:spades, 4),
      Card.new(:spades, 5),
      #
      Card.new(:diamonds, 6),
      Card.new(:diamonds, 7),
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
      Card.new(:diamonds, 13),
      Card.new(:diamonds, 4),
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

  test "bagging out deducts points from score" do
    starting_cards = [
      :spades,
      :diamonds,
      :hearts,
      :clubs
    ]

    card_values =
      2..8
      |> Stream.flat_map(fn num ->
        Stream.repeatedly(fn -> num end)
        |> Stream.take(4)
        |> Enum.to_list()
      end)

    deck =
      starting_cards
      |> Stream.cycle()
      |> Stream.zip(card_values)
      |> Stream.map(fn {suit, value} -> Card.new(suit, value) end)
      |> Stream.take(28)
      |> Enum.to_list()

    p1 = Player.new("0", "alex", :north_south)
    p2 = Player.new("1", "jake", :east_west)
    p3 = Player.new("2", "jon", :north_south)
    p4 = Player.new("3", "gopal", :east_west)

    with_players =
      [p1, p2, p3, p4]
      |> Stream.cycle()
      |> Stream.take(28)
      |> Enum.to_list()

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

    next_game =
      Enum.zip(with_players, deck)
      |> Enum.reduce(game, fn {player, card}, g ->
        Game.play_card(g, player.id, card)
      end)

    assert next_game.state == :bidding
    # p1's team bagged out
    #   so:  2 tricks * 10 - 50 for bagging out, with 5 bags
    assert next_game.scores == %{
             north_south: %{points: -30, bags: 5},
             east_west: %{points: -20, bags: 0}
           }

    assert Game.state(next_game).scores == %{
             north_south: -25,
             east_west: -20
           }
  end

  test "can't call blind nil after revealing cards" do
    p1 = Player.new("0", "alex", :north_south)
    p2 = Player.new("1", "jake", :east_west)
    p3 = Player.new("2", "jon", :north_south)
    p4 = Player.new("3", "gopal", :east_west)

    {:error, game, _reason} =
      Game.new("2", "test")
      |> Game.add_player(p1)
      |> Game.add_player(p2)
      |> Game.add_player(p3)
      |> Game.add_player(p4)
      |> Game.reveal_cards(p1.id)
      |> Game.call(p1.id, -1)

    assert game.players["0"].hand.call == nil
  end

  test "can reveal cards out of turn, but not call" do
    p1 = Player.new("0", "alex", :north_south)
    p2 = Player.new("1", "jake", :east_west)
    p3 = Player.new("2", "jon", :north_south)
    p4 = Player.new("3", "gopal", :east_west)

    revealed =
      Game.new("2", "test")
      |> Game.add_player(p1)
      |> Game.add_player(p2)
      |> Game.add_player(p3)
      |> Game.add_player(p4)
      |> Game.reveal_cards(p4.id)

    assert revealed.players[p4.id].hand.revealed == true

    assert {:error, _game, _reason} = Game.call(revealed, p4.id, 4)
  end
end
