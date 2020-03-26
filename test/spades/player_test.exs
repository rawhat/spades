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
      Player.new("alex", 0)
      |> Player.receive_cards(only_spades)

    jon =
      Player.new("jon", 0)
      |> Player.receive_cards(all_cards)

    jake =
      Player.new("jake", 1)
      |> Player.receive_cards(only_spades)

    gopal =
      Player.new("gopal", 1)
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
    assert Player.get_team_players(player_map, 0) == [alex, jon]
  end

  test "when only spades, can play spades", %{alex: alex} do
    assert Player.can_play_spade?(alex, :heart, false) == true
  end

  test "when other suits, can't play spades", %{jon: jon} do
    assert Player.can_play_spade?(jon, :hearts, false) == false
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

    assert Player.get_score([alex, jon]) == 50
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

    assert Player.get_score([alex, jon]) == 52
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

    assert Player.get_score([alex, jon]) == -50
  end

  test "score with nil", %{alex: alex, jon: jon} do
    alex = Player.make_call(alex, 0)
    jon =
      Player.make_call(jon, 3)
      |> Player.take()
      |> Player.take()
      |> Player.take()
      |> Player.take()

    assert Player.get_score([alex, jon]) == 81
  end
end
