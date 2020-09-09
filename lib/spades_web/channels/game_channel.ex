defmodule SpadesWeb.GameChannel do
  use Phoenix.Channel

  alias Spades.Accounts
  alias Spades.Game.Record.Card
  alias Spades.Game.GameManager

  def join("game:" <> game_id, %{"params" => %{"username" => username}}, socket) do
    user = Accounts.get_user_by(username: username)
    state = GameManager.get_game_state_for_player(game_id, user.id)

    {:ok, state,
     socket
     |> assign(:username, user.username)
     |> assign(:game_id, game_id)
     |> assign(:user_id, user.id)}
  end

  def join("game:" <> game_id, _params, socket) do
    state = GameManager.get_game_state(game_id)
    {:ok, state, assign(socket, :game_id, game_id)}
  end

  def handle_in("join_game", %{"body" => body}, socket) do
    game_id = socket.assigns[:game_id]
    # convert "north_south" to :north_south
    team = String.to_atom(body["team"])
    username = socket.assigns[:username]
    player_id = socket.assigns[:user_id]

    case GameManager.add_player(game_id, id: player_id, name: username, team: team) do
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}

      {:ok, _game, events} ->
        state = GameManager.get_game_state_for_player(game_id, player_id)

        push(socket, "game_state", %{events: events, state: state})
        broadcast!(socket, "join_game", %{"events" => events})

        SpadesWeb.Endpoint.broadcast("lobby:*", "update_game", %{
          id: state.id,
          name: state.name,
          players: Enum.count(state.players)
        })

        {:noreply, socket}
    end
  end

  def handle_in("reveal", _params, socket) do
    game_id = socket.assigns[:game_id]
    player_id = socket.assigns[:user_id]

    case GameManager.reveal_cards(game_id, player_id) do
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}

      {:ok, _game, events} ->
        state = GameManager.get_game_state_for_player(game_id, player_id)

        push(socket, "game_state", %{events: events, state: state})

        {:noreply, socket}
    end
  end

  def handle_in("make_call", %{"body" => call}, socket) do
    game_id = socket.assigns[:game_id]
    player_id = socket.assigns[:user_id]

    case GameManager.make_call(game_id, player_id, call) do
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}

      {:ok, _game, events} ->
        broadcast!(socket, "make_call", %{"events" => events})

        {:noreply, socket}
    end
  end

  def handle_in("play_card", %{"body" => %{"suit" => suit, "value" => value}}, socket) do
    game_id = socket.assigns[:game_id]
    player_id = socket.assigns[:user_id]

    card =
      String.to_existing_atom(suit)
      |> Card.new(value)

    case GameManager.play_card(game_id, player_id, card) do
      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}

      {:ok, _game, events} ->
        broadcast!(socket, "play_card", %{"events" => events})

        {:noreply, socket}
    end
  end

  intercept ["join_game", "make_call", "play_card"]

  def handle_out("join_game", %{"events" => events}, socket) do
    game_id = socket.assigns[:game_id]
    player_id = socket.assigns[:user_id]

    state = GameManager.get_game_state_for_player(game_id, player_id)
    push(socket, "game_state", %{state: state, events: events})

    {:noreply, socket}
  end

  def handle_out("make_call", %{"events" => events}, socket) do
    game_id = socket.assigns[:game_id]
    player_id = socket.assigns[:user_id]

    state = GameManager.get_game_state_for_player(game_id, player_id)
    push(socket, "game_state", %{state: state, events: events})

    {:noreply, socket}
  end

  def handle_out("play_card", %{"events" => events}, socket) do
    game_id = socket.assigns[:game_id]
    player_id = socket.assigns[:user_id]

    state = GameManager.get_game_state_for_player(game_id, player_id)
    push(socket, "game_state", %{state: state, events: events})

    {:noreply, socket}
  end
end
