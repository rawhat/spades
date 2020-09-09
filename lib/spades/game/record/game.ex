defmodule Spades.Game.Record.Game do
  use Spades.Game.Record,
    name: :game,
    from: "gen/src/spades@game_Game.hrl"

  alias __MODULE__, as: Game
  alias Spades.Game.Record.Call
  alias Spades.Game.Record.Card
  alias Spades.Game.Record.Event
  alias Spades.Game.Record.GameStateForPlayer
  alias Spades.Game.Record.Player
  alias Spades.Game.Record.PublicState
  alias Spades.Game.Record.Score
  alias Spades.Game.Record.Trick
  alias Spades.Game.Record, as: GameRecord

  @type scores :: %{:north_south => integer(), :east_west => integer()}
  @type trick :: %{:id => String.t(), :card => Card.t()}
  @type state :: :waiting | :bidding | :playing
  @type player_map :: %{String.t() => Player.t()}
  @type t :: %Game{
          current_player: integer(),
          deck: list(Card.card()),
          id: String.t(),
          name: String.t(),
          play_order: list(String.t()),
          players: player_map(),
          scores: scores(),
          spades_broken: boolean(),
          state: state(),
          trick: list(trick())
        }

  # Public functions

  @spec new(String.t(), String.t()) :: t()
  def new(id, name) when is_binary(id) do
    :spades@game.new_game(id, name, :none)
    |> from_result()
    |> parse()
  end

  @spec new(String.t(), String.t(), list(Card.card())) :: t()
  def new(id, name, deck) when is_binary(id) and is_list(deck) do
    parsed_deck = Enum.map(deck, &Card.unparse/1)

    :spades@game.new_game(id, name, {:some, parsed_deck})
    |> from_result()
    |> parse()
  end

  @spec add_player(t(), Player.t()) :: t()
  def add_player(%Game{} = game, %Player{} = player) do
    game
    |> unparse()
    |> :spades@game.add_player(Player.unparse(player))
    |> result_with_game(game)
  end

  def add_player({%Game{} = game, events}, %Player{} = player),
    do: add_player(%Game{game | events: events}, player)

  def add_player({:error, _game, _reason} = error, %Player{} = _player), do: error

  @spec reveal_cards(t(), String.t()) :: t()
  def reveal_cards(%Game{} = game, player_id) do
    game
    |> unparse()
    |> :spades@game.reveal_cards(to_string(player_id))
    |> result_with_game(game)
  end

  def reveal_cards({%Game{} = game, events}, player_id),
    do: reveal_cards(%Game{game | events: events}, player_id)

  def reveal_cards({:error, _game, _reason} = error, _player_id), do: error

  @spec make_call(t(), String.t(), Hand.call()) :: t()
  def make_call(%Game{} = game, player_id, call) do
    game
    |> unparse()
    |> :spades@game.make_call(to_string(player_id), Call.to_record(call))
    |> result_with_game(game)
  end

  def make_call({%Game{} = game, events}, player_id, call),
    do: make_call(%Game{game | events: events}, player_id, call)

  def make_call({:error, _game, _reason} = error, _player_id, _card), do: error

  @spec play_card(t(), String.t(), Card.t()) :: t()
  def play_card(%Game{} = game, player_id, %Card{} = card) do
    game
    |> unparse()
    |> :spades@game.play_card(to_string(player_id), Card.unparse(card))
    |> result_with_game(game)
  end

  def play_card({%Game{} = game, events}, player_id, %Card{} = card),
    do: play_card(%Game{game | events: events}, player_id, card)

  def play_card({:error, _game, _reason} = error, _player_id, _card), do: error

  def state(%Game{} = game) do
    game
    |> unparse()
    |> :spades@game.state()
    |> PublicState.parse()
  end

  def state_for_player(%Game{} = game, player_id) do
    state =
      game
      |> unparse()
      |> :spades@game.state_for_player(to_string(player_id))

    case state do
      {:ok, state_for_player} -> GameStateForPlayer.parse(state_for_player)
      {:error, state} -> PublicState.parse(state)
    end
  end

  # Turn all record sub-fields into their appropriate structs as well
  def parse({:error, _} = error), do: error

  def parse({:ok, %Game{} = game}), do: parse(game)

  def parse(%Game{} = game) do
    %__MODULE__{
      game
      | current_player: GameRecord.option_as_nil(game.current_player),
        deck: Enum.map(game.deck, &Card.parse/1),
        players: map_values(game.players, &Player.parse/1),
        scores: map_values(game.scores, &Score.parse/1),
        trick: Enum.map(game.trick, &Trick.parse/1),
        last_trick:
          case game.last_trick do
            {:some, tricks} -> Enum.map(tricks, &Trick.parse/1)
            :none -> nil
          end
    }
  end

  def unparse(%Game{} = game) do
    %__MODULE__{
      game
      | current_player: GameRecord.nil_as_option(game.current_player),
        deck: Enum.map(game.deck, &Card.unparse/1),
        events: Enum.map(game.events, &Event.unparse/1),
        players: map_values(game.players, &Player.unparse/1),
        scores: map_values(game.scores, &Score.unparse/1),
        trick: Enum.map(game.trick, &Trick.unparse/1),
        last_trick:
          case game.last_trick do
            nil -> :none
            tricks -> {:some, Enum.map(tricks, &Trick.unparse/1)}
          end
    }
    |> to_record()
  end

  defp map_values(map, from) do
    map
    |> Enum.map(fn {key, value} -> {key, from.(value)} end)
    |> Map.new()
  end

  defp result_with_game(record, %Game{} = game) do
    case record do
      {:error, reason} ->
        {:error, game, reason}

      {:ok, {result, events}} ->
        {
          result
          |> from_record()
          |> parse(),
          Enum.map(events, &Event.parse/1)
        }

      {result, events} ->
        {
          result
          |> from_record()
          |> parse(),
          Enum.map(events, &Event.parse/1)
        }
    end
  end
end
