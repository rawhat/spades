defmodule SpadesWeb.GameChannel do
  use Phoenix.Channel

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
    IO.inspect(player)

    state = GameManager.get_game_state_for_player(game_id, player.name)
    IO.inspect(state)

    push(socket, "game_state", state)

    broadcast!(socket, "join_game", body)

    {:noreply, socket}
  end

  intercept ["join_game"]

  def handle_out("join_game", _body, socket) do
    game_id = socket.assigns[:game_id]
    username = socket.assigns[:username]

    state = GameManager.get_game_state_for_player(game_id, username)
    push(socket, "game_state", state)

    {:noreply, socket}
  end
end
