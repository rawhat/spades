defmodule Spades.Game.Hand do
  use TypedStruct

  alias Spades.Game.Card

  @type call :: 0..13 | -1

  typedstruct do
    field :cards, list(Card.t()), enforce: true
    field :tricks, integer()
    field :revealed, boolean()
    field :call, call()
  end

  @spec new(list(Card.t())) :: t()
  def new(cards) do
    %__MODULE__{
      cards: cards,
      tricks: 0,
      revealed: false
    }
  end

  @spec call(t(), call()) :: t()
  def call(%__MODULE__{revealed: revealed} = hand, value) do
    if revealed && value == -1 do
      hand
    else
      %{hand | call: value, revealed: true}
    end
  end

  @spec take(t()) :: t()
  def take(%__MODULE__{tricks: tricks} = hand) do
    %{hand | tricks: tricks + 1}
  end

  @spec play(t(), Card.card()) :: t()
  def play(%__MODULE__{cards: cards} = hand, %Card{} = card) do
    %{hand | cards: Enum.filter(cards, &(&1 != card))}
  end

  @spec reveal(t()) :: t()
  def reveal(%__MODULE__{} = hand) do
    %{hand | revealed: true}
  end

  @spec is_nil?(t()) :: boolean()
  def is_nil?(%__MODULE__{call: 0}), do: true
  def is_nil?(%__MODULE__{call: -1}), do: true
  def is_nil?(%__MODULE__{call: _}), do: false

  @spec score(t()) :: integer()
  def score(%__MODULE__{call: 0, tricks: 0}), do: 50
  def score(%__MODULE__{call: 0, tricks: n}), do: -50 + n
  def score(%__MODULE__{call: -1, tricks: 0}), do: 100
  def score(%__MODULE__{call: -1, tricks: n}), do: -100 + n

  def score(%__MODULE__{call: call, tricks: tricks}) when tricks >= call do
    call * 10 + if tricks > call, do: tricks - call, else: 0
  end

  def score(%__MODULE__{call: call}), do: call * -10
end
