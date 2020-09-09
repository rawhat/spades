defmodule Spades.Game.Record.GameStateForPlayer do
  use Spades.Game.Record,
    name: :game_state_for_player,
    from: "gen/src/spades@game_GameStateForPlayer.hrl"

  alias Spades.Game.Record.Call
  alias Spades.Game.Record.Card
  alias Spades.Game.Record.PublicPlayer
  alias Spades.Game.Record.PublicScore
  alias Spades.Game.Record.Trick
  alias Spades.Game.Record, as: GameRecord

  def parse(record) do
    state = from_record(record)

    %__MODULE__{
      state
      | call: Call.parse(state.call),
        cards:
          case state.cards do
            cards when is_list(cards) ->
              Enum.map(cards, &Card.parse/1)

            count ->
              count
          end,
        current_player: GameRecord.option_as_nil(state.current_player),
        last_trick:
          case state.last_trick do
            {:some, tricks} -> Enum.map(tricks, &Trick.parse/1)
            :none -> nil
          end,
        players: Enum.map(state.players, &PublicPlayer.parse/1),
        scores: PublicScore.from_record(state.scores),
        trick: Enum.map(state.trick, &Trick.parse/1)
    }
  end
end
