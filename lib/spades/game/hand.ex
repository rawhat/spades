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
    %{hand | cards: Enum.filter(cards, &(&1 != card))}
  end

  def is_nil?(%__MODULE__{call: 0}), do: true
  def is_nil?(%__MODULE__{call: -1}), do: true
  def is_nil?(%__MODULE__{call: _}), do: false

  def score(%__MODULE__{call: 0, tricks: 0}), do: 50
  def score(%__MODULE__{call: 0, tricks: _}), do: -50
  def score(%__MODULE__{call: -1, tricks: 0}), do: 100
  def score(%__MODULE__{call: -1, tricks: _}), do: -100
  def score(%__MODULE__{call: call, tricks: tricks}) when call == tricks, do: tricks * 10
  def score(%__MODULE__{call: call}), do: call * -10
end
