defmodule Spades.Game.Record.PublicState do
  use Spades.Game.Record,
    name: :public_state,
    from: "gen/src/spades@game_PublicState.hrl"

  alias Spades.Game.Record.PublicScore

  def parse(record) do
    state = from_record(record)
    %__MODULE__{state | scores: PublicScore.from_record(state.scores)}
  end
end
