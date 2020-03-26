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

  def get_score([%__MODULE__{hand: hand1}, %__MODULE__{hand: hand2}]) do
    exists_nil = Hand.is_nil?(hand1) || Hand.is_nil?(hand2)

    if exists_nil do
      Hand.score(hand1) + Hand.score(hand2)
    else
      total_tricks = hand1.tricks + hand2.tricks
      taken = hand1.tricks + hand2.tricks
      called = hand1.call + hand2.call

      if taken >= total_tricks do
        called * 10 + (taken - called)
      else
        called * -10
      end
    end
  end

  def get_team_hands(players, team) do
    Map.values(players)
    |> Enum.filter(&(&1.team == team))
    |> Enum.map(& &1.hand)
  end

  def can_play_spade?(%__MODULE__{hand: hand}, suit) do
    !Enum.any?(hand.cards, fn card -> card.suit == suit end)
  end

  def play_card(%__MODULE__{hand: hand} = player, card) do
    %{player | hand: Hand.play(hand, card)}
  end
end
