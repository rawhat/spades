defmodule Spades.Game.BotTest do
  use ExUnit.Case

  alias Spades.Game

  setup_all do
    {:error, game, "Game is finished"} =
      Game.new("1", "test", "bot_north")
      |> Game.add_bot(:north)
      |> Game.add_bot(:south)
      |> Game.add_bot(:east)
      |> Game.add_bot(:west)

    {:ok, game: game}
  end

  test "it finishes the game", %{game: game} do
    assert game.state == :done
  end
end
