defmodule Spades.Game.Deck do
  alias Spades.Game.Card

  @spec new() :: list(Card.t())
  def new() do
    generate_cards()
    |> Enum.shuffle()
  end

  @spec generate_cards() :: list(Card.t())
  def generate_cards() do
    for suit <- [:clubs, :diamonds, :hearts, :spades],
        value <- 1..13 do
      Card.new(suit, value)
    end
  end
end
