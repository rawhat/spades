defmodule Spades.Game.Player do
  use TypedStruct

  alias Spades.Game
  alias Spades.Game.Card
  alias Spades.Game.Hand

  @type team :: :north_south | :east_west
  @type public_player :: %{
          cards: integer(),
          call: integer() | nil,
          id: String.t(),
          id: String.t(),
          name: String.t(),
          team: team(),
          tricks: integer() | nil,
          revealed: boolean()
        }

  typedstruct do
    field :hand, Hand.t()
    field :id, String.t(), enforce: true
    field :name, String.t(), enforce: true
    field :team, team(), enforce: true
  end

  @spec new(String.t(), String.t(), team()) :: t()
  def new(id, name, team) do
    %__MODULE__{
      id: id,
      name: name,
      team: team
    }
  end

  @spec to_public(t()) :: public_player()
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

  @spec receive_cards(t(), list(Card.card())) :: t()
  def receive_cards(%__MODULE__{} = player, cards) when is_list(cards) do
    %{player | hand: Hand.new(cards)}
  end

  @spec reveal(t()) :: t()
  def reveal(%__MODULE__{hand: hand} = player) do
    %{player | hand: Hand.reveal(hand)}
  end

  @spec make_call(t(), Hand.call()) :: t()
  def make_call(%__MODULE__{hand: hand} = player, call) do
    %{player | hand: Hand.call(hand, call)}
  end

  @spec take(t()) :: t()
  def take(%__MODULE__{hand: hand} = player) do
    %{player | hand: Hand.take(hand)}
  end

  @spec get_score(list(t())) :: integer()
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

  @spec sorted_hand(t()) :: list(Card.card())
  def sorted_hand(%__MODULE__{hand: hand}) do
    if hand.revealed do
      Enum.sort(hand.cards, &Card.compare/2)
    else
      []
    end
  end

  @spec get_team_players(%{String.t() => t()}, team()) :: list(t())
  def get_team_players(players, team) do
    Map.values(players)
    |> Enum.filter(&(&1.team == team))
  end

  def can_play?(%__MODULE__{hand: hand}, %Card{suit: :spades}, nil, broken) do
    Enum.all?(hand.cards, &(&1.suit == :spades)) || broken
  end

  def can_play?(_player, _card, nil, _broken), do: true

  @spec can_play?(t(), Card.card(), Game.trick() | nil, boolean()) :: boolean()
  def can_play?(%__MODULE__{hand: hand}, card, lead, broken) do
    Enum.member?(hand.cards, card) &&
      (card.suit == lead.suit ||
         Enum.all?(hand.cards, &(&1.suit != lead.suit)) ||
         (card.suit == :spades && broken))
  end

  @spec play_card(t(), Card.card()) :: t()
  def play_card(%__MODULE__{hand: hand} = player, card) do
    %{player | hand: Hand.play(hand, card)}
  end
end
