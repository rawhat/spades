defmodule SpadesWeb.GameChannel do
  use Phoenix.Channel

  alias Spades.Game.Card
  alias Spades.Game.GameManager

  def join("game:" <> game_id, %{"params" => %{"username" => username}}, socket) do
    state = GameManager.get_game_state_for_player(game_id, username)
    {:ok, state, socket |> assign(:username, username) |> assign(:game_id, game_id)}
  end

  def join("game:" <> game_id, _params, socket) do
    state = GameManager.get_game_state(game_id)
    {:ok, state, assign(socket, :game_id, game_id)}
  end

  def handle_in("join_game", %{"body" => body}, socket) do
    game_id = socket.assigns[:game_id]
    team = body["team"]
    username = body["username"]

    player = GameManager.add_player(game_id, name: username, team: team)
    state = GameManager.get_game_state_for_player(game_id, player.name)

    push(socket, "game_state", state)
    broadcast!(socket, "join_game", body)

    {:noreply, socket}
  end

  def handle_in("reveal", _params, socket) do
    game_id = socket.assigns[:game_id]
    username = socket.assigns[:username]

    GameManager.reveal_cards(game_id, username)

    state = GameManager.get_game_state_for_player(game_id, username)

    push(socket, "game_state", state)

    {:noreply, socket}
  end

  def handle_in("make_call", %{"body" => call}, socket) do
    game_id = socket.assigns[:game_id]
    username = socket.assigns[:username]

    GameManager.make_call(game_id, username, call)
    broadcast!(socket, "make_call", %{})

    {:noreply, socket}
  end

  def handle_in("play_card", %{"body" => %{"suit" => suit, "value" => value}}, socket) do
    game_id = socket.assigns[:game_id]
    username = socket.assigns[:username]

    card =
      String.to_existing_atom(suit)
      |> Card.new(value)

    GameManager.play_card(game_id, username, card)

    broadcast!(socket, "play_card", %{})

    {:noreply, socket}
  end

  intercept ["join_game", "make_call", "play_card"]

  def handle_out("join_game", _body, socket) do
    game_id = socket.assigns[:game_id]
    username = socket.assigns[:username]

    state = GameManager.get_game_state_for_player(game_id, username)
    push(socket, "game_state", state)

    {:noreply, socket}
  end

  def handle_out("make_call", _body, socket) do
    game_id = socket.assigns[:game_id]
    username = socket.assigns[:username]

    state = GameManager.get_game_state_for_player(game_id, username)
    push(socket, "game_state", state)

    {:noreply, socket}
  end

  def handle_out("play_card", _body, socket) do
    game_id = socket.assigns[:game_id]
    username = socket.assigns[:username]

    state = GameManager.get_game_state_for_player(game_id, username)
    push(socket, "game_state", state)

    {:noreply, socket}
  end
end
