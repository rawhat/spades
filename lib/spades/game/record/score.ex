defmodule Spades.Game.Record.Score do
  use Spades.Game.Record,
    name: :score,
    from: "gen/src/spades@score_Score.hrl"

  def new(points, bags), do: %__MODULE__{points: points, bags: bags}

  def add(%__MODULE__{} = score1, %__MODULE__{} = score2) do
    :spades@score.add(to_record(score1), to_record(score2))
    |> from_record()
  end
end
