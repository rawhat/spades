defmodule Spades.Game.Record.Hand do
  use Spades.Game.Record,
    name: :hand,
    from: "gen/src/spades@player_Hand.hrl"

  alias Spades.Game.Record.Call
  alias Spades.Game.Record.Card

  @type t :: %__MODULE__{
          call: integer(),
          cards: list(Card.t()),
          revealed: boolean(),
          tricks: integer()
        }

  def new(cards) do
    cards
    |> Enum.map(&Card.unparse/1)
    |> :spades@player.new_hand()
    |> parse_record()
  end

  def parse({:some, record}), do: parse_record(record)

  def parse(:none), do: nil

  def parse_record(record) do
    parsed = from_record(record)

    %__MODULE__{
      parsed
      | call: Call.parse(parsed.call),
        cards: Enum.map(parsed.cards, &Card.parse/1)
    }
  end

  def unparse(%__MODULE__{} = hand) do
    unparsed = %__MODULE__{
      hand
      | call: Call.unparse(hand.call),
        cards: Enum.map(hand.cards, &Card.unparse/1)
    }

    {:some, to_record(unparsed)}
  end

  def unparse(nil) do
    :none
  end
end
