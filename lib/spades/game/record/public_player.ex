defmodule Spades.Game.Record.PublicPlayer do
  use Spades.Game.Record,
    name: :public_player,
    from: "gen/src/spades@player_PublicPlayer.hrl"

  alias Spades.Game.Record.Call

  def parse(record) do
    parsed = from_record(record)

    %__MODULE__{
      parsed
      | call:
          case parsed.call do
            {:some, call} -> Call.from_record(call)
            :none -> nil
          end
    }
  end
end
