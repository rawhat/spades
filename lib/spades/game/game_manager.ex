defmodule Spades.Game.GameManager do
  use GenServer

  alias Spades.Game
  alias Spades.Game.Event
  alias Spades.Game.Player

  # Client

  def start_link(opts) do
    {id, _} = Keyword.pop_first(opts, :id, next_id())
    game = Keyword.fetch!(opts, :game)
    name = via_tuple(id)
    GenServer.start_link(__MODULE__, game, name: name)
  end

  def active_games do
    Registry.select(Spades.Game.Registry, [
      {{:"$1", :_, :_}, [], [:"$1"]}
    ])
    |> Stream.map(&get_game_state/1)
    |> Stream.map(fn game_state ->
      %{name: game_state.name, id: game_state.id, players: Enum.count(game_state.players)}
    end)
    |> Enum.to_list()
  end

  def next_id do
    case active_games() do
      [] ->
        "1"

      games ->
        {id, _} =
          Enum.map(games, & &1.id)
          |> Enum.sort()
          |> Enum.reverse()
          |> Enum.at(0)
          |> Integer.parse()

        to_string(id + 1)
    end
  end

  def exists?(id) do
    case Registry.lookup(Spades.Game.Registry, id) do
      [] -> false
      _ -> true
    end
  end

  def add_player(id, id: player_id, name: name, position: position) do
    GenServer.call(via_tuple(id), {:add_player, player_id, name, position})
  end

  def add_bot(id, position: position) do
    GenServer.call(via_tuple(id), {:add_bot, position})
  end

  def get_game_state(id) do
    GenServer.call(via_tuple(id), :get_state)
  end

  def get_game_state_for_player(id, player_id) do
    GenServer.call(via_tuple(id), {:get_state, player_id})
  end

  def reveal_cards(id, player_id) do
    GenServer.call(via_tuple(id), {:reveal_cards, player_id})
  end

  def make_call(id, player_id, value) do
    GenServer.call(via_tuple(id), {:make_call, player_id, value})
  end

  def play_card(id, player_id, card) do
    GenServer.call(via_tuple(id), {:play_card, player_id, card})
  end

  def read_state(id) do
    GenServer.call(via_tuple(id), :read_state)
  end

  def set_state(id, %Game{} = game) do
    GenServer.call(via_tuple(id), {:set_state, game})
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
  def handle_call(:read_state, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_call({:set_state, new_game}, _from, _game) do
    {:reply, new_game, new_game}
  end

  # TODO:  Check if `is_bot_turn?`, and if so, `send_after(self(), 1000)` a
  # take_bot_action message

  @impl true
  def handle_call({:add_player, player_id, name, position}, _from, game) do
    player = Player.new(player_id, name, position)

    game
    |> Game.add_player(player)
    |> handle_return()
  end

  @impl true
  def handle_call({:add_bot, position}, _from, game) do
    game
    |> Game.add_bot(position)
    |> handle_return()
  end

  @impl true
  def handle_call(:get_state, _from, game) do
    {:reply, Game.state(game), game}
  end

  @impl true
  def handle_call({:get_state, player_id}, _from, game) do
    {:reply, Game.state_for_player(game, player_id), game}
  end

  @impl true
  def handle_call({:reveal_cards, player_id}, _from, game) do
    game
    |> Game.reveal_cards(player_id)
    |> handle_error()
  end

  @impl true
  def handle_call({:make_call, player_id, value}, _from, game) do
    game
    |> Game.make_call(player_id, value)
    |> handle_return()
  end

  @impl true
  def handle_call({:play_card, player_id, card}, _from, game) do
    game
    |> Game.play_card(player_id, card)
    |> handle_return()
  end

  @impl true
  def handle_info(:take_bot_action, game) do
    {game, events} = Game.take_bot_action(game)

    if Event.has_event?(events, :called) do
      SpadesWeb.Endpoint.broadcast!("game:#{game.id}", "make_call", %{"events" => events})
    end

    if Event.has_event?(events, :played_card) do
      SpadesWeb.Endpoint.broadcast!("game:#{game.id}", "play_card", %{"events" => events})
    end

    if Game.is_bot_turn?(game) do
      send_bot_action()
    end

    {:noreply, game}
  end

  def send_bot_action(), do: Process.send_after(self(), :take_bot_action, 1000)

  @type return_type :: {:reply, {:error, String.t()}, Game.t()} | {:reply, :ok, Game.return()}

  @spec handle_return(Game.return()) :: return_type()
  def handle_return({:error, _game, _reason} = return), do: handle_error(return)

  def handle_return({%Game{} = game, _events} = return) do
    if Game.is_bot_turn?(game) do
      send_bot_action()
    end

    handle_error(return)
  end

  @spec handle_error(Game.return()) :: return_type()
  defp handle_error({:error, game, reason}), do: {:reply, {:error, reason}, game}
  defp handle_error({%Game{} = game, events}), do: {:reply, {:ok, game, events}, game}
end
