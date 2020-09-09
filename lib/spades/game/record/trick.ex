defmodule Spades.Game.Record.Trick do
  use Spades.Game.Record,
    name: :trick,
    from: "gen/src/spades@game_Trick.hrl"

  alias Spades.Game.Record.Card

  def parse(record) do
    parsed = from_record(record)

    %__MODULE__{parsed | card: Card.parse(parsed.card)}
  end

  def unparse(%__MODULE__{} = trick) do
    %{trick | card: Card.unparse(trick.card)}
    |> to_record()
  end
end
