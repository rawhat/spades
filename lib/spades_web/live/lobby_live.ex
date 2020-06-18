defmodule SpadesWeb.LobbyLive do
  use SpadesWeb, :live_view

  alias Phoenix.Socket.Broadcast
  alias Spades.Game.GameManager

  def mount(_params, _map, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Spades.PubSub, "lobby:*")
    end

    games = GameManager.active_games()

    {:ok, assign(socket, :games, games), temporary_assigns: [games: []]}
  end

  def render(assigns) do
    ~L"""
    <div>hi!</div>
    <div phx-update="append">
      <%= for game <- @games do %>
        <div id="<%= game.id %>">
          <%= game.name %>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_info(%Broadcast{event: "update_game", topic: "lobby:*", payload: game_state}, socket) do
    IO.puts("game: #{inspect(game_state)}")
    {:noreply, assign(socket, :games, [game_state])}
  end
end
