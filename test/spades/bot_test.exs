defmodule Spades.Game.BotTest do
  use ExUnit.Case

  alias Spades.Game

  test "it finishes the game" do
    {:error, g, _message} =
      Game.new("1", "test", "bot_north")
      |> Game.add_bot(:north)
      |> Game.add_bot(:south)
      |> Game.add_bot(:east)
      |> Game.add_bot(:west)
      |> Stream.iterate(fn game ->
        case game do
          {:error, _g, _reason} -> game
          {g, _events} -> Game.take_bot_action(g)
          g -> Game.take_bot_action(g)
        end
      end)
      |> Stream.drop_while(fn game ->
        case game do
          {_g, _events} -> true
          {:error, _g, "Game is finished"} -> false
          _g -> true
        end
      end)
      |> Enum.at(0)

    assert g.state == :done
  end
end
