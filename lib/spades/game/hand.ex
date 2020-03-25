defmodule Spades.Game.Hand do
  @enforce_keys [:cards]

  defstruct ~w(cards tricks call)a

  alias Spades.Game.Card

  def new(cards) do
    %__MODULE__{
      cards: cards,
      tricks: 0
    }
  end

  def call(%__MODULE__{} = hand, value) do
    %{hand | call: value}
  end

  def take(%__MODULE__{tricks: tricks} = hand) do
    %{hand | tricks: tricks + 1}
  end

  def play(%__MODULE__{cards: cards} = hand, %Card{} = card) do
    {card, %{hand | cards: Enum.filter(cards, &(&1 != card))}}
  end

  def broken_nil?(%__MODULE__{call: 0, tricks: tricks}) when tricks != 0, do: true
  def broken_nil?(_hand), do: false

  def broken_blind_nil?(%__MODULE__{call: -1, tricks: tricks}) when tricks != 0, do: true
  def broken_blind_nil?(_hand), do: false
end
