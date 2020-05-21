defmodule Spades.Game.Hand do
  @enforce_keys [:cards]

  defstruct ~w(cards tricks call revealed)a

  alias Spades.Game.Card

  @type call :: 0..13 | -1
  @type hand :: %__MODULE__{
          cards: list(Card.card()),
          tricks: integer(),
          revealed: boolean()
        }

  @spec new(list(Card.card())) :: hand()
  def new(cards) do
    %__MODULE__{
      cards: cards,
      tricks: 0,
      revealed: false
    }
  end

  @spec call(hand(), call()) :: hand()
  def call(%__MODULE__{revealed: revealed} = hand, value) do
    if revealed && value == -1 do
      hand
    else
      %{hand | call: value, revealed: true}
    end
  end

  @spec take(hand()) :: hand()
  def take(%__MODULE__{tricks: tricks} = hand) do
    %{hand | tricks: tricks + 1}
  end

  @spec play(hand(), Card.card()) :: hand()
  def play(%__MODULE__{cards: cards} = hand, %Card{} = card) do
    %{hand | cards: Enum.filter(cards, &(&1 != card))}
  end

  @spec reveal(hand()) :: hand()
  def reveal(%__MODULE__{} = hand) do
    %{hand | revealed: true}
  end

  @spec is_nil?(hand()) :: boolean()
  def is_nil?(%__MODULE__{call: 0}), do: true
  def is_nil?(%__MODULE__{call: -1}), do: true
  def is_nil?(%__MODULE__{call: _}), do: false

  @spec score(hand()) :: integer()
  def score(%__MODULE__{call: 0, tricks: 0}), do: 50
  def score(%__MODULE__{call: 0, tricks: n}), do: -50 + n
  def score(%__MODULE__{call: -1, tricks: 0}), do: 100
  def score(%__MODULE__{call: -1, tricks: n}), do: -100 + n

  def score(%__MODULE__{call: call, tricks: tricks}) when tricks >= call do
    call * 10 + if tricks > call, do: tricks - call, else: 0
  end

  def score(%__MODULE__{call: call}), do: call * -10
end
