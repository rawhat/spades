defmodule Spades.Game.Player do
  @enforce_keys [:name, :team]
  defstruct ~w(hand name team)a

  alias Spades.Game.Hand

  def new(name, team) do
    %__MODULE__{
      name: name,
      team: team
    }
  end

  def receive_cards(%__MODULE__{} = player, cards) do
    %{player | hand: Hand.new(cards)}
  end

  def make_call(%__MODULE__{hand: hand} = player, call) do
    %{player | hand: Hand.call(hand, call)}
  end

  def take(%__MODULE__{hand: hand} = player) do
    %{player | hand: Hand.take(hand)}
  end

  def get_score(%__MODULE__{hand: hand1}, %__MODULE__{hand: hand2}) do
    total_tricks = hand1.tricks + hand2.tricks

    #case {{}}
  end
end
