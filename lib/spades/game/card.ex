defmodule Spades.Game.Card do
  use TypedStruct

  @type suit :: :spades | :diamonds | :clubs | :hearts
  @type value :: 1..13

  @derive Jason.Encoder
  typedstruct do
    field :suit, suit(), enforce: true
    field :value, value(), enforce: true
  end

  @suit_value %{:spades => 3, :diamonds => 2, :clubs => 1, :hearts => 0}

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

  def min_of_suit(cards, suit) when is_list(cards) do
    cards
    |> Enum.filter(fn %{card: card} -> card.suit == suit end)
    |> Enum.min_by(fn %{card: card} -> if card.value == 1, do: 14, else: card.value end, fn ->
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

  @spec suit_text(t()) :: String.t()
  def suit_text(%__MODULE__{suit: :clubs}), do: "C"
  def suit_text(%__MODULE__{suit: :diamonds}), do: "D"
  def suit_text(%__MODULE__{suit: :hearts}), do: "H"
  def suit_text(%__MODULE__{suit: :spades}), do: "S"

  @spec value_text(t()) :: String.t()
  def value_text(%__MODULE__{value: 1}), do: "A"
  def value_text(%__MODULE__{value: value}) when value in 2..10, do: to_string(value)
  def value_text(%__MODULE__{value: 11}), do: "J"
  def value_text(%__MODULE__{value: 12}), do: "Q"
  def value_text(%__MODULE__{value: 13}), do: "K"

  def sorted_by_value(cards) when is_list(cards) do
    Enum.sort(cards, fn a, b -> get_value(a) <= get_value(b) end)
  end
end

defimpl String.Chars, for: Spades.Game.Card do
  alias Spades.Game.Card

  def to_string(card) do
    suit_text = Card.suit_text(card)
    value_text = Card.value_text(card)

    "#{value_text}#{suit_text}"
  end
end
