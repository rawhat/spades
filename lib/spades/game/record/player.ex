defmodule Spades.Game.Record.Player do
  use Spades.Game.Record,
    name: :player,
    from: "gen/src/spades@player_Player.hrl"

  alias Spades.Game.Record.Hand

  @type team :: :north_south | :east_west

  @type t :: %__MODULE__{
          hand: Hand.t(),
          id: String.t(),
          name: String.t(),
          team: team()
        }

  @spec new(String.t(), String.t(), team()) :: t()
  def new(id, name, team) do
    %__MODULE__{
      id: id,
      name: name,
      team: team
    }
  end

  def parse(record) do
    parsed = from_record(record)
    %__MODULE__{parsed | hand: Hand.parse(parsed.hand)}
  end

  def unparse(%__MODULE__{} = player) do
    %__MODULE__{
      player
      | hand: Hand.unparse(player.hand),
        id: to_string(player.id)
    }
    |> to_record()
  end
end
