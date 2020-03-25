defmodule Spades.Game.Card do
  @enforce_keys [:suit, :value]

  defstruct ~w(suit value)a

  def new(suit, value) do
    %__MODULE__{suit: suit, value: value}
  end

  def max_spade(cards) when is_list(cards) do
    max_of_suit(cards, :spades)
  end

  def max_of_suit(cards, suit) when is_list(cards) do
    cards
    |> Enum.filter(&(&1.suit == suit))
    |> Enum.max(fn a, b -> a.value >= b.value end, fn -> 0 end)
    |> Enum.at(0)
  end
end

defimpl String.Chars, for: Spades.Game.Card do
  def to_string(card) do
    suit_text =
      case card.suit do
        :clubs -> "C"
        :diamonds -> "D"
        :hearts -> "H"
        :spades -> "S"
      end

    value = card.value

    value_text =
      cond do
        value == 1 -> "A"
        value in 2..10 -> Kernel.to_string(value)
        value == 11 -> "J"
        value == 12 -> "Q"
        value == 13 -> "A"
      end

    "#{value_text}#{suit_text}"
  end
end
