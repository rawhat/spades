defmodule Spades.Game.GameManager do
  use GenServer

  alias Spades.Game
  alias Spades.Game.Player

  # Client

  def start_link(game \\ Game.new()) do
    GenServer.start_link(__MODULE__, game)
  end

  def add_player(pid, name: name, team: team) do
    GenServer.call(pid, {:add_player, name, team})
  end

  def get_game_state_for_player(pid, name) do
    GenServer.call(pid, {:get_state, name})
  end

  def make_call(pid, name, value) do
    GenServer.call(pid, {:make_call, name, value})
  end

  def play_card(pid, name, card) do
    GenServer.call(pid, {:play_card, name, card})
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
