defmodule Spades.Game.BotTest do
  use ExUnit.Case

  alias Spades.Game
  alias Spades.Game.Player

  setup_all do
    p1 = Player.new("1", "alex", :north)

    {:error, game, "Game is finished"} =
      Game.new("1", "test")
      |> Game.add_bot(:north)
      |> Game.add_bot(:south)
      |> Game.add_bot(:east)
      |> Game.add_bot(:west)

    {:ok, game: game, p1: p1}
  end

  test "it finishes the game", %{game: game} do
    assert game.state == :done
  end
end
