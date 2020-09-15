defmodule Spades.Game.Event do
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
    field :data, map()
  end

  @spec create_event(event_type(), map()) :: t()
  def create_event(type, data) do
    %__MODULE__{
      type: type,
      data: data
    }
  end

  @spec has_event?(list(t()), event_type()) :: boolean
  def has_event?(events, type) when is_list(events) do
    Enum.any?(events, &(&1.type == type))
  end
end
