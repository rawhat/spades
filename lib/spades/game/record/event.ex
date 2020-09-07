defmodule Spades.Game.Record.Event do
  defmodule AwardedTrick do
    use Spades.Game.Record,
      name: :awarded_trick,
      from: "gen/src/spades@game_AwardedTrick.hrl"
  end

  defmodule Called do
    use Spades.Game.Record,
      name: :called,
      from: "gen/src/spades@game_Called.hrl"

    alias Spades.Game.Record.Call

    def parse(record) do
      called = from_record(record)
      %__MODULE__{called | call: Call.from_record(called.call)}
    end

    def unparse(%__MODULE__{} = called) do
      %__MODULE__{called | call: Call.to_record(called.call)}
      |> to_record()
    end
  end

  defmodule PlayedCard do
    use Spades.Game.Record,
      name: :played_card,
      from: "gen/src/spades@game_PlayedCard.hrl"

    alias Spades.Game.Record.Card

    def parse(record) do
      played = from_record(record)
      %__MODULE__{played | card: Card.parse(played.card)}
    end

    def unparse(%__MODULE__{} = played) do
      %__MODULE__{played | card: Card.unparse(played.card)}
      |> to_record()
    end
  end

  defmodule RevealedCards do
    use Spades.Game.Record,
      name: :revealed_cards,
      from: "gen/src/spades@game_RevealedCards.hrl"
  end

  defmodule StateChanged do
    use Spades.Game.Record,
      name: :state_changed,
      from: "gen/src/spades@game_StateChanged.hrl"
  end

  use TypedStruct

  @event_types ~w(
    awarded_trick
    called
    dealt_cards
    hand_ended
    played_card
    revealed_cards
    round_ended
    state_changed
  )a
  @type event_type :: unquote(Enum.reduce(@event_types, &{:|, [], [&1, &2]}))

  @derive Jason.Encoder
  typedstruct do
    field :type, event_type(), enforce: true
    field :data, map(), enforce: true
  end

  def create_event(type, data \\ %{}), do: %__MODULE__{type: type, data: data}

  def parse(record) do
    case record do
      t when is_tuple(record) ->
        case elem(t, 0) do
          :awarded_trick -> create_event(:awarded_trick, AwardedTrick.parse(record))
          :called -> create_event(:called, Called.parse(record))
          :played_card -> create_event(:played_card, PlayedCard.parse(record))
          :revealed_cards -> create_event(:revealed_cards, RevealedCards.parse(record))
          :state_changed -> create_event(:state_changed, StateChanged.parse(record))
        end

      :dealt_cards ->
        create_event(:dealt_cards)

      :hand_ended ->
        create_event(:hand_ended)

      :round_ended ->
        create_event(:round_ended)
    end
  end

  def unparse(%__MODULE__{type: :awarded_trick, data: data}), do: AwardedTrick.unparse(data)
  def unparse(%__MODULE__{type: :called, data: data}), do: Called.unparse(data)
  def unparse(%__MODULE__{type: :played_card, data: data}), do: PlayedCard.unparse(data)
  def unparse(%__MODULE__{type: :revealed_cards, data: data}), do: RevealedCards.unparse(data)
  def unparse(%__MODULE__{type: :state_changed, data: data}), do: StateChanged.unparse(data)

  def unparse(%__MODULE__{type: type}), do: type
end
