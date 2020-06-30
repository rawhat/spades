defmodule Spades.Game.Card do
  use TypedStruct

  @type suit :: :spades | :diamonds | :clubs | :hearts
  @type value :: 1..13

  @derive Jason.Encoder
  typedstruct do
    field :suit, suit(), enforce: true
    field :value, value(), enforce: true
  end

  @suit_value %{:spades => 0, :diamonds => 1, :clubs => 2, :hearts => 3}

  @spec new(suit(), value()) :: t()
  def new(suit, value) do
    %__MODULE__{suit: suit, value: value}
  end

  def max_spade(cards) when is_list(cards) do
    max_of_suit(cards, :spades)
  end

  @spec max_of_suit(list(t()), suit()) :: t() | nil
  def max_of_suit(cards, suit) when is_list(cards) do
    cards
    |> Enum.filter(fn %{card: card} -> card.suit == suit end)
    |> Enum.max_by(fn %{card: card} -> if card.value == 1, do: 14, else: card.value end, fn ->
      nil
    end)
  end

  @spec get_value(t()) :: value()
  def get_value(%__MODULE__{value: 1}), do: 14
  def get_value(%__MODULE__{value: value}), do: value

  @spec compare(t(), t()) :: boolean()
  def compare(%__MODULE__{} = card1, %__MODULE__{} = card2) do
    if card1.suit != card2.suit do
      Map.get(@suit_value, card1.suit) <= Map.get(@suit_value, card2.suit)
    else
      get_value(card1) <= get_value(card2)
    end
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
