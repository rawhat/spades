defmodule Spades.Game.Record.Card do
  use Spades.Game.Record,
    name: :card,
    from: "gen/src/spades@card_Card.hrl"

  @type suit :: :spades | :diamonds | :clubs | :hearts
  @type value :: 1..13

  @type t :: %__MODULE__{
          suit: suit(),
          value: value()
        }

  @spec new(suit(), value()) :: t()
  def new(suit, value) do
    :spades@card.new(suit, from_value(value))
    |> parse()
  end

  def parse(record) do
    parsed = from_record(record)

    %__MODULE__{
      parsed
      | value:
          case parsed.value do
            {:number, value} -> value
            :jack -> 11
            :queen -> 12
            :king -> 13
            :ace -> 1
          end
    }
  end

  def unparse(%__MODULE__{} = card) do
    %__MODULE__{card | value: from_value(card.value)}
    |> to_record()
  end

  defp from_value(value) do
    case value do
      11 -> :jack
      12 -> :queen
      13 -> :king
      1 -> :ace
      value -> {:number, value}
    end
  end
end
