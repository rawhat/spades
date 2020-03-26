defmodule Spades.Game.Deck do
  alias Spades.Game.Card

  def new() do
    generate_cards()
    |> Enum.shuffle()
  end

  def generate_cards() do
    for suit <- [:clubs, :diamonds, :hearts, :spades],
        value <- 1..13 do
      Card.new(suit, value)
    end
  end
end
