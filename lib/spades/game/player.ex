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
          name: String.t(),
          team: team(),
          tricks: integer() | nil,
          revealed: boolean()
        }

  typedstruct do
    field :id, String.t(), enforce: true
    field :name, String.t(), enforce: true
    field :team, team(), enforce: true
    field :hand, Hand.t()
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

  @spec receive_cards(t(), list(Card.t())) :: t()
  def receive_cards(%__MODULE__{} = player, cards) when is_list(cards) do
    %__MODULE__{player | hand: Hand.new(cards)}
  end

  @spec reveal(t()) :: t()
  def reveal(%__MODULE__{hand: hand} = player) do
    %__MODULE__{player | hand: Hand.reveal(hand)}
  end

  @spec can_call?(t(), Hand.call()) :: boolean()
  def can_call?(%__MODULE__{hand: %Hand{revealed: true}}, -1), do: false
  def can_call?(%__MODULE__{hand: nil}, _call), do: false
  def can_call?(%__MODULE__{}, _call), do: true

  @spec make_call(t(), Hand.call()) :: t()
  def make_call(%__MODULE__{hand: hand} = player, call) do
    %__MODULE__{player | hand: Hand.call(hand, call)}
  end

  @spec take(t()) :: t()
  def take(%__MODULE__{hand: hand} = player) do
    %{player | hand: Hand.take(hand)}
  end

  @spec get_score(list(t())) :: Game.score()
  def get_score([%__MODULE__{hand: hand1}, %__MODULE__{hand: hand2}]) do
    exists_nil = Hand.is_nil?(hand1) || Hand.is_nil?(hand2)

    if exists_nil do
      Map.merge(Hand.score(hand1), Hand.score(hand2), fn _, v1, v2 ->
        v1 + v2
      end)
    else
      taken = hand1.tricks + hand2.tricks
      called = hand1.call + hand2.call

      if taken >= called do
        bags = if taken > called, do: taken - called, else: 0
        %{points: called * 10, bags: bags}
      else
        %{points: called * -10, bags: 0}
      end
    end
  end

  @spec update_score(Game.score(), Game.score()) :: Game.score()
  def update_score(new_score, old_score, nil_amount \\ 50)

  # double bagging out
  def update_score(
        %{points: calculated_points, bags: new_bags} = _new_score,
        %{points: existing_points, bags: old_bags} = _old_score,
        nil_amount
      )
      when old_bags < 5 and new_bags + old_bags >= 10 do
    %{
      points: existing_points + calculated_points - nil_amount * 2 + 10,
      bags: old_bags + new_bags - 10
    }
  end

  # bagging out at 10
  def update_score(
        %{points: calculated_points, bags: new_bags} = _new_score,
        %{points: existing_points, bags: old_bags} = _old_score,
        nil_amount
      )
      when old_bags >= 5 and new_bags + old_bags >= 10 do
    %{
      points: existing_points + calculated_points - nil_amount + 10,
      bags: old_bags + new_bags - 10
    }
  end

  # bagging out at 5
  def update_score(
        %{points: calculated_points, bags: new_bags} = _new_score,
        %{points: existing_points, bags: old_bags} = _old_score,
        nil_amount
      )
      when old_bags < 5 and old_bags + new_bags > 5 do
    %{points: calculated_points + existing_points - nil_amount, bags: old_bags + new_bags}
  end

  # just add to score
  def update_score(
        %{points: calculated_points, bags: new_bags} = _new_score,
        %{points: existing_points, bags: old_bags} = _old_score,
        _nil_amount
      ),
      do: %{points: calculated_points + existing_points, bags: new_bags + old_bags}

  def sorted_hand(%__MODULE__{hand: nil}), do: []

  @spec sorted_hand(t()) :: list(Card.t())
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

  @spec can_play?(t(), Card.t(), Game.trick() | nil, boolean()) :: boolean()
  def can_play?(%__MODULE__{hand: hand}, card, lead, broken) do
    Enum.member?(hand.cards, card) &&
      (card.suit == lead.suit ||
         Enum.all?(hand.cards, &(&1.suit != lead.suit)) ||
         (card.suit == :spades && broken))
  end

  @spec play_card(t(), Card.t()) :: t()
  def play_card(%__MODULE__{hand: hand} = player, card) do
    %__MODULE__{player | hand: Hand.play(hand, card)}
  end
end
