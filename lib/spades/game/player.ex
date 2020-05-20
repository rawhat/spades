defmodule Spades.Game.Player do
  @enforce_keys [:id, :name, :team]
  defstruct ~w(hand id name team)a

  alias Spades.Game.Card
  alias Spades.Game.Hand

  def new(id, name, team) do
    %__MODULE__{
      id: id,
      name: name,
      team: team
    }
  end

  def to_public(%__MODULE__{} = player) do
    if player.hand != nil do
      %{
        cards: Enum.count(player.hand.cards),
        call: player.hand.call,
        id: player.id,
        name: player.name,
        team: player.team,
        tricks: player.hand.tricks,
        revealed: player.hand.revealed
      }
    else
      %{
        id: player.id,
        name: player.name,
        team: player.team,
        cards: 0,
        call: nil,
        tricks: 0,
        revealed: false
      }
    end
  end

  def receive_cards(%__MODULE__{} = player, cards) when is_list(cards) do
    %{player | hand: Hand.new(cards)}
  end

  def reveal(%__MODULE__{hand: hand} = player) do
    %{player | hand: Hand.reveal(hand)}
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
      taken = hand1.tricks + hand2.tricks
      called = hand1.call + hand2.call

      if taken >= called do
        bags = if taken > called, do: taken - called, else: 0
        called * 10 + bags
      else
        called * -10
      end
    end
  end

  def sorted_hand(%__MODULE__{hand: nil}), do: []

  def sorted_hand(%__MODULE__{hand: hand}) do
    if hand.revealed do
      Enum.sort(hand.cards, &Card.compare/2)
    else
      []
    end
  end

  def get_team_players(players, team) do
    Map.values(players)
    |> Enum.filter(&(&1.team == team))
  end

  def can_play?(%__MODULE__{hand: hand}, %Card{suit: :spades}, nil, broken) do
    Enum.all?(hand.cards, &(&1.suit == :spades)) || broken
  end

  def can_play?(_player, _card, nil, _broken), do: true

  def can_play?(%__MODULE__{hand: hand}, card, lead, broken) do
    Enum.member?(hand.cards, card) &&
      (card.suit == lead.suit ||
         Enum.all?(hand.cards, &(&1.suit != lead.suit)) ||
         (card.suit == :spades && broken))
  end

  def play_card(%__MODULE__{hand: hand} = player, card) do
    %{player | hand: Hand.play(hand, card)}
  end
end
