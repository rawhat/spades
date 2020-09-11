defmodule Spades.Game.PlayerTest do
  use ExUnit.Case

  alias Spades.Game.Card
  alias Spades.Game.Player

  setup_all do
    ace_of_spades = Card.new(:spades, 1)
    queen_of_hearts = Card.new(:hearts, 12)
    three_of_diamonds = Card.new(:diamonds, 3)

    only_spades = [ace_of_spades]
    all_cards = [ace_of_spades, three_of_diamonds, queen_of_hearts]

    alex =
      Player.new("0", "alex", :north)
      |> Player.receive_cards(only_spades)

    jon =
      Player.new("1", "jon", :south)
      |> Player.receive_cards(all_cards)

    jake =
      Player.new("2", "jake", :east)
      |> Player.receive_cards(only_spades)

    gopal =
      Player.new("e", "gopal", :west)
      |> Player.receive_cards(all_cards)

    player_map = %{"alex" => alex, "jon" => jon, "jake" => jake, "gopal" => gopal}

    {:ok,
     player_map: player_map,
     alex: alex,
     jon: jon,
     jake: jake,
     gopal: gopal,
     only_spades: only_spades,
     all_cards: all_cards,
     ace_of_spades: ace_of_spades}
  end

  test "get team hands", %{player_map: player_map, alex: alex, jon: jon} do
    assert Player.get_team_players(player_map, :north_south) == [alex, jon]
  end

  test "when only spades in hand, can play spades", %{alex: alex, ace_of_spades: ace_of_spades} do
    assert Player.can_play?(alex, ace_of_spades, nil, false) == true
  end

  test "when spades not broken, can't play spades", %{jon: jon, ace_of_spades: ace_of_spades} do
    assert Player.can_play?(jon, ace_of_spades, nil, false) == false
  end

  test "when hand has lead suit and attempting to play other", %{jon: jon} do
    assert Player.can_play?(jon, Card.new(:hearts, 10), Card.new(:diamond, 10), false) ==
             false
  end

  test "playing card removes from hand", %{alex: alex, ace_of_spades: ace_of_spades} do
    assert Player.play_card(alex, ace_of_spades).hand.cards == []
  end

  test "score with made tricks", %{alex: alex, jon: jon} do
    alex =
      Player.make_call(alex, 3)
      |> Player.take()
      |> Player.take()
      |> Player.take()

    jon =
      Player.make_call(jon, 2)
      |> Player.take()
      |> Player.take()

    assert Player.get_score([alex, jon]) == %{points: 50, bags: 0}
  end

  test "score made with bags", %{alex: alex, jon: jon} do
    alex =
      Player.make_call(alex, 3)
      |> Player.take()
      |> Player.take()
      |> Player.take()

    jon =
      Player.make_call(jon, 2)
      |> Player.take()
      |> Player.take()
      |> Player.take()
      |> Player.take()

    assert Player.get_score([alex, jon]) == %{points: 50, bags: 2}
  end

  test "score with one made, one broken", %{alex: alex, jon: jon} do
    alex =
      Player.make_call(alex, 3)
      |> Player.take()
      |> Player.take()
      |> Player.take()

    jon =
      Player.make_call(jon, 2)
      |> Player.take()

    assert Player.get_score([alex, jon]) == %{points: -50, bags: 0}
  end

  test "score with nil", %{alex: alex, jon: jon} do
    alex = Player.make_call(alex, 0)

    jon =
      Player.make_call(jon, 3)
      |> Player.take()
      |> Player.take()
      |> Player.take()
      |> Player.take()

    assert Player.get_score([alex, jon]) == %{points: 80, bags: 1}
  end

  test "updating score" do
    assert Player.update_score(%{points: 10, bags: 0}, %{points: 0, bags: 1}) == %{
             points: 10,
             bags: 1
           }
  end

  test "bagging out with over 5" do
    assert Player.update_score(%{points: 10, bags: 5}, %{points: 0, bags: 1}) == %{
             points: -40,
             bags: 6
           }
  end

  test "bagging out with over 10" do
    assert Player.update_score(%{points: 10, bags: 6}, %{points: 0, bags: 5}) == %{
             points: -30,
             bags: 1
           }
  end

  test "double bagging out" do
    assert Player.update_score(%{points: 10, bags: 6}, %{points: 0, bags: 4}) == %{
             points: -80,
             bags: 0
           }
  end
end
