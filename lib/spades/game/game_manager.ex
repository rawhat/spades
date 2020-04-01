defmodule Spades.Game.GameManager do
  use GenServer

  alias Spades.Game
  alias Spades.Game.Player

  # Client

  def start_link(opts) do
    {id, _} = Keyword.pop_first(opts, :id, next_id())
    {game, _} = Keyword.pop_first(opts, :game, Game.new(id))
    name = via_tuple(id)
    GenServer.start_link(__MODULE__, game, name: name)
  end

  def active_games() do
    Registry.select(Spades.Game.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def next_id() do
    {id, _} =
      active_games()
      |> Enum.sort()
      |> Enum.reverse()
      |> Enum.at(0)
      |> Integer.parse()

    to_string(id + 1)
  end

  def exists?(id) do
    case Registry.lookup(Spades.Game.Registry, id) do
      [] -> false
      _ -> true
    end
  end

  def add_player(id, name: name, team: team) do
    GenServer.call(via_tuple(id), {:add_player, name, team})
  end

  def get_game_state(id) do
    GenServer.call(via_tuple(id), :get_state)
  end

  def get_game_state_for_player(id, name) do
    GenServer.call(via_tuple(id), {:get_state, name})
  end

  def make_call(id, name, value) do
    GenServer.call(via_tuple(id), {:make_call, name, value})
  end

  def play_card(id, name, card) do
    GenServer.call(via_tuple(id), {:play_card, name, card})
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Spades.Game.Registry, game_id}}
  end

  # Server

  @impl true
  def init(game) do
    {:ok, game}
  end

  @impl true
  def handle_call({:add_player, name, team}, _from, game) do
    player = Player.new(name, team)
    {:reply, player, Game.add_player(game, player)}
  end

  @impl true
  def handle_call(:get_state, _from, game) do
    {:reply, Game.state(game), game}
  end

  @impl true
  def handle_call({:get_state, name}, _from, game) do
    {:reply, Game.state_for_player(game, name), game}
  end

  @impl true
  def handle_call({:make_call, name, value}, _from, game) do
    {:reply, :ok, Game.make_call(game, name, value)}
  end

  @impl true
  def handle_call({:play_card, name, card}, _from, game) do
    {:reply, :ok, Game.play_card(game, name, card)}
  end
end
