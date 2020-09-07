defmodule Spades.Game.Record.GameStateForPlayer do
  use Spades.Game.Record,
    name: :game_state_for_player,
    from: "gen/src/spades@game_GameStateForPlayer.hrl"

  alias Spades.Game.Record.PublicScore

  def parse(record) do
    state = from_record(record)
    %__MODULE__{state | scores: PublicScore.from_record(state.scores)}
  end
end
