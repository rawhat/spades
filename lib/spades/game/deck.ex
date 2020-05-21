defmodule Spades.Game.Deck do
  alias Spades.Game.Card

  @spec new() :: list(Card.card())
  def new() do
    generate_cards()
    |> Enum.shuffle()
  end

  @spec generate_cards() :: list(Card.card())
  def generate_cards() do
    for suit <- [:clubs, :diamonds, :hearts, :spades],
        value <- 1..13 do
      Card.new(suit, value)
    end
  end
end
