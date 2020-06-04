defmodule Spades.Game.Game do
  # import RecStruct
  use Spades.Game.GameRecord,
    erl_mod: "spades_game",
    module: Spades.Game2,
    record_name: "Game"

  # record =
  # Record.extract(
  # :game,
  # from: "gen/src/spades_game_Game.hrl"
  # )

  # keys = :lists.map(&elem(&1, 0), record)
  # vals = :lists.map(&{&1, [], nil}, keys)
  # pairs = :lists.zip(keys, vals)

  # defstruct keys

  # defheader SpadesGame, "gen/src/spades_game_Game.hrl" do
  # defrecstruct(Game, :game)
  # defrecstruct(Player, :player)
  # end

  # alias SpadesGame.Structures.Game

  alias Spades.Game
  alias Spades.Game.Card
  alias Spades.Game.Player

  @type scores :: %{:north_south => integer(), :east_west => integer()}
  @type trick :: %{:id => String.t(), :card => Card.card()}
  @type state :: :waiting | :bidding | :playing
  @type player_map :: %{String.t() => Player.player()}
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
    :spades_game.new_game(id, name, :none)
    |> SpadesGame.Structures.to_struct()

    # |> from_record()
  end

  @spec new(String.t(), String.t(), list(Card.card())) :: t()
  def new(id, name, deck) when is_binary(id) and is_list(deck) do
    :spades_game.new_game(id, name, {:some, deck})
    |> SpadesGame.Structures.to_struct()

    # |> from_record()
  end

  @spec add_player(t(), Player.player()) :: t()
  def add_player(%Game{} = game, %Player{} = player) do
    game
    |> SpadesGame.Structures.to_record()
    |> :spades_game.add_player(player)
    |> SpadesGame.Structures.to_struct()

    # |> from_record()
  end

  @spec reveal_cards(t(), Player.player()) :: t()
  def reveal_cards(%Game{} = game, %Player{} = player) do
    game
    |> SpadesGame.Structures.to_record()
    |> :spades_game.reveal_cards(player.id)
    |> SpadesGame.Structures.to_struct()

    # |> from_record()
  end

  @spec make_call(t(), Player.player(), Hand.call()) :: t()
  def make_call(%Game{} = game, %Player{} = player, call) do
    game
    |> SpadesGame.Structures.to_record()
    |> :spades_game.make_call(player.id, call)
    |> SpadesGame.Structures.to_struct()

    # |> from_record()
  end

  @spec play_card(t(), Player.player(), Card.t()) :: t()
  def play_card(%Game{} = game, %Player{} = player, %Card{} = card) do
    game
    |> SpadesGame.Structures.to_record()
    |> :spades_game.play_card(player.id, card)
    |> SpadesGame.Structures.to_struct()

    # |> from_record()
  end

  # TODO:  Make private

  # def to_record(%Spades.Game.Game{unquote_splicing(pairs)}) do
  # {:game, unquote_splicing(vals)}
  # end

  # def from_record({:game, unquote_splicing(vals)}) do
  # %Spades.Game.Game{unquote_splicing(pairs)}
  # end
end
