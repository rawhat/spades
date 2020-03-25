defmodule Spades.Game.Deck do
  alias Spades.Game.Card

  defstruct [:cards]

  def new() do
    %__MODULE__{cards: generate_cards()}
    |> shuffle()
  end

  def shuffle(%__MODULE__{} = deck) do
    %{deck | cards: Enum.shuffle(deck.cards)}
  end

  def draw(%__MODULE__{cards: cards} = deck) do
    case cards do
      [] -> {nil, deck}
      [card | rest] -> {card, %{deck | cards: rest}}
    end
  end

  defp generate_cards() do
    for suit <- [:clubs, :diamonds, :hearts, :spades],
        value <- 1..13 do
      Card.new(suit, value)
    end
  end
end
